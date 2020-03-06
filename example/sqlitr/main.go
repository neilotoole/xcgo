package main

import (
	"fmt"
	"os"
)

func main() {
	fmt.Println("hello world")
	if len(os.Args) != 2 {
		fmt.Fprintln(os.Stderr, "Usage: sqlitr 'SELECT * FROM table'")
		os.Exit(1)
		return
	}
}
