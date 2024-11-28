FROM ubuntu:noble

ARG LLVM_VERSION=17
ARG PAHOLE_BRANCH=master
ARG PAHOLE_ORIGIN=https://git.kernel.org/pub/scm/devel/pahole/pahole.git
ARG TARGET_ARCH=x86_64

RUN apt-get update && apt-get install -y \
    bash bc binutils bison cmake diffutils elfutils findutils flex \
    gcc git gnupg libdw-dev libelf-dev libssl-dev libzstd-dev make \
    openssl perl sudo udev util-linux wget zstd

RUN git clone -b v2 --depth 1 https://github.com/libbpf/ci.git /ci/actions

RUN /ci/actions/setup-build-env/build_pahole.sh
RUN /ci/actions/setup-build-env/install_clang.sh
RUN /ci/actions/setup-build-env/install_cross_compilation_toolchain.sh $TARGET_ARCH

ENV GITHUB_WORKSPACE=/github/workspace
WORKDIR /github/workspace
ENTRYPOINT ["/ci/actions/build-linux/build.sh"]

