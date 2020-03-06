# XCGO_S3 is xcgo's own S3 bucket that holds stuff that's hard to find, e.g. macOS SDK.
ARG XCGO_S3="https://xcgo.s3.amazonaws.com"
ARG OSX_SDK=MacOSX10.15.sdk
ARG OSX_CODENAME=catalina
ARG OSX_VERSION_MIN=10.10
ARG OSX_SDK_SUM=d97054a0aaf60cb8e9224ec524315904f0309fbbbac763eb7736bdfbdad6efc8
ARG OSX_SDK_BASEURL="$XCGO_S3/macos/sdk"
ARG OSX_CROSS_COMMIT=bee9df60f169abdbe88d8529dbcc1ec57acf656d
ARG LIBTOOL_VERSION=2.4.6_1
ARG LIBTOOL_BASEURL="$XCGO_S3/macos/libtool"

FROM ubuntu:bionic AS snapcore
# This section taken from snapcore/snapcraft:stable
# Grab dependencies
RUN apt-get update
RUN apt-get dist-upgrade --yes
RUN apt-get install --yes \
      curl \
      jq \
      squashfs-tools \
      lsb-core

# Grab the core snap (for backwards compatibility) from the stable channel and
# unpack it in the proper place.
RUN curl -L $(curl -H 'X-Ubuntu-Series: 16' 'https://api.snapcraft.io/api/v1/snaps/details/core' | jq '.download_url' -r) --output core.snap
RUN mkdir -p /snap/core
RUN unsquashfs -d /snap/core/current core.snap

# Grab the core18 snap (which snapcraft uses as a base) from the stable channel
# and unpack it in the proper place.
RUN curl -L $(curl -H 'X-Ubuntu-Series: 16' 'https://api.snapcraft.io/api/v1/snaps/details/core18' | jq '.download_url' -r) --output core18.snap
RUN mkdir -p /snap/core18
RUN unsquashfs -d /snap/core18/current core18.snap

# Grab the snapcraft snap from the stable channel and unpack it in the proper
# place.
RUN curl -L $(curl -H 'X-Ubuntu-Series: 16' 'https://api.snapcraft.io/api/v1/snaps/details/snapcraft?channel=stable' | jq '.download_url' -r) --output snapcraft.snap
RUN mkdir -p /snap/snapcraft
RUN unsquashfs -d /snap/snapcraft/current snapcraft.snap

# Create a snapcraft runner (TODO: move version detection to the core of
# snapcraft).
RUN mkdir -p /snap/bin
RUN echo "#!/bin/sh" > /snap/bin/snapcraft
RUN snap_version="$(awk '/^version:/{print $2}' /snap/snapcraft/current/meta/snap.yaml)" && echo "export SNAP_VERSION=\"$snap_version\"" >> /snap/bin/snapcraft
RUN echo 'exec "$SNAP/usr/bin/python3" "$SNAP/bin/snapcraft" "$@"' >> /snap/bin/snapcraft
RUN chmod +x /snap/bin/snapcraft

# Multi-stage build, only need the snaps from the builder. Copy them one at a
# time so they can be cached.
#FROM ubuntu:xenial
#COPY --from=builder /snap/core /snap/core
#COPY --from=builder /snap/core18 /snap/core18
#COPY --from=builder /snap/snapcraft /snap/snapcraft
#COPY --from=builder /snap/bin/snapcraft /snap/bin/snapcraft

# Generate locale.
RUN apt-get update && apt-get dist-upgrade --yes && apt-get install --yes sudo locales && locale-gen en_US.UTF-8

# Set the proper environment.
ENV LANG="en_US.UTF-8"
ENV LANGUAGE="en_US:en"
ENV LC_ALL="en_US.UTF-8"
ENV PATH="/snap/bin:$PATH"
ENV SNAP="/snap/snapcraft/current"
ENV SNAP_NAME="snapcraft"
ENV SNAP_ARCH="amd64"




FROM snapcore AS golangcore

RUN apt-get update -qq -y && apt-get install -y -q --no-install-recommends \
    man \
    wget \
    curl \
    git \
    zsh \
    vim \
    software-properties-common


ENV GOPATH="/go"
RUN mkdir -p "${GOPATH}/src"

# As suggested here: https://github.com/golang/go/wiki/Ubuntu
RUN add-apt-repository -y ppa:longsleep/golang-backports && apt update -y
RUN apt install -y golang-go


FROM golangcore AS ctools
# Dependencies for https://github.com/tpoechtrager/osxcross:
RUN apt-get update -qq && apt-get install -y -q --no-install-recommends \
    clang \
    cmake \
    file \
    llvm \
    patch \
    libxml2-dev \
    libssl-dev \
    xz-utils \
    zlib1g-dev  \
    libc++-dev  \
    libltdl-dev \
    gcc-mingw-w64 \
    parallel


ENV OSX_CROSS_PATH=/osxcross


FROM ctools AS osx-sdk
#ARG XCGO_S3
ARG OSX_SDK
ARG OSX_SDK_SUM
ARG OSX_SDK_BASEURL
#ADD "${XCGO_S3}/macos/sdk/${OSX_SDK}.tar.xz" "${OSX_CROSS_PATH}/tarballs/${OSX_SDK}.tar.xz"
ADD "${OSX_SDK_BASEURL}/${OSX_SDK}.tar.xz" "${OSX_CROSS_PATH}/tarballs/${OSX_SDK}.tar.xz"
#ADD "${OSX_SDK_BASEURL}/${OSX_SDK}.tar.xz" "${OSX_CROSS_PATH}/tarballs/${OSX_SDK}.tar.xz"
RUN echo "${OSX_SDK_SUM}"  "${OSX_CROSS_PATH}/tarballs/${OSX_SDK}.tar.xz" | sha256sum -c -


FROM ctools AS osx-cross
ARG OSX_CROSS_COMMIT
WORKDIR "${OSX_CROSS_PATH}"
RUN git clone https://github.com/tpoechtrager/osxcross.git . \
 && git checkout -q "${OSX_CROSS_COMMIT}" \
 && rm -rf ./.git
COPY --from=osx-sdk "${OSX_CROSS_PATH}/." "${OSX_CROSS_PATH}/"
ARG OSX_VERSION_MIN
RUN UNATTENDED=yes OSX_VERSION_MIN=${OSX_VERSION_MIN} ./build.sh


FROM osx-cross AS libtool
#ARG XCGO_S3
ARG LIBTOOL_VERSION
ARG LIBTOOL_BASEURL
ARG OSX_CODENAME
ARG OSX_SDK

## See https://bintray.com/homebrew/bottles/libtool#files
#RUN mkdir -p "${OSX_CROSS_PATH}/target/SDK/${OSX_SDK}/usr/"
##ARG LIBTOOL_URL=https://bintray.com/homebrew/bottles/download_file?file_path=libtool-2.4.6.yosemite.bottle.tar.gz
##RUN curl -fsSL "https://homebrew.bintray.com/bottles/libtool-2.4.6.yosemite.bottle.tar.gz" \
#RUN curl -fsSL "https://homebrew.bintray.com/bottles/libtool-2.4.6_1.catalina.bottle.tar.gz" \
##RUN curl -fsSL "https://homebrew.bintray.com/bottles/libtool-${LIBTOOL_VERSION}.${OSX_CODENAME}.bottle.tar.gz" \

RUN mkdir -p "${OSX_CROSS_PATH}/target/SDK/${OSX_SDK}/usr/"
#RUN curl -fsSL "${XCGO_S3}/macos/libtool/libtool-${LIBTOOL_VERSION}.${OSX_CODENAME}.bottle.tar.gz" \
RUN curl -fsSL "${LIBTOOL_BASEURL}/libtool-${LIBTOOL_VERSION}.${OSX_CODENAME}.bottle.tar.gz" \
	| gzip -dc | tar xf - \
		-C "${OSX_CROSS_PATH}/target/SDK/${OSX_SDK}/usr/" \
		--strip-components=2 \
		"libtool/${LIBTOOL_VERSION}/include/" \
		"libtool/${LIBTOOL_VERSION}/lib/"


# This section descended from https://github.com/mailchain/goreleaser-xcgo
# Much gratitude to the mailchain team for doing the hard work.
FROM libtool AS goreleaser

ENV GORELEASER_VERSION=0.127.0
ENV GORELEASER_SHA=bf7e0f34d1d46041f302a0dd773a5c70ff7476c147d3a30659a5a11e823bccbd

ENV GORELEASER_DOWNLOAD_FILE=goreleaser_Linux_x86_64.tar.gz
ENV GORELEASER_DOWNLOAD_URL=https://github.com/goreleaser/goreleaser/releases/download/v${GORELEASER_VERSION}/${GORELEASER_DOWNLOAD_FILE}

RUN  wget ${GORELEASER_DOWNLOAD_URL}; \
			echo "$GORELEASER_SHA $GORELEASER_DOWNLOAD_FILE" | sha256sum -c - || exit 1; \
			tar -xzf $GORELEASER_DOWNLOAD_FILE -C /usr/bin/ goreleaser; \
			rm $GORELEASER_DOWNLOAD_FILE;

RUN apt-get update && \
    apt-get install -y \
    apt-transport-https \
    ca-certificates \
    gnupg-agent

#RUN wget https://download.docker.com/linux/debian/gpg | apt-key add - && \

#RUN curl -fsSL "https://download.docker.com/linux/debian/gpg" | apt-key add - && \
#   add-apt-repository \
#   "deb [arch=amd64] https://download.docker.com/linux/debian \
#   $(lsb_release -cs) \
#   stable"

RUN curl -fsSL "https://download.docker.com/linux/ubuntu/gpg" | apt-key add - && \
   add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"

RUN apt-get update && \
	apt-get install -y docker-ce \
	docker-ce-cli

ENV PATH=${OSX_CROSS_PATH}/target/bin:$PATH
WORKDIR "${GOPATH}/src"

ENTRYPOINT ["/entrypoint.sh"]
#CMD ["-h"]


COPY scripts/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh



