# Regression tests

# Download files fails - https://github.com/aw/picolisp-https/issues/5
[de test-gh-issue-5 ()
  (unit~assert-throws
      'InternalError
      '(HttpsError . "Unable to write to file: /dev/non-existant-file")
      '(download-file NIL "/dev/non-existant-file")
      "Regression test GH issue #5 - download file fails" ]

[unit~execute
  '(test-gh-issue-5) ]
