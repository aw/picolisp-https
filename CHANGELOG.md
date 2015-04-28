# Changelog

## 0.30.1.11 (2015-04-28)

  * Remove the need for git submodules
  * Add Makefile for fetching and building dependencies
  * Change default path for dependencies and shared module (.modules and .lib)
  * Adjust README.md, tests and travis-ci unit testing config

## 0.30.1.10 (2015-04-22)

  * Fix bug where downloading a file to an inexistant dir fails horribly

## 0.30.1.9 (2015-04-12)

  * Update picolisp-unit to v0.6.1

## 0.30.1.8 (2015-04-08)

  * Update picolisp-unit to v0.6.0
  * Add requires to module.l

## 0.30.1.7 (2015-03-31)

  * Update picolisp-unit to v0.5.2

## 0.30.1.6 (2015-03-24)

  * Add unit tests and automated testing with travis-ci
  * Move MODULE_INFO to module.l
  * Update README.md
  * Prevent leaky namespace globals
  * Add update.sh script

## 0.30.1.5 (2015-03-17)

  * Version bump because it's 3am. I should sleep.

## 0.30.1.4 (2015-03-17)

  * Add an incrementing counter to temporary filenames, to prevent collisions
  * Fix noop in (cons) pair
    (credit: Alexander Burger)

## 0.30.1.3 (2015-03-17)

  * Documentation updates

## 0.30.1.2 (2015-03-16)

  * Ensure the upload buffer (malloc) is free'd even if an error is thrown
