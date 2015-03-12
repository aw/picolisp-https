(symbols 'https 'pico)

[setq MODULE_INFO
  '(("name"       "https")
    ("version"    "0.30.1.0")
    ("summary"    "HTTPS (Neon) ffi-bindings for PicoLisp")
    ("source"     "https://github.com/aw/picolisp-https.git")
    ("author"     "Alexander Williams")
    ("license"    "MIT")
    ("copyright"  "(c) 2015 Alexander Williams, Unscramble <license@unscramble.jp>")
    ("install"    "build.sh") ]

(setq
  *Https             "lib/libneon.so"
  *Buffer_size       8192
  *Headers           '(("Accept" . "*/*") ("User-Agent" . "picolisp-https") ("Accept-Charset" . "utf-8"))

  *NE_FEATURE_SSL    1
  *NE_FEATURE_ZLIB   2
  *NE_FEATURE_IPV6   3
  *NE_FEATURE_LFS    4
  *NE_FEATURE_SOCKS  5
  *NE_FEATURE_TS_SSL 6
  *NE_FEATURE_I18N   7
  *NE_FEATURE_SSPI   8

  *NE_OK             0
  *NE_ERROR          1
  *NE_LOOKUP         2
  *NE_AUTH           3
  *NE_PROXYAUTH      4
  *NE_CONNECT        5
  *NE_TIMEOUT        6
  *NE_FAILED         7
  *NE_RETRY          8
  *NE_REDIRECT       9 )

# ffi-bindings
(load "ffi.l")

# internal
(load "internal.l")

# initialize
(when (=0 (ne-has-support *NE_FEATURE_SSL))
      (throw-error NIL "Missing support for SSL/TLS") )

(when (=0 (ne-has-support *NE_FEATURE_TS_SSL))
      (throw-error NIL "Missing support for thread-safe SSL") )

(unless (= *NE_OK (ne-sock-init))
        (throw-error NIL "Could not initiate socket") )

(seed (in "/dev/urandom" (rd 20)))


# public
(de req-head (Url Headers)
  (req  "HEAD" Url Headers) )

[de req-get (Url Headers Filename)
  (req  "GET"
        Url
        Headers
        (if (=T Filename)
            (random-filename)
            Filename ) ]

[de req (Method Url Headers Filename)
  (let ((Session Path Request) (create-session-request Method Url Headers))
    (let (Output (if  Filename
                      (request-dispatch Request Session download-file)
                      (request-dispatch Request Session process-body) )
          Response (parse-response Request Url Output) )

      (end-request-session Request Session)
      Response ]
