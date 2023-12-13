ARCHS = amd64 arm64 s390x ppc64el
DISTROS = bullseye

.PHONY: all
all:
	@for distro in $(DISTROS) ; do \
		for arch in $(ARCHS) ; do \
			sudo ./mkrootfs_debian.sh --arch "$${arch}" --distro "$${distro}" ; \
		done \
	done

