#!/bin/bash

set -uo pipefail
trap 'exit 2' ERR

. "$(cd "$(dirname "$0")" && pwd)/../helpers.sh"

TEMP=$(getopt -o 'k:b:d:lh' --long 'kernel:,build:,dir:,list,help' -n "$0" -- "$@")
eval set -- "$TEMP"
unset TEMP

unset KERNELRELEASE
unset BUILDDIR
unset IMG
DIR="$PWD"
LIST=0

# by default will copy all files that aren't listed in git exclusions
# but it doesn't work for entire kernel tree very well
# so for full kernel tree you may need to SOURCE_FULLCOPY=0
SOURCE_FULLCOPY=${SOURCE_FULLCOPY:-1}

while true; do
	case "$1" in
		-k|--kernel)
			KERNELRELEASE="$2"
			shift 2
			;;
		-b|--build)
			BUILDDIR="$2"
			shift 2
			;;
		-d|--dir)
			DIR="$2"
			shift 2
			;;
		-l|--list)
			LIST=1
			;;
		--)
			shift
			break
			;;
		*)
			usage err
			;;
	esac
done
if [[ -v BUILDDIR ]]; then
	if [[ -v KERNELRELEASE ]]; then
		usage err
	fi
elif [[ ! -v KERNELRELEASE ]]; then
	KERNELRELEASE='*'
fi
unset URLS

cache_urls() {
	if ! declare -p URLS &> /dev/null; then
		# This URL contains a mapping from file names to URLs where
		# those files can be downloaded.
		declare -gA URLS
		while IFS=$'\t' read -r name url; do
			URLS["$name"]="$url"
		done < <(cat "${GITHUB_ACTION_PATH}/../INDEX")
	fi
}

matching_kernel_releases() {
	local pattern="$1"
	{
	for file in "${!URLS[@]}"; do
		if [[ $file =~ ^vmlinux-(.*).zst$ ]]; then
			release="${BASH_REMATCH[1]}"
			case "$release" in
				"$pattern")
					# sort -V handles rc versions properly
					# if we use "~" instead of "-".
					echo "${release//-rc/~rc}"
					;;
			esac
		fi
	done
	} | sort -rV | sed 's/~rc/-rc/g'
}

download() {
	local file="$1"
	cache_urls
	if [[ ! -v URLS[$file] ]]; then
		echo "$file not found" >&2
		return 1
	fi
	echo "Downloading $file..." >&2
	curl -Lf "${URLS[$file]}" "${@:2}"
}

if (( LIST )); then
	cache_urls
	matching_kernel_releases "$KERNELRELEASE"
	exit 0
fi

# Only go to the network if it's actually a glob pattern.
if [[ -v BUILDDIR ]]; then
	KERNELRELEASE="$(make -C "$BUILDDIR" -s kernelrelease)"
elif [[ ! $KERNELRELEASE =~ ^([^\\*?[]|\\[*?[])*\\?$ ]]; then
	# We need to cache the list of URLs outside of the command
	# substitution, which happens in a subshell.
	cache_urls
	KERNELRELEASE="$(matching_kernel_releases "$KERNELRELEASE" | head -1)"
	if [[ -z $KERNELRELEASE ]]; then
		echo "No matching kernel release found" >&2
		exit 1
	fi
fi

echo "Kernel release: $KERNELRELEASE" >&2
echo

foldable start vmlinux_setup "Preparing Linux image"

tmp=
ARCH_DIR="$DIR/x86_64"
mkdir -p "$ARCH_DIR"
mnt="$(mktemp -d -p "$DIR" mnt.XXXXXXXXXX)"

cleanup() {
	if [[ -n $tmp ]]; then
		rm -f "$tmp" || true
	fi
	if mountpoint -q "$mnt"; then
		sudo umount "$mnt" || true
	fi
	if [[ -d "$mnt" ]]; then
		rmdir "$mnt" || true
	fi
}
trap cleanup EXIT

if [[ -v BUILDDIR ]]; then
	vmlinuz="$BUILDDIR/$(make -C "$BUILDDIR" -s image_name)"
else
	vmlinuz="${ARCH_DIR}/vmlinuz-${KERNELRELEASE}"
	if [[ ! -e $vmlinuz ]]; then
		tmp="$(mktemp "$vmlinuz.XXX.part")"
		download "${ARCH}/vmlinuz-${KERNELRELEASE}" -o "$tmp"
		mv "$tmp" "$vmlinuz"
		tmp=
	fi
fi

# Install vmlinux.
vmlinux="${GITHUB_WORKSPACE}/vmlinux"
download "${ARCH}/vmlinux-${KERNELRELEASE}.zst" | zstd -d > "$vmlinux"

echo $vmlinux

foldable end vmlinux_setup
