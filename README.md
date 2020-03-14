# neilotoole/xcgo

`xcgo` is a maximalist builder image for cross-compiling and
releasing/distrubting CGo-enabled Go/Golang applications. It can build
macOS, Windows and Linux targets for arch `amd64`.


> No effort has been made to provide support for other
> archs such as `386` (or for an OS beyond the three big ones),
> but pull requests are welcome.

> Also, no effort has been made to make this image slim. It's
> maximalist, but for sure, the `Dockerfile` can be improved to be
> slimmer. Again, pull requests are welcome.

`xcgo` has what gophers crave:

- `go 1.14`
- `macOS SDK 10.15` Catalina
- `docker` CLI
- `sqlite3`
- `snapcraft`
- `goreleaser`
- `golangci-lint`
- `mage`
- `zsh` and `oh-my-zsh`
- and a bunch of other stuff.

## Usage

There's a companion example project ([neilotoole/sqlitr](https://github.com/neilotoole/sqlitr)) that was explicitly created to demonstrate `xcgo`, that's the best place to start. It demonstrates pretty much the entire array of `xcgo`'s capabilities.

To play around with the image, launch into zsh:

```shell script
$ docker run -it neilotoole/xcgo:latest zsh
```


### go build

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

### goreleaser

Quite possibly you'll want to use `xcgo` in conjunction 
with [goreleaser](http://goreleaser.com). 

On your local machine, we'll clone the `sqlitr` repo, mount it into the `xcgo` container and run `goreleaser`.

```shell script
$ git clone https://github.com/neilotoole/sqlitr.git && cd sqlitr
$ docker run --rm --privileged \
-v $(pwd):/go/src/github.com/neilotoole/sqlitr \
-v /var/run/docker.sock:/var/run/docker.sock \
-w /go/src/github.com/neilotoole/sqlitr \
neilotoole/xcgo:latest goreleaser --snapshot --rm-dist

$ docker tree
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
├── sqlitr_v0.0.0-snapshot_darwin_amd64.tar.gz
├── sqlitr_v0.0.0-snapshot_linux_amd64.tar.gz
└── sqlitr_v0.0.0-snapshot_windows_amd64.tar.gz
```


Again, see the [neilotoole/sqlitr](https://github.com/neilotoole/sqlitr) project for more.

## Contributors

See the [wiki](https://github.com/neilotoole/xcgo/wiki).

## Related Projects

Comments for related projects are as of `2020-03-11`:

- [Offical golang image](https://hub.docker.com/_/golang): doesn't support CGo
- [mailchain/goreleaser-xcgo](https://github.com/mailchain/goreleaser-xcgo): doesn't support `go1.14` or `snap`
- [docker/golang-cross](https://github.com/docker/golang-cross): doesn't support `go1.14` or `snap`

## Acknowledgments

- [mailchain/goreleaser-xcgo](https://github.com/mailchain/goreleaser-xcgo)... great bunch of lads.
- [docker/golang-cross](https://github.com/docker/golang-cross)
- [mattn/sqlite3](https://github.com/mattn/sqlite3)
- [ubuntu/snap](https://hub.docker.com/r/snapcore/snapcraft)
- Many others, see [sqlitr/go.mod](https://github.com/neilotoole/sqlitr/blob/master/go.mod) at a minimum. If anybody has been omitted from this list, please [open an issue](https://github.com/neilotoole/xcgo/issues/new).
