# xcgo
`xcgo` is a maximalist builder image for cross-compiling and
releasing CGo-enabled Go/Golang applications. It can build
macOS, Windows and Linux targets.

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
To play around with the image, we'll launch into zsh:

```shell script
$ docker run -it neilotoole/xcgo:latest zsh
```

This should start you out in `$GOPATH/src`.

Quite possibly, you'll want to use `xcgo` in conjunction 
with [goreleaser](http://goreleaser.com).