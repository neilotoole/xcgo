#!/usr/bin/env bash


# This section lifted from mailchain/goreleaser-xcgo
if [ -n "$DOCKER_USERNAME" ] && [ -n "$DOCKER_PASSWORD" ]; then
    echo "Login to docker..."
    if docker login -u $DOCKER_USERNAME -p $DOCKER_PASSWORD $DOCKER_REGISTRY;
    then
      echo "Logged into docker"
    else
      exit $?
    fi
fi


# Workaround for github actions when access to different repositories is needed.
# Github actions provides a GITHUB_TOKEN secret that can only access the current
# repository and you cannot configure it's value.
# Access to different repositories is needed by brew for example.
if [ -n "$GORELEASER_GITHUB_TOKEN" ] ; then
  export GITHUB_TOKEN=$GORELEASER_GITHUB_TOKEN
fi


# To use snapcraft, you first have to generate a snapcraft login file locally.
# The file location is conventionally determined via an envar.
#
#  $ snapcraft export-login ~/.snapcraft.login
#  $ export SNAPCRAFT_LOGIN_FILE="~/.snapcraft.login"
#
# Then, mount that local file to the docker image, and set the
# envar inside the xcgo container. For example:
#
#  $ docker run -it -v "$SNAPCRAFT_LOGIN_FILE":/.snapcraft.login -e SNAPCRAFT_LOGIN_FILE=/.snapcraft.login neilotoole/xcgo:latest echo hello
if [ -n "$SNAPCRAFT_LOGIN_FILE" ]; then
  echo "Login to snapcraft..."
  if snapcraft login --with "$SNAPCRAFT_LOGIN_FILE";
  then
    echo "Logged into snapcraft"
  else
    exit $?
  fi
fi

exec "$@"