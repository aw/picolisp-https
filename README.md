# HTTP(S) client for PicoLisp

[![GitHub release](https://img.shields.io/github/release/aw/picolisp-https.svg)](https://github.com/aw/picolisp-https) [![Build Status](https://travis-ci.org/aw/picolisp-https.svg?branch=master)](https://travis-ci.org/aw/picolisp-https) [![Dependency](https://img.shields.io/badge/[deps] Neon-0.30.1-ff69b4.svg)](https://github.com/aw/neon-unofficial-mirror) [![Dependency](https://img.shields.io/badge/[deps] picolisp--unit-v1.0.0-ff69b4.svg)](https://github.com/aw/picolisp-unit.git)

This library can be used to make HTTP and HTTPS requests in [PicoLisp](http://picolisp.com), with support for authentication.

![picolisp-https](https://cloud.githubusercontent.com/assets/153401/6665239/08fe38ee-cbcf-11e4-8289-603c985c1c0f.png)

Please read [EXPLAIN.md](EXPLAIN.md) to learn more about PicoLisp and this HTTPS library.

  1. [Requirements](#requirements)
  2. [Getting Started](#getting-started)
  3. [Usage](#usage)
  4. [Examples](#examples)
  5. [Testing](#testing)
  6. [Alternatives](#alternatives)
  7. [Contributing](#contributing)
  8. [License](#license)

# Requirements

  * PicoLisp 64-bit v3.1.9+
  * Git
  * UNIX/Linux development/build tools (gcc, make/gmake, etc..)
  * OpenSSL

# Getting Started

These FFI bindings require the [Neon C library](http://www.webdav.org/neon/), compiled as a shared library.

  1. Type `make` to pull and compile the _Neon C Library_.
  2. Include `https.l` in your project (it loads `ffi.l` and `internal.l`).
  3. Try the [examples](#examples) below

### Linking and Paths

Once compiled, the shared library is symlinked as:

    .lib/libneon.so -> .modules/neon/HEAD/src/.libs/libneon.so

The `https.l` file searches for `.lib/libneon.so`, relative to its current directory.

### Updating

To keep everything updated, type:

    git pull && make clean && make

# Usage

Only the following functions are exported publicly, and namespaced with `(symbols 'https)` (or the prefix: `https~`):

  * **(uriparse Url)** parses a sanitized URL into its separate parts
    - `Url` _String_: a URL string to be parsed (does not encode the URL)
  * **(req-get Url Headers Filename)** performs an HTTP `GET` request
    - `Url` _String_: a URL string to make the HTTP request
    - `Headers` _List (optional)_: a PicoLisp list of cons pairs containing HTTP headers
    - `Filename` _String_ or _Flag (optional)_: can be a full path to a filename to store the HTTP Body content, the flag `T` to generate a random filename and store in a tmp dir (`~/.pil/tmp`), or `NIL` to return the Body in the `Response` list
  * **(req-head Url Headers)** performs an HTTP `HEAD` request
    - `Url` _String_: a URL string to make the HTTP request
    - `Headers` _List (optional)_: a PicoLisp list of cons pairs containing HTTP headers
  * **(req-post Url Headers Filename Body)** performs an HTTP `POST` request
    - `Url` _String_: a URL string to make the HTTP request
    - `Headers` _List (optional)_: a PicoLisp list of cons pairs containing HTTP headers
    - `Filename` _String_ or _Flag (optional)_: can be a full path to a filename to store the HTTP Body content, the flag `T` to generate a random filename and store in a tmp dir (`~/.pil/tmp`), or `NIL` to return the Body in the `Response` list
    - `Body` _String (optional)_: a string to be sent as part of the HTTP body. Make sure to set the proper `Content-Type` headers.
  * **(req-put Url Headers Filename Body)**: performs an idempotent HTTP `PUT` request (same as `POST`).
  * **(req-delete Url Headers Filename)**: performs an HTTP `DELETE` request
    - `Url` _String_: a URL string to make the HTTP request
    - `Headers` _List (optional)_: a PicoLisp list of cons pairs containing HTTP headers
    - `Filename` _String_ or _Flag (optional)_: can be a full path to a filename to store the HTTP Body content, the flag `T` to generate a random filename and store in a tmp dir (`~/.pil/tmp`), or `NIL` to return the Body in the `Response` list
  * **(req Method Url Headers Filename Body)**: performs an HTTP requeste using the `Method` you provide. The arguments to `req` are the same as the convenience methods list above.

> **Note:** These functions are not namespace [local symbols](http://software-lab.de/doc/refL.html#local), which means they would redefine symbols with the same name in the `'pico` namespace

### Notes

  * A successful result will return a list. Failures return `NIL` or throw an `'InternalError`.
  * Arguments are not sanitized, validated, encoded or cleaned in any way. It's up to you to perform those tasks before sending data to the public functions.
  * Only three default headers are sent on each request. They can be overwritten to suit your needs:
    - `Accept: */*`
    - `Accept-Charset: utf/8`
    - `User-Agent: picolisp-https`
  * The `Host` header and `HTTP/1.1` strings are sent automatically by the native C library.
   - Many authorization schemes are supported, but only `Auth-Basic and Auth-Digest` have been tested successfully. See [more here](https://github.com/aw/neon-unofficial-mirror/blob/master/src/ne_auth.h#L67).

# Examples

### (uriparse Url)

```lisp
pil +

(load "https.l")

(symbols 'https)
(uriparse "http://user:pass@test.url:443/test/file.txt?question=answer#section")

-> ("http" "test.url" "user:pass" 443 "/test/file.txt" "question=answer" "section")
```

### Error: (req-get Url Headers Filename)

Mistakes happen, and we've added a facility to catch errors when they do occur. Simply `(catch 'InternalError` and do what you want with it.

```lisp
pil +

(load "https.l")

(symbols 'https)
(println
  (catch 'InternalError
    (req-get "https://test.url" NIL NIL) ) )

-> (HttpsError . "Could not resolve hostname `test.url': Host not found")
```

### (req-get Url Headers Filename)

In this example, we try to fetch from a URL that doesn't exist, and receive a response body stored in a temporary file, status code, headers, and other useful information.

```lisp
pil +

(load "https.l")

(symbols 'https)
(pretty
  (req-get
    "https://google.com/404"
    '(("Referer" . "http://test.url") ("User-Agent" . "picolisp-https-example"))
    T ) )

-> ((("Filename" . "/home/aw/.pil/tmp/2363/dl-7d702f36-1.tmp") ("Filesize" . 1428))
   ("Version" . "HTTP/1.1")
   ("Code" . 404)
   ("Message" . "Not Found")
   ("Url" . "https://google.com/404")
   ("Headers" ("date" . "Mon, 16 Mar 2015 10:50:07 GMT") ("content-length" . "1428") ("server" . "GFE/2.0") ("content-type" . "text/html; charset=UTF-8")) )
```

### (req-get Url Headers NIL)

Here we try to fetch from a URL which does exist, and receive the response body output.

```lisp
pil +

(load "https.l")

(symbols 'https)
(pretty
  (req-get "http://software-lab.de/donate.html" NIL) )

-> (("Body" . "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.0 Transitional//EN\" \"http://www.w3.org/TR/1998/REC-html40-19980424/loose.dtd\">^J<html lang=\"en\">^J<head>
^J<meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\">^J<title>Donate to PicoLisp</title>^J<link rel=\"stylesheet\" href=\"doc/doc.css\" type=\"t
ext/css\">^J</head>^J<body bgcolor=\"#F0F8FF\">^J^J<div style=\"margin-top: 60px; text-align: center;\">^J   <h2>Donate to <a href=\"http://home.picolisp.com\">Pico
Lisp</a></h2>^J^J   If you want to support the development and maintenance of PicoLisp,<br>^J   you can donate <a href=\"http://bitcoin.org\">Bitcoins</a> to the ad
dress<br>^J   <br>^J   <strong>18hPeB7sEtwMvRVrBMmwhJ3hkFzFda2QHN</strong><br>^J   <br>^J   Please send a note to<br>^J   <strong>btc&lt;at&gt;software-lab.de</stro
ng><br>^J   if you like your name to be mentioned.<br>^J   <br>^J   Thank you for your support!^J</div>^J^J<div style=\"margin-top: 60px; text-align: center;\">^J  
 <h3>Thanks to all Donors:</h3>^J   Jon Kleiser<br>^J   Heow Goodman<br>^J</div>^J^J</body>^J</html>^J")
   ("Version" . "HTTP/1.1")
   ("Code" . 200)
   ("Message" . "OK")
   ("Url" . "http://software-lab.de/donate.html")
   ("Headers"
      ("last-modified" . "Thu, 30 Oct 2014 12:25:01 GMT")
      ("date" . "Mon, 16 Mar 2015 10:56:37 GMT")
      ("keep-alive" . "timeout=3, max=100")
      ("content-length" . "1016")
      ("connection" . "Keep-Alive")
      ("accept-ranges" . "bytes")
      ("etag" . "\"757d8-3f8-506a2f824b149\"")
      ("server" . "Apache/2.2.29 (Unix)")
      ("content-type" . "text/html") ) )
```

### (req-head Url Headers)

An HTTP `HEAD` request never returns a body. You can see it in the result, the `Body` item has no `cdr`.

```lisp
pil +

(load "https.l")

(symbols 'https)
(pretty (req-head "http://software-lab.de/COPYING" NIL))

-> (("Body")
   ("Version" . "HTTP/1.1")
   ("Code" . 200)
   ("Message" . "OK")
   ("Url" . "http://software-lab.de/COPYING")
   ("Headers"
      ("last-modified" . "Mon, 16 Mar 2015 08:40:12 GMT")
      ("date" . "Mon, 16 Mar 2015 10:57:57 GMT")
      ("keep-alive" . "timeout=3, max=100")
      ("content-length" . "1078")
      ("connection" . "Keep-Alive")
      ("accept-ranges" . "bytes")
      ("etag" . "\"4ba06-436-51163cc69f4fd\"")
      ("server" . "Apache/2.2.29 (Unix)")
      ("content-type" . "text/plain") ) )
```

### (req-post Url Headers Filename Body)

Here we send an HTTP `POST` request with a JSON string (body), and receive the `ok` response body, along with some headers.

```lisp
pil +

(load "https.l")

(symbols 'https)
(pretty
  (req-post
    "http://requestb.in/10l0pw01"
    '(("Content-Type" . "application/json"))
    NIL
    "{\"Hello\":\"World\"}" ) )

-> (("Body" . "ok")
   ("Version" . "HTTP/1.1")
   ("Code" . 200)
   ("Message" . "OK")
   ("Url" . "http://requestb.in/10l0pw01")
   ("Headers"
      ("via" . "1.1 vegur")
      ("date" . "Mon, 16 Mar 2015 11:04:05 GMT")
      ("content-length" . "2")
      ("connection" . "keep-alive")
      ("server" . "gunicorn/18.0")
      ("sponsored-by" . "https://www.runscope.com")
      ("content-type" . "text/html; charset=utf-8") ) )
```

### (req-put) / (req-delete)

Pretty much the same as above.

### (req Method Url Headers Filename Body)

In this example, we send a request with a custom HTTP method.

```lisp
pil +

(load "https.l")

(symbols 'https)
(pretty (req "PICO" "https://encrypted.google.com/search?hl=en&q=recursion"))

-> (("Body" . "<!DOCTYPE html>^J<html lang=en>^J  <meta charset=utf-8>^J  <meta name=viewport content=\"initial-scale=1, minimum-scale=1, width=device-width\">^J  <tit
le>Error 405 (Method Not Allowed)!!1</title>^J  <style>^J    *{margin:0;padding:0}html,code{font:15px/22px arial,sans-serif}html{background:#fff;color:#222;padding:
15px}body{margin:7% auto 0;max-width:390px;min-height:180px;padding:30px 0 15px}* > body{background:url(//www.google.com/images/errors/robot.png) 100% 5px no-repeat
;padding-right:205px}p{margin:11px 0 22px;overflow:hidden}ins{color:#777;text-decoration:none}a img{border:0}@media screen and (max-width:772px){body{background:non
e;margin-top:0;max-width:none;padding-right:0}}#logo{background:url(//www.google.com/images/errors/logo_sm_2.png) no-repeat}@media only screen and (min-resolution:1
92dpi){#logo{background:url(//www.google.com/images/errors/logo_sm_2_hr.png) no-repeat 0% 0%/100% 100%;-moz-border-image:url(//www.google.com/images/errors/logo_sm_
2_hr.png) 0}}@media only screen and (-webkit-min-device-pixel-ratio:2){#logo{background:url(//www.google.com/images/errors/logo_sm_2_hr.png) no-repeat;-webkit-backg
round-size:100% 100%}}#logo{display:inline-block;height:55px;width:150px}^J  </style>^J  <a href=//www.google.com/><span id=logo aria-label=Google></span></a>^J  <p
><b>405.</b> <ins>Thatâs an error.</ins>^J  <p>The request method <code>PICO</code> is inappropriate for the URL <code>/search</code>.  <ins>Thatâs all we know.</in
s>^J")
   ("Version" . "HTTP/1.1")
   ("Code" . 405)
   ("Message" . "Method Not Allowed")
   ("Url" . "https://encrypted.google.com/search?hl=en&q=recursion")
   ("Headers" ("date" . "Mon, 16 Mar 2015 11:09:29 GMT") ("content-length" . "1459") ("alternate-protocol" . "443:quic,p=0.5") ("server" . "GFE/2.0") ("content-type
" . "text/html; charset=UTF-8")) )
```

# Testing

This library now comes with full [unit tests](https://github.com/aw/picolisp-unit). To run the tests, type:

    make check

# Alternatives

The following are alternatives written in pure PicoLisp. They are limited by pipe/read syscalls and shell exec commands.

* [HTTP request](http://rosettacode.org/wiki/HTTP#PicoLisp) on Rosetta Code.
* [HTTPS request](http://rosettacode.org/wiki/HTTPS#PicoLisp) on Rosetta Code.

# Contributing

If you find any bugs or issues, please [create an issue](https://github.com/aw/picolisp-https/issues/new).

If you want to improve this library, please make a pull-request.

# License

[MIT License](LICENSE)

Copyright (c) 2015 Alexander Williams, Unscramble <license@unscramble.jp>
