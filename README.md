# xcgo
`xcgo` is a maximalist builder image for cross-compiling and
releasing CGo-enabled Go/Golang applications. It can build
macOS, Windows and Linux targets for arch `amd64`.
No effort has been made to provide support for other
archs such as `386`, but pull requests are welcome.

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

This should start you out in `$GOPATH/src`.

Quite possibly, you'll want to use `xcgo` in conjunction 
with [goreleaser](http://goreleaser.com).

## Build Image
From this repo root:

```shell script
$ docker build -t neilotoole/xcgo:latest .
```

## Acknowledgments

- [mailchain/goreleaser-xcgo](https://github.com/mailchain/goreleaser-xcgo)... great bunch of lads.
- [docker/golang-cross](https://github.com/docker/golang-cross)
- [mattn/sqlite3](https://github.com/mattn/sqlite3)
- [ubuntu/snap](https://hub.docker.com/r/snapcore/snapcraft)
- Many others, see [sqlitr/go.mod](https://github.com/neilotoole/sqlitr/blob/master/go.mod) at a minimum. If anybody has been omitted from this list, please [open an issue](https://github.com/neilotoole/xcgo/issues/new).
