ARCHS = amd64 arm64 s390x riscv64
DISTROS = noble

.PHONY: all
all:
	@for distro in $(DISTROS) ; do \
		for arch in $(ARCHS) ; do \
			sudo ./mkrootfs_debian.sh --arch "$${arch}" --distro "$${distro}" ; \
		done \
	done

