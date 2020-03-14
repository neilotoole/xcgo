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

Quite probably you'll want to use `xcgo` in conjunction 
with [goreleaser](http://goreleaser.com). 

```shell script
$ git clone https://github.com/neilotoole/sqlitr.git
$ cd sqlitr
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
