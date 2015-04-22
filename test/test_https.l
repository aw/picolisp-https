(setq
  *My_tests_are_order_dependent NIL
  *Https_output (req-get "https://google.com/404" NIL T)
  *Donate_page  (req-get "http://software-lab.de/donate.html" NIL NIL)
  *404_page     (req-head "https://google.com/404") )

[de test-uriparse-success ()
  (unit~assert-equal  '("http" "test.url" "user:pass" 443 "/test/file.txt" "question=answer" "section")
                      (uriparse "http://user:pass@test.url:443/test/file.txt?question=answer#section")
                      "Successfully parse a valid URI" ]

[de test-uriparse-fail ()
  (unit~assert-throws 'InternalError
                      '(HttpsError . "Unable to parse URI")
                      '(uriparse "http://test.url/test/[test]")
                      "Fail to parse an invalid URI" ]

[de test-get-404 ()
  (unit~assert-includes '("Code" . 404)
                        *Https_output
                        "Returns a 404 error page from HTTPS request" ]

[de test-get-tempfile ()
  (unit~assert-includes '("Filename")
                        *Https_output
                        "Downloads the body into a temporary filename" ]

[de test-get-headers ()
  (unit~assert-kind-of  'List
                        (cdr (assoc "Headers" *Https_output))
                        "Returns a list of HTTP Headers" ]

[de test-get-body ()
  (unit~assert-includes '("Body")
                        *Donate_page
                        "Returns the body as a result (not a file) from HTTP request" ]

[de test-get-url ()
  (unit~assert-equal  '("Url" . "http://software-lab.de/donate.html")
                      (assoc "Url" *Donate_page)
                      "Returns the URL of the donate page 'http://software-lab.de/donate.html' for PicoLisp" ]

[de test-head-nobody ()
  (unit~assert-nil  (cdr (assoc "Body" *404_page))
                    "HEAD requests don't return a body" ]

[de test-head ()
  (unit~assert-includes '("Code" . 404)
                        *404_page
                        "HEAD requests work" ]

[de test-post ()
  (unit~assert-includes '("Body")
                        (req-post
                          "http://requestb.in/10l0pw01"
                          '(("Content-Type" . "application/json"))
                          NIL
                          "{\"Hello\":\"World\"}" )
                        "POST requests work" ]

[unit~execute
  '(test-uriparse-success)
  '(test-uriparse-fail)
  '(test-get-404)
  '(test-get-tempfile)
  '(test-get-headers)
  '(test-get-body)
  '(test-get-url)
  '(test-head-nobody)
  '(test-head)
  '(test-post) ]
