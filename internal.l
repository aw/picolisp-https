# internal.l
#
# The MIT License (MIT)
#
# Copyright (c) 2015 Alexander Williams, Unscramble <license@unscramble.jp>

(de exit-with-error (Session Message)
  (prinl "ERROR: "  (if Session
                        (ne-get-error Session)
                        Message ) )
  (bye 1) )

[de random-id ()
  (lowc (hex (abs (rand) ]

[de parse-uri (Fullurl)
  (let Result
    (ne-uri-parse Fullurl '(60 (S S S I I S S S I))) # parsed URI structure (60 Bytes)
    (if (=0 (car Result))
        (cadr Result)
        (exit-with-error NIL "Could not parse URI") ]

[de get-port (Scheme Port)
  (if (> Port 0)
      Port
      (ne-uri-defaultport Scheme) ]

[de pack-path (Path Query)
  (pack (ne-path-escape Path)
        "?"
        (ne-path-escape Query) ]

[de set-headers (Headers Request)
  (for L Headers
    (apply ne-add-request-header (list Request (car L) (cdr L))) ]

(de create-get-request (Session Path)
  (ne-ssl-trust-default-ca Session)
  (ne-request-create Session "GET" Path) )

[de request-dispatch (Request Session)
  (unless
    (= *NE_OK (ne-begin-request Request))
    (exit-with-error Session) )

  (let (Filename (download-file Request)
        Result (ne-end-request Request) )

    (cond ((= *NE_RETRY Result) (wait 1000) (request-dispatch Request Session))
          ((unless (= *NE_OK Result) (exit-with-error Session)))
          (T Filename) ]

[de download-file (Request)
  (let (Filename (pack "dl-" (random-id) ".tmp")
        Fd (open (tmp Filename)) )
    (ne-read-response-to-fd Request Fd)
    (close Fd)
    (pack (tmp) Filename) ]

[de get-headers (Request Cursor)
  (let ((Recursor Name Value) (ne-response-header-iterate Request Cursor '(N S) '(N S)))
    (when (> Recursor 0)
      (link (cons (car Name) (car Value)))
      (get-headers Request Recursor) ]

[de parse-response (Request Filename Fullurl)
  (let (Headers   (make (get-headers Request 0))
        Status    (struct (ne-get-status Request) '(I I I I S))
        Version   (pack "HTTP/" (car Status) "." (cadr Status))
        Code      (; Status 3)
        Message   (; Status 5)
        Filesize  (car (info Filename)) )

    (list (cons "Filename"  . Filename)
          (cons "Filesize"  . Filesize)
          (cons "Version"   . Version)
          (cons "Code"      . Code)
          (cons "Message"   . Message)
          (cons "Url"       . Fullurl)
          (cons "Headers"     Headers) ]

[de create-session (Fullurl)
  (let (Uri     (parse-uri Fullurl)
        Scheme  (car Uri)
        Host    (cadr Uri)
        Port    (get-port Scheme (; Uri 4))
        Session (ne-session-create Scheme Host Port)
        Path    (pack-path (; Uri 6) (; Uri 7)) )

    (cons Session Path) ]

(de end-session (Session)
  (ne-close-connection Session)
  (ne-session-destroy Session) )
