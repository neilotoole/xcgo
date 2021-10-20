# This neilotoole/xcgo Dockerfile builds a maximalist Go/Golang CGo-enabled
# cross-compiling image It can build CGo apps on macOS, Linux, and Windows.
# It also contains supporting tools such as docker and snapcraft.
# See https://github.com/neilotoole/xcgo
ARG OSX_SDK="MacOSX10.15.sdk"
ARG OSX_CODENAME="catalina"
ARG OSX_VERSION_MIN="10.10"
ARG OSX_SDK_BASEURL="https://github.com/neilotoole/xcgo/releases/download/v0.1"
ARG OSX_SDK_SUM="d97054a0aaf60cb8e9224ec524315904f0309fbbbac763eb7736bdfbdad6efc8"
ARG OSX_CROSS_COMMIT="bee9df60f169abdbe88d8529dbcc1ec57acf656d"
ARG LIBTOOL_VERSION="2.4.6_1"
ARG LIBTOOL_BASEURL="https://github.com/neilotoole/xcgo/releases/download/v0.1"
ARG GOLANGCI_LINT_VERSION="1.37.1"
ARG GORELEASER_VERSION="0.182.1"



####################  snapbuilder ####################
FROM ubuntu:bionic AS snapbuilder
# We build from ubuntu:bionic because we need snapcraft. It's difficult
# to build, say, a Debian-based image with snapcraft included. Note also that
# the snapcore/snapcraft images are based upon ubuntu:xenial, but we
# want ubuntu:bionic (some things we want, e.g. go1.14, don't have good
# packages for xenial). Also, generically, want to stay pretty current
# with all the tech in this stack.

# This section lifted from snapcore/snapcraft:stable
# Grab dependencies
RUN apt-get update && apt-get dist-upgrade -y && apt-get install -y \
      curl \
      jq \
      lsb-core \
      squashfs-tools


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

# Create a snapcraft runner
RUN mkdir -p /snap/bin
RUN echo "#!/bin/sh" > /snap/bin/snapcraft
RUN snap_version="$(awk '/^version:/{print $2}' /snap/snapcraft/current/meta/snap.yaml)" && echo "export SNAP_VERSION=\"$snap_version\"" >> /snap/bin/snapcraft
RUN echo 'exec "$SNAP/usr/bin/python3" "$SNAP/bin/snapcraft" "$@"' >> /snap/bin/snapcraft
RUN chmod +x /snap/bin/snapcraft

RUN apt update && apt install -y snapd

## Multi-stage build, only need the snaps from the builder. Copy them one at a
## time so they can be cached.
FROM ubuntu:bionic AS snapcore
COPY --from=snapbuilder /snap/core /snap/core
COPY --from=snapbuilder /snap/core18 /snap/core18
COPY --from=snapbuilder /snap/snapcraft /snap/snapcraft
COPY --from=snapbuilder /snap/bin/snapcraft /snap/bin/snapcraft

# Generate locale.
RUN apt-get update && apt-get dist-upgrade -y && apt-get install -y sudo locales && locale-gen en_US.UTF-8

# Set the proper environment.
ENV LANG="en_US.UTF-8"
ENV LANGUAGE="en_US:en"
ENV LC_ALL="en_US.UTF-8"
ENV PATH="/snap/bin:$PATH"
ENV SNAP="/snap/snapcraft/current"
ENV SNAP_NAME="snapcraft"
ENV SNAP_ARCH="amd64"

####################  golangcore  ####################
FROM snapcore AS golangcore
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    git \
    jq \
    lsb-core \
    software-properties-common

ENV GOPATH="/go"
RUN mkdir -p "${GOPATH}/src"

# As suggested here: https://github.com/golang/go/wiki/Ubuntu
RUN add-apt-repository -y ppa:longsleep/golang-backports
RUN apt update && apt install -y golang-1.16
RUN ln -s /usr/lib/go-1.16 /usr/lib/go
RUN ln -s /usr/lib/go/bin/go /usr/bin/go
RUN ln -s /usr/lib/go/bin/gofmt /usr/bin/gofmt

RUN go version


####################  devtools  ####################
FROM golangcore AS devtools
# Dependencies for https://github.com/tpoechtrager/osxcross and some
# other stuff.

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    clang \
    cmake \
    file \
    gcc-mingw-w64 gcc-mingw-w64-i686 gcc-mingw-w64-x86-64 \
    less \
    libc6-dev \
    libc6-dev-i386 \
    libc++-dev  \
    libltdl-dev \
    libsqlite3-dev \
    libssl-dev \
    libxml2-dev \
    llvm \
    man \
    parallel \
    patch \
    sqlite3 \
    tree \
    vim \
    wget \
    xz-utils \
    zlib1g-dev  \
    zsh



####################  osx-cross  ####################
# See https://github.com/tpoechtrager/osxcross
FROM devtools AS osx-cross
ARG OSX_SDK
ARG OSX_CODENAME
ARG OSX_SDK_BASEURL
ARG OSX_SDK_SUM
ARG OSX_CROSS_COMMIT
ARG OSX_VERSION_MIN
ARG LIBTOOL_VERSION
ARG LIBTOOL_BASEURL
ENV OSX_CROSS_PATH=/osxcross

WORKDIR "${OSX_CROSS_PATH}"
RUN git clone https://github.com/tpoechtrager/osxcross.git . \
 && git checkout -q "${OSX_CROSS_COMMIT}" \
 && rm -rf ./.git

RUN curl -fsSL "${OSX_SDK_BASEURL}/${OSX_SDK}.tar.xz" -o "${OSX_CROSS_PATH}/tarballs/${OSX_SDK}.tar.xz"
RUN echo "${OSX_SDK_SUM}"  "${OSX_CROSS_PATH}/tarballs/${OSX_SDK}.tar.xz" | sha256sum -c -

RUN UNATTENDED=yes OSX_VERSION_MIN=${OSX_VERSION_MIN} ./build.sh

RUN mkdir -p "${OSX_CROSS_PATH}/target/SDK/${OSX_SDK}/usr/"
RUN curl -fsSL "${LIBTOOL_BASEURL}/libtool-${LIBTOOL_VERSION}.${OSX_CODENAME}.bottle.tar.gz" \
	| gzip -dc | tar xf - \
		-C "${OSX_CROSS_PATH}/target/SDK/${OSX_SDK}/usr/" \
		--strip-components=2 \
		"libtool/${LIBTOOL_VERSION}/include/" \
		"libtool/${LIBTOOL_VERSION}/lib/"

WORKDIR /root



####################  docker  ####################
FROM osx-cross AS docker
RUN apt-get update -y && apt-get install -y --no-install-recommends \
    apt-transport-https \
    ca-certificates \
    gnupg-agent


RUN curl -fsSL "https://download.docker.com/linux/ubuntu/gpg" | apt-key add - && \
   add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"

RUN apt-get update && apt-get install -y docker-ce docker-ce-cli



####################  gotools  ####################
FROM docker AS gotools
# This section descended from https://github.com/mailchain/goreleaser-xcgo
# Much gratitude to the mailchain team.
ARG GORELEASER_VERSION
ARG GORELEASER_DOWNLOAD_FILE="goreleaser_Linux_x86_64.tar.gz"
ARG GORELEASER_DOWNLOAD_URL="https://github.com/goreleaser/goreleaser/releases/download/v${GORELEASER_VERSION}/${GORELEASER_DOWNLOAD_FILE}"
ARG GOLANGCI_LINT_VERSION

RUN wget "${GORELEASER_DOWNLOAD_URL}"; \
    tar -xzf $GORELEASER_DOWNLOAD_FILE -C /usr/bin/ goreleaser; \
    rm $GORELEASER_DOWNLOAD_FILE;

# Add mage - https://magefile.org
RUN cd /tmp && git clone https://github.com/magefile/mage.git && cd mage && go run bootstrap.go && rm -rf /tmp/mage

# https://github.com/golangci/golangci-lint
RUN curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s -- -b $(go env GOPATH)/bin "v${GOLANGCI_LINT_VERSION}"



####################  xcgo-final  ####################
FROM gotools AS xcgo-final
LABEL maintainer="neilotoole@apache.org"
ENV PATH=${OSX_CROSS_PATH}/target/bin:$PATH:${GOPATH}/bin
ENV CGO_ENABLED=1

WORKDIR /root
COPY ./entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
