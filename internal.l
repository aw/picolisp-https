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

[de create-session (Fullurl)
  (let (Uri     (parse-uri Fullurl)
        Scheme  (car Uri)
        Host    (cadr Uri)
        Port    (get-port Scheme (; Uri 4))
        Session (ne-session-create Scheme Host Port)
        Path    (pack-path (; Uri 6) (; Uri 7)) )

    (when (= Scheme "https") (ne-ssl-trust-default-ca Session))

    (cons Session Path) ]

[de parse-uri (Fullurl)
  (let Result
    (ne-uri-parse Fullurl '(60 (S S S I I S S S I))) # *ne_uri URI structure (60 Bytes)
    (when (=0 (car Result)) (cadr Result)) ]

[de get-port (Scheme Port)
  (if (> Port 0)
      Port
      (ne-uri-defaultport Scheme) ]

[de pack-path (Path Query)
  (pack (ne-path-escape Path)
        "?"
        (ne-path-escape Query) ]

(de create-get-request (Session Path)
  (ne-request-create Session "GET" Path) )

[de set-headers (Headers Request)
  (mapcar
    '((L) (ne-add-request-header Request (car L) (cdr L)))
    Headers ]

[de request-dispatch (Request Session _readbody) # _readbody is function which processes a response body
  (unless
    (= *NE_OK (ne-begin-request Request))
    (exit-with-error Session) )

  (let (Body    (when (fun? _readbody) (_readbody))
        Result  (ne-end-request Request) )

    (cond ((= *NE_RETRY Result) (wait 1000) (request-dispatch Request Session _readbody))
          ((unless (= *NE_OK Result) (exit-with-error Session)))
          (T Body) ]

# returns NIL because we don't need the Fd
[de download-file () # Filename and Request will be closed-over
  (let Fd (open Filename)
    (ne-read-response-to-fd Request Fd)
    (close Fd)
    NIL ]

(de create-tmp-filename ()
  (tmp (pack "dl-" (random-id) ".tmp")) )

[de parse-response (Request Fullurl Filename)
  (let (Headers   (make (get-headers Request 0))
        Status    (struct (ne-get-status Request) '(I I I I S)) # *ne_status Status structure
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

[de get-headers (Request Cursor)
  (let ((Recursor Name Value) (ne-response-header-iterate Request Cursor '(N S) '(N S)))
    (when (> Recursor 0)
      (link (cons (car Name) (car Value)))
      (get-headers Request Recursor) ]

(de end-request-session (Request Session)
  (ne-request-destroy Request)
  (end-session Session) )

(de end-session (Session)
  (ne-close-connection Session)
  (ne-session-destroy Session) )

(de extract-header (Response Name)
  (cdr (assoc Name (cdr (assoc "Headers" Response)))) )
