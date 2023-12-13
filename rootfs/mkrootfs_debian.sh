#!/bin/bash
# This script builds a Debian root filesystem image for testing libbpf in a
# virtual machine. Requires debootstrap >= 1.0.95 and zstd.

# Use e.g. ./mkrootfs_debian.sh --arch=s390x to generate a rootfs for a
# foreign architecture. Requires configured binfmt_misc, e.g. using
# Debian/Ubuntu's qemu-user-binfmt package or
# https://github.com/multiarch/qemu-user-static.
# Any arguments that need to be passed to `debootstrap` should be passed after
# `--`, e.g ./mkrootfs_debian.sh --arch=s390x -- --foo=bar

set -e -u -o pipefail

# table of Debian arch <-> GNU arch matches
CPUTABLE="${CPUTABLE:-/usr/share/dpkg/cputable}"

deb_arch=$(dpkg --print-architecture)
distro="bullseye"

function usage() {
    echo "Usage: $0 [-a | --arch architecture] [-h | --help]

Build a Debian chroot filesystem image for testing libbbpf in a virtual machine.
By default build an image for the architecture of the host running the script.

    -a | --arch:    architecture to build the image for. Default (${deb_arch})
    -d | --distro:  distribution to build. Default (${distro})
"
}

function error() {
    echo "ERROR: ${1}" >&2
}

function debian_to_gnu() {
    # Funtion to convert an architecture in Debian to its GNU equivalent,
    # e.g amd64 -> x86_64
    # CPUTABLE contains a list of debian_arch\tgnu_arch per line
    # Compare of the first field matches and print the second one.
    awk -v deb_arch="$1" '$1 ~ deb_arch {print $2}' "${CPUTABLE}"
}

function qemu_static() {
    # Given a Debian architecture find the location of the matching
    # qemu-${gnu_arch}-static binary.
    gnu_arch=$(debian_to_gnu "${1}")
    if [ "$deb_arch" == "ppc64el" ]; then
	    gnu_arch="ppc64le"
    fi
    echo "qemu-${gnu_arch}-static"
}

function check_requirements() {
    # Checks that all necessary packages are installed on the system.
    # Prints an error message explaining what is missing and exits.

    local deb_arch=$1
    local err=0

    # Check that we can translate from Debian arch to GNU arch.
    if [[ ! -e "${CPUTABLE}" ]]
    then
        error "${CPUTABLE} not found on your system. Make sure dpkg package is installed."
        err=1
    fi

    # Check that the architecture is supported  by Debian.
    if [[ -z $(debian_to_gnu "${deb_arch}") ]]
    then
        error "${deb_arch} is not a supported architecture."
        err=1
    fi

    # Check that we can install the root image for a foreign arch.
    qemu=$(qemu_static "${deb_arch}")
    if ! command -v "${qemu}" &> /dev/null
    then
        error "${qemu} binary not found on your system. Make sure qemu-user-static package is installed."
        err=1
    fi

    # Check that debootrap is installed.
    if ! command -v debootstrap &> /dev/null
    then
        error "debootstrap binary not found on your system. Make sure debootstrap package is installed."
        err=1
    fi

    # Check we are root.
    if [[ "$(id -u)" != 0 ]]; then
        error "$0 must run as root"
        err=1
    fi

    if [[ ${err} -ne 0 ]]
    then
        exit 1
    fi
}

TEMP=$(getopt  -l "arch:,distro:,help" -o "a:d:h" -- "$@")
if [ $? -ne 0 ]; then
    usage
fi

eval set -- "${TEMP}"
unset TEMP

while true; do
    case "$1" in
        --arch | -a)
            deb_arch="$2"
            shift 2
            ;;
        --distro | -d)
            distro="$2"
            shift 2
            ;;
        --help | -h)
            usage
            exit
            ;;
        --)
            shift
            break
            ;;
        *)
            break
            ;;
    esac
done


check_requirements "${deb_arch}"

# Print out commands ran to make it easier to troubleshoot breakages.
set -x

# Create a working directory and schedule its deletion.
root=$(mktemp -d -p "$PWD")
trap '[[ "$?" -eq "0" ]] && rm -r "$root"' EXIT

# Install packages.
packages=(
	binutils
	busybox
	elfutils
	ethtool
	iproute2
	iptables
	keyutils
	libcap2
	libelf1
	openssl
	strace
	zlib1g
)
packages=$(IFS=, && echo "${packages[*]}")

# Stage 1
debootstrap --include="$packages" \
    --components=main,universe \
    --foreign \
    --variant=minbase \
    --arch="${deb_arch}" \
    "$@" \
    "${distro}" \
    "$root"

qemu=$(which $(qemu_static ${deb_arch}))

cp "${qemu}" "${root}/usr/bin"

# Stage 2
chroot "${root}" /debootstrap/debootstrap --second-stage

# Remove the init scripts (tests use their own). Also remove various
# unnecessary files in order to save space.
rm -rf \
	"$root"/etc/rcS.d \
	"$root"/usr/share/{doc,info,locale,man,zoneinfo} \
	"$root"/var/cache/apt/archives/* \
	"$root"/var/lib/apt/lists/* \
	"${root}/usr/bin/${qemu}"

# Apply common tweaks.
"$(dirname "$0")"/mkrootfs_tweak.sh "$root"

# Save the result.
name="libbpf-vmtest-rootfs-$(date +%Y.%m.%d)-${distro}-${deb_arch}.tar.zst"
rm -f "$name"
tar -C "$root" -c . | zstd -T0 -19 -o "$name"
