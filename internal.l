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

[de create-session-request (Method Url Headers)
  (let ((Session . Path) (create-session Url)
        Request (ne-request-create Session Method Path) )

    (set-headers Headers Request)
    (list Session Path Request) ]

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

[de set-headers (Headers Request)
  (mapcar
    '((L) (ne-add-request-header Request (car L) (cdr L)))
    Headers ]

[de request-dispatch (Request Session _readbody) # _readbody is function which processes a response body
  (begin-request)

  (let Body (when (fun? _readbody) (_readbody))
    (end-request)
    Body ]

[de process-body ()
  (cons "Body" . "noop") ]

[de parse-response (Request Fullurl Output)
  (let (Headers   (make (get-headers Request 0))
        Status    (struct (ne-get-status Request) '(I I I I S)) # *ne_status Status structure
        Version   (pack "HTTP/" (car Status) "." (cadr Status))
        Code      (; Status 3)
        Message   (; Status 5)
        Result    (if (lst? Output)
                      Output
                      (list (cons "Filename"  . Output)
                            (cons "Filesize"    (car (info Output))) ) ) )

    (list Result
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

# WARNING: closures, variables rely on their context
# this could potentially be the source of many bugs, look here first ;)
[de begin-request () # closed-over: Request, Session
  (unless (= *NE_OK (ne-begin-request Request))
          (exit-with-error Session) ]

[de end-request () # closed-over: Request, Session, _readbody
  (let Result (ne-end-request Request)
    (cond ((= *NE_RETRY Result) (wait 1000)
                                (request-dispatch Request Session _readbody) )
          ((unless  (= *NE_OK Result)
                    (exit-with-error Session) ]

[de download-file () # closed-over: Filename, Request
  (let Fd (open Filename)
    (ne-read-response-to-fd Request Fd)
    (close Fd)
    Filename ]
