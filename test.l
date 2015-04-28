#!/usr/bin/env pil

(load ".modules/picolisp-unit/HEAD/unit.l")

(load "https.l")

(prinl "^J  Testing HTTP(S) client for PicoLisp^J")

(symbols 'https)

(chdir "test/"
  (mapcar load (filter '((N) (sub? "test_" N)) (dir "."))) )

(unit~report)
