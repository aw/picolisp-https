# HTTP(S) (Neon) FFI Bindings

[HTTPS](http://www.webdav.org/neon/) (Neon) FFI bindings for [PicoLisp](http://picolisp.com/).

This library can be used to make HTTP and HTTPS requests.

# Version

**v0.30.1.0** (uses Neon v_0.30.1_)

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

  * `get-file`: downloads a file from `Fullurl` and appends `Headers` to the `GET` request

A successful result will return a list containing the file name, size, status code, and HTTP headers. A failure returns `NIL` and might possibly quit.

# Example (get-file Url Headers)

In this example, we try to fetch from a URL that doesn't exist, and receive a response body, headers, and other useful information.

```lisp
pil +

(load "https.l")

(symbols 'https)

(pretty
  (req-get-file
    "https://google.com/404"
    '(("User-Agent" . "picolisp-https")) ) )

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

* Ability to follow redirects from status codes 302, 307.
* Other HTTP methods such as HEAD, POST, PUT.
* Better error handling (don't quit)

# Contributing

If you find any bugs or issues, please [create an issue](https://github.com/aw/picolisp-https/issues/new).

If you want to improve this library, please make a pull-request.

# License

[MIT License](LICENSE)
Copyright (c) 2015 Alexander Williams, Unscramble <license@unscramble.jp>