#!/bin/sh
#
# Copyright (c) 2015 Alexander Williams, Unscramble <license@unscramble.jp>
# MIT License

set -u
set -e

git submodule init
git submodule update

cd vendor/neon
  ./autogen.sh
  ./configure --enable-shared --with-ssl=openssl --enable-threadsafe-ssl=posix
  make
cd -

cd lib
  rm -f libneon.so
  ln -s ../vendor/neon/src/.libs/libneon.so libneon.so
cd -
