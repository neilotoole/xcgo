# This neilotoole/xcgo Dockerfile builds a maximalist golang CGo-enabled
# cross-compiling image with a bunch of developer tools on it. It can
# build CGo apps on macOS, Linux, and Windows. It also contains supporting
# tools such as Docker and snapcraft.



# Note that xcgo.s3.amazonaws.com is xcgo's own S3 bucket that holds stuff
# that's hard to find, e.g. macOS SDK.
ARG OSX_SDK=MacOSX10.15.sdk
ARG OSX_CODENAME=catalina
ARG OSX_VERSION_MIN=10.10
ARG OSX_SDK_SUM=d97054a0aaf60cb8e9224ec524315904f0309fbbbac763eb7736bdfbdad6efc8
ARG OSX_SDK_BASEURL="https://xcgo.s3.amazonaws.com/macos/sdk"
ARG OSX_CROSS_COMMIT=bee9df60f169abdbe88d8529dbcc1ec57acf656d
ARG LIBTOOL_VERSION=2.4.6_1
ARG LIBTOOL_BASEURL="https://xcgo.s3.amazonaws.com/macos/libtool"



####################  snapcore  ####################
FROM ubuntu:bionic AS snapcore
# We build from ubuntu:bionic because we need snapcraft. It's difficult
# to build a, say, Debian-based image with snapcraft. Note also that
# the snapcore/snapcraft images are based upon ubuntu:xenial, but we
# want ubuntu:bionic (some things we want, e.g. go1.14, don't have good
# packages for xenial). Also, we generically want to stay pretty current
# with all the tech in this stack.

LABEL maintainer="neilotoole@apache.org"

# This section taken from snapcore/snapcraft:stable
# Grab dependencies
RUN apt-get update && apt-get dist-upgrade -y && apt-get install -y \
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

## Multi-stage build, only need the snaps from the builder. Copy them one at a
## time so they can be cached.
#FROM ubuntu:xenial
#COPY --from=builder /snap/core /snap/core
#COPY --from=builder /snap/core18 /snap/core18
#COPY --from=builder /snap/snapcraft /snap/snapcraft
#COPY --from=builder /snap/bin/snapcraft /snap/bin/snapcraft

# Generate locale.
RUN apt-get update && apt-get dist-upgrade && apt-get install -y sudo locales && locale-gen en_US.UTF-8

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
RUN apt-get update -y && apt-get install -y --no-install-recommends \
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
RUN add-apt-repository -y ppa:longsleep/golang-backports
RUN apt update -y && apt install -y golang-go



####################  devtools  ####################
FROM golangcore AS devtools
# Dependencies for https://github.com/tpoechtrager/osxcross:
RUN apt-get update -y -qq && apt-get install -y -q --no-install-recommends \
    clang \
    cmake \
    file \
    llvm \
    patch \
    build-essential \
    libxml2-dev \
    libssl-dev \
    xz-utils \
    zlib1g-dev  \
    libc++-dev  \
    libltdl-dev \
    gcc-mingw-w64 \
    parallel \
    sqlite3 libsqlite3-dev

ENV OSX_CROSS_PATH=/osxcross



####################  osx-sdk  ####################
FROM devtools AS osx-sdk
ARG OSX_SDK
ARG OSX_SDK_SUM
ARG OSX_SDK_BASEURL
ADD "${OSX_SDK_BASEURL}/${OSX_SDK}.tar.xz" "${OSX_CROSS_PATH}/tarballs/${OSX_SDK}.tar.xz"
RUN echo "${OSX_SDK_SUM}"  "${OSX_CROSS_PATH}/tarballs/${OSX_SDK}.tar.xz" | sha256sum -c -



####################  osx-cross  ####################
FROM devtools AS osx-cross
ARG OSX_CROSS_COMMIT
WORKDIR "${OSX_CROSS_PATH}"
RUN git clone https://github.com/tpoechtrager/osxcross.git . \
 && git checkout -q "${OSX_CROSS_COMMIT}" \
 && rm -rf ./.git
COPY --from=osx-sdk "${OSX_CROSS_PATH}/." "${OSX_CROSS_PATH}/"
ARG OSX_VERSION_MIN
RUN UNATTENDED=yes OSX_VERSION_MIN=${OSX_VERSION_MIN} ./build.sh



####################  libtool  ####################
FROM osx-cross AS libtool
ARG LIBTOOL_VERSION
ARG LIBTOOL_BASEURL
ARG OSX_CODENAME
ARG OSX_SDK


RUN mkdir -p "${OSX_CROSS_PATH}/target/SDK/${OSX_SDK}/usr/"
RUN curl -fsSL "${LIBTOOL_BASEURL}/libtool-${LIBTOOL_VERSION}.${OSX_CODENAME}.bottle.tar.gz" \
	| gzip -dc | tar xf - \
		-C "${OSX_CROSS_PATH}/target/SDK/${OSX_SDK}/usr/" \
		--strip-components=2 \
		"libtool/${LIBTOOL_VERSION}/include/" \
		"libtool/${LIBTOOL_VERSION}/lib/"



####################  docker  ####################
FROM libtool AS docker
RUN apt-get update && \
    apt-get install -y \
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
ENV GORELEASER_VERSION=0.128.0
ENV GORELEASER_SHA=2d9bcff7612700a2a9fe4a085a7f1a84298c2f4d70eab50b1eb5aa5d7863f7c4
ENV GORELEASER_DOWNLOAD_FILE=goreleaser_Linux_x86_64.tar.gz
ENV GORELEASER_DOWNLOAD_URL=https://github.com/goreleaser/goreleaser/releases/download/v${GORELEASER_VERSION}/${GORELEASER_DOWNLOAD_FILE}

RUN wget "${GORELEASER_DOWNLOAD_URL}"; \
    echo "$GORELEASER_SHA $GORELEASER_DOWNLOAD_FILE" | sha256sum -c - || exit 1; \
    tar -xzf $GORELEASER_DOWNLOAD_FILE -C /usr/bin/ goreleaser; \
    rm $GORELEASER_DOWNLOAD_FILE;

# Let's add mage - https://magefile.org
RUN cd /tmp && git clone https://github.com/magefile/mage.git && cd mage && go run bootstrap.go && rm -rf /tmp/mage

# https://github.com/golangci/golangci-lint
RUN curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s -- -b $(go env GOPATH)/bin v1.23.8



####################  sugar  ####################
# Adding some sugar-on-top, it's not like this image is going to be slim anyway.
FROM gotools AS sugar

# Install ohmyzsh
RUN sh -c "$(wget -O- https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
# And some sweet fonts
RUN apt-get update && apt-get install -y fonts-powerline

# Add some non-core ohmyzsh plugins
RUN git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
RUN git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
# Enable some plugins by default
RUN sed -i 's/plugins=(git)/plugins=( git golang zsh-syntax-highlighting zsh-autosuggestions docker ubuntu )/' ~/.zshrc


WORKDIR "${GOPATH}/src"


####################  final  ####################
FROM sugar AS final
ENV PATH=${OSX_CROSS_PATH}/target/bin:$PATH:${GOPATH}/bin
ENV CGO_ENABLED=1
ENTRYPOINT ["/entrypoint.sh"]
COPY scripts/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh



