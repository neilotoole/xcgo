# neilotoole/xcgo

`xcgo` is a maximalist Docker image for cross-compiling and
releasing/distrubting CGo-enabled Go/Golang applications. It can build
macOS, Windows and Linux CGo projects for arch `amd64`.

> No effort has yet been made to provide support for other
> archs such as `386` (or for an OS beyond the three big ones),
> but pull requests are welcome.

> Also, no effort has been made to make this image slim. `xcgo` by mission is
> maximalist (`3GB+` image), but it seems highly likely the `Dockerfile` can be slimmed down. Again, pull requests are welcome.

`xcgo` has what gophers crave:

- `go 1.14`
- `macOS SDK 10.15` Catalina
- `docker` CLI
- `snapcraft`
- `goreleaser`
- `golangci-lint`
- `mage`
- `zsh` and `oh-my-zsh`
- and a bunch of other stuff.

There's a companion example project ([neilotoole/sqlitr](https://github.com/neilotoole/sqlitr)) that was created explicitly to demonstrate `xcgo`, that's the best place to start. It demonstrates pretty much the entire array of `xcgo`'s capabilities: it releases to `brew`, `scoop`, `snap`, Docker Hub, GitHub, etc.

To play around with the `xcgo` image, launch into zsh:

```shell script
$ docker run -it neilotoole/xcgo:latest zsh
```

`xcgo` doesn't prescribe a particular usage approach. Some possibilities:

- Launch a container shell session, clone your repo, and build (or even edit) within the container. 
- Mount your local repo into the container, shell in, and build from within the container.
- Invoke `xcgo` with `goreleaser` (local repo mounted) -- this is pretty typical.

Let's look at a few of these approaches:

## `go build` inside container

From inside the docker container, we'll build (`amd64`) binaries for macOS, Linux, and Windows.

```shell script
$ git clone https://github.com/neilotoole/sqlitr.git && cd sqlitr
$ GOOS=darwin GOARCH=amd64 CC=o64-clang CXX=o64-clang++ go build -o dist/darwin_amd64/sqlitr
$ GOOS=linux GOARCH=amd64 go build -o dist/linux_amd64/sqlitr
$ GOOS=windows GOARCH=amd64 CC=x86_64-w64-mingw32-gcc CXX=x86_64-w64-mingw32-g++ go build -o dist/windows_amd64/sqlitr.exe
```
You should end up with these:

```shell script
$ tree ./dist
./dist
├── darwin_amd64
│   └── sqlitr
├── linux_amd64
│   └── sqlitr
└── windows_amd64
    └── sqlitr.exe
```

Running `file` on each of the binaries:

```shell script
./dist/darwin_amd64/sqlitr: Mach-O 64-bit x86_64 executable, flags:<NOUNDEFS|DYLDLINK|TWOLEVEL>
./dist/linux_amd64/sqlitr: ELF 64-bit LSB executable, x86-64, version 1 (SYSV), dynamically linked, interpreter /lib64/l, for GNU/Linux 3.2.0, BuildID[sha1]=9a130449828e21fc5ef935582d889bba0344432c, not stripped
./dist/windows_amd64/sqlitr.exe: PE32+ executable (console) x86-64, for MS Windows
```

> Note that the linux binary listed above is dynamically linked. There are additional steps you can take to statically link instead (useful if you're distributing on an Alpine image for example). See [sqlitr .goreleaser.yml](https://github.com/neilotoole/sqlitr/blob/master/.goreleaser.yml) `build_linux` section.

## `goreleaser`

Quite possibly you'll want to use `xcgo` in conjunction 
with [goreleaser](http://goreleaser.com). 

Again, we'll use `sqlitr` to demonstrate. On your local machine, clone the `sqlitr` repo, mount it into the `xcgo` container and run `goreleaser`.

```shell script
$ git clone https://github.com/neilotoole/sqlitr.git && cd sqlitr
$ docker run --rm --privileged \
-v $(pwd):/go/src/github.com/neilotoole/sqlitr \
-v /var/run/docker.sock:/var/run/docker.sock \
-w /go/src/github.com/neilotoole/sqlitr \
neilotoole/xcgo:latest goreleaser --snapshot --rm-dist

$ tree ./dist
```

The above will build that CGo project via `goreleaser` with binaries for macOS, Linux, and Windows.

```shell script
$ tree ./dist
./dist
├── build_linux_linux_amd64
│   └── sqlitr
├── build_macos_darwin_amd64
│   └── sqlitr
├── build_windows_windows_amd64
│   └── sqlitr.exe
├── checksums.txt
├── config.yaml
├── sqlitr.rb
├── sqlitr_0.1.10_darwin_amd64.tar.gz
├── sqlitr_0.1.10_linux_amd64
│   └── prime
│       ├── meta
│       │   └── snap.yaml
│       └── sqlitr
├── sqlitr_0.1.10_linux_amd64.snap
├── sqlitr_0.1.10_linux_amd64.tar.gz
└── sqlitr_0.1.10_windows_amd64.zip
```

The above example uses `goreleaser --snapshot`. To actually publish artifacts (`brew`, `scoop`, `snap`, `dockerhub`, etc), you need to inject appropriate secrets into the `xcgo` container. In this next example we pass secrets for GitHub, `docker`, and `snapcraft`.

> Note that this example actually won't succeed for you (as you don't have the secrets)

```shell script
docker run --rm --privileged \
-v $(pwd):/go/src/github.com/neilotoole/sqlitr \
-v /var/run/docker.sock:/var/run/docker.sock \
-e "GITHUB_TOKEN=$GITHUB_TOKEN" \
-e "DOCKER_USERNAME=$DOCKER_USERNAME" -e "DOCKER_PASSWORD=$DOCKER_PASSWORD" -e "DOCKER_REGISTRY=$DOCKER_REGISTRY" \
-v "${HOME}/.snapcraft.login":/.snapcraft.login \
-w /go/src/github.com/neilotoole/sqlitr \
neilotoole/xcgo:latest goreleaser --rm-dist
```

Again, see the [neilotoole/sqlitr](https://github.com/neilotoole/sqlitr) example project for more.

## `xcgo` Parameterization
There are a few 



> Note: much of the `xcgo` container parameterization effectively feeds `goreleaser`. 

```
-e GITHUB_TOKEN=X
# or
-e GORELEASER_GITHUB_TOKEN=X

# docker registry (typically docker hub)
-e DOCKER_USERNAME=X -e DOCKER_PASSWORD=X -e DOCKER_REGISTRY=X

# snapcraft
-v "${HOME}/.snapcraft.login":/.snapcraft.login
# optionally 
-e SNAPCRAFT_LOGIN_FILE=/some/where/.snapcraft.login

```


## Feedback, issues, changes

Open a GitHub [issue](https://github.com/neilotoole/xcgo/issues). Also, see the [wiki](https://github.com/neilotoole/xcgo/wiki).

## Related Projects

Comments for related projects are as of `2020-03-11`:

- [Offical golang image](https://hub.docker.com/_/golang): doesn't support CGo
- [mailchain/goreleaser-xcgo](https://github.com/mailchain/goreleaser-xcgo): doesn't support `go1.14` or `snap`
- [docker/golang-cross](https://github.com/docker/golang-cross): doesn't support `go1.14` or `snap`

## Acknowledgments

- [mailchain/goreleaser-xcgo](https://github.com/mailchain/goreleaser-xcgo): this was the original starting point for `xcgo`. 
- [tpoechtrager/osxcross](https://github.com/tpoechtrager/osxcross): utterly fundamental to the `macOS` capabilities.
- [goreleaser](https://goreleaser.com): obviously core to `xcgo`'s mission. 
- [docker/golang-cross](https://github.com/docker/golang-cross)
- [mattn/sqlite3](https://github.com/mattn/sqlite3)
- Many others, see [sqlitr/go.mod](https://github.com/neilotoole/sqlitr/blob/master/go.mod) at a minimum. If anybody has been omitted from this list, please [open an issue](https://github.com/neilotoole/xcgo/issues/new).
