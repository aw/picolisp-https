# ffi.l
#
# The MIT License (MIT)
#
# Copyright (c) 2015 Alexander Williams, Unscramble <license@unscramble.jp>

(de ne-sock-init ()
  (native `*Https "ne_sock_init" 'I) )

(de ne-version-string ()
  (native `*Https "ne_version_string" 'S) )

(de ne-has-support (Feature)
  (native `*Https "ne_has_support" 'I Feature) )

(de ne-get-error (Session)
  (native `*Https "ne_get_error" 'S Session) )

# returns the result in 'car', parsed URI in 'cdr'
[de ne-uri-parse (Uri &ne_uri)
  (use Parsed
    (cons
      (native `*Https "ne_uri_parse" 'I Uri (list 'Parsed &ne_uri))
      Parsed ]

(de ne-uri-defaultport (Scheme)
  (native `*Https "ne_uri_defaultport" 'I Scheme) )

(de ne-add-request-header (Request Name Value)
  (native `*Https "ne_add_request_header" NIL Request Name Value) )

(de ne-path-escape (Path)
  (native `*Https "ne_path_escape" 'S Path) )

(de ne-session-create (Scheme Hostname Port)
  (native `*Https "ne_session_create" 'N Scheme Hostname Port) )

(de ne-ssl-trust-default-ca (Session)
  (native `*Https "ne_ssl_trust_default_ca" NIL Session) )

(de ne-request-create (Session Method Path)
  (native `*Https "ne_request_create" 'N Session Method Path) )

(de ne-begin-request (Request)
  (native `*Https "ne_begin_request" 'I Request) )

(de ne-end-request (Request)
  (native `*Https "ne_end_request" 'I Request) )

(de ne-read-response-to-fd (Request Fd)
  (native `*Https "ne_read_response_to_fd" 'I Request Fd) )

(de ne-request-destroy (Request)
  (native `*Https "ne_request_destroy" NIL Request) )

(de ne-close-connection (Session)
  (native `*Https "ne_close_connection" NIL Session) )

(de ne-session-destroy (Session)
  (native `*Https "ne_session_destroy" NIL Session) )

(de ne-get-status (Request)
  (native `*Https "ne_get_status" 'N Request) )

[de ne-response-header-iterate (Request Cursor &name &value)
  (use (Name Value)
    (list
      (native `*Https "ne_response_header_iterate" 'N
                                                   Request
                                                   Cursor
                                                   (cons 'Name &name 0)
                                                   (cons 'Value &value 0) )
      Name
      Value ]
