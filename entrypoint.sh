#!/usr/bin/env bash


# This section lifted from mailchain/goreleaser-xcgo
# Note: you probably want to use an access token
# for $DOCKER_PASSWORD rather than your real password.
# See: https://docs.docker.com/docker-hub/access-tokens/
if [ -n "$DOCKER_USERNAME" ] && [ -n "$DOCKER_PASSWORD" ]; then
    echo "Login to docker using $DOCKER_USERNAME ..."
    if docker login -u $DOCKER_USERNAME -p $DOCKER_PASSWORD $DOCKER_REGISTRY;
    then
      echo "Logged into docker"
      echo
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


# To use snapcraft, you must supply a snapcraft login file.
# If the login file is on your host at ~/.snapcraft.login then mount
# that local file to the docker image like this:
#
#  $ docker run -it -v "${HOME}/.snapcraft.login":/.snapcraft.login neilotoole/xcgo:latest zsh
#
# You can specify an alternative mount location in the container like this:
#  $ docker run -it -v -e SNAPCRAFT_LOGIN_FILE=/my/secrets/.snapcraft.login neilotoole/xcgo:latest zsh
#
# Defaults to /.snapcraft.login if not specified via envar
export SNAPCRAFT_LOGIN_FILE="${SNAPCRAFT_LOGIN_FILE:-/.snapcraft.login}"

# If file exists and is not empty
if [ -s "$SNAPCRAFT_LOGIN_FILE" ]; then
  echo "Login to snapcraft using $SNAPCRAFT_LOGIN_FILE ..."
  if snapcraft login --with "$SNAPCRAFT_LOGIN_FILE";
  then
    echo "Logged into snapcraft"
    echo
  else
    exit $?
  fi
fi

exec "$@"