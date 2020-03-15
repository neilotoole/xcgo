# neilotoole/xcgo

`xcgo` is a maximalist Docker image for cross-compiling and
releasing/distributing CGo-enabled Go/Golang applications. At this time, it can build and dist
macOS, Windows and Linux CGo projects for arch `amd64`.

`xcgo` has what gophers crave:

- `go 1.14`
- `OSX SDK` Catalina / `macOS 10.15`
- `docker`
- `snapcraft`
- `goreleaser`
- `golangci-lint`
- `mage`
- `zsh` and `oh-my-zsh`
- and a bunch of other stuff.

The primary source of documentation for `xcgo` is the [wiki](https://github.com/neilotoole/xcgo/wiki). Start there. There's a companion example project ([neilotoole/sqlitr](https://github.com/neilotoole/sqlitr)) that was created explicitly to exhibit `xcgo`: it demonstrates pretty much the entire array of `xcgo`'s capabilities, showing how to release to `brew`, `scoop`, `snap`, Docker Hub, GitHub, etc. The `neilotoole/xcgo` images are published to [Docker Hub](https://hub.docker.com/repository/docker/neilotoole/xcgo).

> Note: No effort has yet been made to provide support for other
> archs such as `386` (or for an OS beyond the typical three),
> but pull requests are welcome. Note also that no effort has been
> made to make this image slim. `xcgo` by mission is
> maximalist (it's a 3GB+ image), but I'm sure the `Dockerfile` 
> can be slimmed down. Again, pull requests are welcome.

## Usage

You can test `xcgo` with:

```shell script
$ docker run -it neilotoole/xcgo:latest go version
go version go1.14 linux/amd64
```

To play around in the container, launch into a shell:

```shell script
$ docker run -it neilotoole/xcgo:latest zsh
```

`xcgo` doesn't prescribe a particular usage approach. Some possibilities:

- Launch a container shell session, clone your repo, and build (or even edit and do all your work) within the container. 
- Mount your local repo into the container, shell in, and build from within the container.
- With local repo mounted, invoke `xcgo` with `goreleaser`: this is pretty typical.

### Example: `go build` inside container

From inside the docker container, we'll build (`amd64`) binaries for macOS, Linux, and Windows.

Shell into the `xcgo` container if you haven't already done so:

```shell script
$ docker run -it neilotoole/xcgo:latest zsh
```

From inside the container:

```shell script
$ git clone https://github.com/neilotoole/sqlitr.git && cd sqlitr
$ GOOS=darwin GOARCH=amd64 CC=o64-clang CXX=o64-clang++ go build -o dist/darwin_amd64/sqlitr
$ GOOS=linux GOARCH=amd64 go build -o dist/linux_amd64/sqlitr
$ GOOS=windows GOARCH=amd64 CC=x86_64-w64-mingw32-gcc CXX=x86_64-w64-mingw32-g++ go build -o dist/windows_amd64/sqlitr.exe
```
You should end up with something like this:

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

### Example: `goreleaser`

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
├── goreleaserdocker393975300
│   ├── Dockerfile
│   ├── LICENSE
│   ├── README.md
│   ├── sqlitr
│   └── testdata
│       └── example.sqlite
├── sqlitr_v0.1.23-snapshot_darwin_amd64.tar.gz
├── sqlitr_v0.1.23-snapshot_linux_amd64
│   └── prime
│       ├── meta
│       │   └── snap.yaml
│       └── sqlitr
├── sqlitr_v0.1.23-snapshot_linux_amd64.deb
├── sqlitr_v0.1.23-snapshot_linux_amd64.rpm
├── sqlitr_v0.1.23-snapshot_linux_amd64.snap
├── sqlitr_v0.1.23-snapshot_linux_amd64.tar.gz
└── sqlitr_v0.1.23-snapshot_windows_amd64.zip
```

Again, see the [wiki](https://github.com/neilotoole/xcgo/wiki) for more.


## Parameterization
Some params that can be passed to `xcgo` (as args to `docker run`):

- **Docker:** `-e DOCKER_USERNAME=X -e DOCKER_PASSWORD=X`
	
	When present, `xcgo`'s `entrypoint.sh` performs a `docker login`.
	Supply `-e DOCKER_REGISTRY=X` to use a registry other than Docker Hub.
	
- **GitHub:** `-e GITHUB_TOKEN=X` or `-e GORELEASER_GITHUB_TOKEN=X`

	Used to publish artifacts to GitHub (e.g. by `goreleaser`).

- **Snapcraft:** `-v "${HOME}/.snapcraft.login":/.snapcraft.login`

	When `/.snapcraft.login` is present in the `xcgo` container, `entrypoint.sh`
	performs a `snapcraft` login. This enables use of `snapcraft`, e.g. by `goreleaser`
	to publish a `snap`.
	
	Supply `-e SNAPCRAFT_LOGIN_FILE=/other/place/.snapcraft.login` to specify an
	alternative mount location for the login file. See the [wiki](https://github.com/neilotoole/xcgo/wiki/Snapcraft) for more.

## Issues

First, consult the [wiki](https://github.com/neilotoole/xcgo/wiki) and
the [neilotoole/sqlitr](https://github.com/neilotoole/sqlitr) example project.
Then open an [issue](https://github.com/neilotoole/xcgo/issues).



## FAQ

See FAQ on [wiki](https://github.com/neilotoole/xcgo/wiki/FAQ).

## Related Projects

Comments for related projects are as of `2020-03-14`:

- [Official golang image](https://hub.docker.com/_/golang): doesn't support CGo.
- [mailchain/goreleaser-xcgo](https://github.com/mailchain/goreleaser-xcgo): doesn't support `go1.14` or `snapcraft`.
- [docker/golang-cross](https://github.com/docker/golang-cross): doesn't support `go1.14` or `snapcraft`.

## Acknowledgments

- [mailchain/goreleaser-xcgo](https://github.com/mailchain/goreleaser-xcgo): this was the original fork point for `xcgo`. 
- [tpoechtrager/osxcross](https://github.com/tpoechtrager/osxcross): fundamental to macOS capabilities.
- [mingw](http://www.mingw.org/): fundamental to Windows capabilities.
- [goreleaser](https://goreleaser.com): core to `xcgo`'s mission. 
- [docker/golang-cross](https://github.com/docker/golang-cross): much gleaned from here.
- [SQLite](https://www.sqlite.org/) and [mattn/sqlite3](https://github.com/mattn/sqlite3): the perfect use case, as seen in `xcgo`'s companion example project [neilotoole/sqlitr](https://github.com/neilotoole/sqlitr).
- And many others, see [sqlitr/go.mod](https://github.com/neilotoole/sqlitr/blob/master/go.mod) at a minimum. If anybody has been overlooked, please open an [issue](https://github.com/neilotoole/xcgo/issues/new).
