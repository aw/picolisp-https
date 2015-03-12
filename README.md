# HTTP(S) (Neon) FFI Bindings for PicoLisp

[![GitHub release](https://img.shields.io/github/release/aw/picolisp-https.svg)](https://github.com/aw/picolisp-https) [![Dependency](https://img.shields.io/badge/[deps] Neon-0.30.1-ff69b4.svg)](https://github.com/aw/neon-unofficial-mirror)

This library can be used to make HTTP and HTTPS requests in [PicoLisp](http://picolisp.com).

# Requirements

  * PicoLisp 64-bit v3.1.9+
  * Git
  * UNIX/Linux development/build tools (gcc, make/gmake, etc..)
  * OpenSSL

# Getting started

This binding relies on the _Neon C library._, compiled as a shared library. It is included here as a [git submodule](http://git-scm.com/book/en/v2/Git-Tools-Submodules).

  1. Type `./build.sh` to pull and compile the _Neon C Library_.
  2. Include `https.l` in your project (it loads `ffi.l` and `internal.l`)
  3. Try the example below

## Linking and Paths

Once compiled, the shared library is symlinked in `lib/libneon.so` pointing to `vendor/neon/src/.libs/libneon.so`.

The `https.l` file searches for `lib/libneon.so`, relative to its current directory.

# Usage

All functions are publicly accessible and namespaced with `(symbols 'https)` (or the prefix: `https~`), but only the following are necessary:

  * `req-get`: downloads a file from `Fullurl` and appends `Headers` to the `GET` request

A successful result will return a list containing the file name, size, status code, and HTTP headers. A failure returns `NIL` and might possibly quit.

# Example (req-get Url Headers Destination)

In this example, we try to fetch from a URL that doesn't exist, and receive a response body, headers, and other useful information.

```lisp
pil +

(load "https.l")

(symbols 'https)

(pretty
  (req-get
    "https://google.com/404"
    '(("User-Agent" . "picolisp-https"))
    (random-filename) ) )

-> (("Filename" . "/home/aw/.pil/tmp/1689/dl-fc6ccf5.tmp")
    ("Filesize" . 1428)
    ("Version" . "HTTP/1.1")
    ("Code" . 404)
    ("Message" . "Not Found")
    ("Url" . "https://google.com/404")
    ("Headers"  ("date" . "Wed, 11 Mar 2015 05:54:07 GMT")
                ("content-length" . "1428")
                ("server" . "GFE/2.0")
                ("content-type" . "text/html; charset=UTF-8") ) )
```

# TODO

* Other HTTP methods such as HEAD, POST, PUT.
* Better error handling (don't quit)

# Contributing

If you find any bugs or issues, please [create an issue](https://github.com/aw/picolisp-https/issues/new).

If you want to improve this library, please make a pull-request.

# License

[MIT License](LICENSE)
Copyright (c) 2015 Alexander Williams, Unscramble <license@unscramble.jp>
