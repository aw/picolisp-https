# internal.l
#
# The MIT License (MIT)
#
# Copyright (c) 2015 Alexander Williams, Unscramble <license@unscramble.jp>

[de throw-error (Session Message)
  (throw 'InternalError (cons 'HttpsError (if Session
                                              (ne-get-error Session)
                                              Message ]

[de random-id ()
  (lowc (hex (abs (rand) ]

[de create-session (Fullurl)
  (let (Uri     (parse-uri (escape-path Fullurl))
        Scheme  (car Uri)
        Host    (cadr Uri)
        Port    (get-port Scheme (; Uri 4))
        Session (ne-session-create Scheme Host Port)
        Path    (pack (; Uri 6) "?" (; Uri 7)) )

    (when (= Scheme "https") (ne-ssl-trust-default-ca Session))

    (cons Session Path) ]

[de create-session-request (Method Url Headers)
  (let ((Session . Path) (create-session Url)
        Request (ne-request-create Session Method Path) )

    (set-headers Headers Request)
    (list Session Path Request) ]

[de escape-path (Fullurl)
  (let Url (split (chop Fullurl) "/")
    (pack (car Url)
          "//"
          (caddr Url)
          "/"
          (split-pack-path Url) ]

[de parse-uri (Fullurl)
  (let Result
    (ne-uri-parse Fullurl '(60 (S S S I I S S S I))) # *ne_uri URI structure (60 Bytes)
    (when (=0 (car Result)) (cadr Result)) ]

[de get-port (Scheme Port)
  (if (> Port 0)
      Port
      (ne-uri-defaultport Scheme) ]

[de split-pack-path (Url)
  (let Path (split (chop (glue "/" (cdddr Url))) "?")
    (pack-path (pack (car Path)) (glue "?" (cdr Path))) ]

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

[de parse-response (Request Fullurl Output)
  (let (Headers   (make (get-headers Request 0))
        Status    (struct (ne-get-status Request) '(I I I I S)) # *ne_status Status structure
        Version   (pack "HTTP/" (car Status) "." (cadr Status))
        Code      (; Status 3)
        Message   (; Status 5) )

    (list Output
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

[de pack-body (Result)
  (pack (mapcar char (head (car Result) (cdr Result) ]

[de link-response-block (Request)
  (let Result (ne-read-response-block Request '(`*Buffer_size B . `*Buffer_size) *Buffer_size)
    (link (pack-body Result)) ]

(de random-filename ()
  (tmp (pack "dl-" (random-id) ".tmp")) )

# WARNING: variables rely on their context (dynamic scope)
# this could potentially be the source of many bugs, look here first ;)
[de begin-request ()
  (unless (= *NE_OK (ne-begin-request Request))
          (throw-error Session) ]

[de end-request ()
  (let Result (ne-end-request Request)
    (cond ((= *NE_RETRY Result) (wait 1000)
                                (request-dispatch Request Session _readbody) )
          ((unless  (= *NE_OK Result)
                    (throw-error Session) ]

[de download-file ()
  (let File (if (=T Filename)
                (random-filename)
                Filename )

    (let Fd (open File)
      (ne-read-response-to-fd Request Fd)
      (close Fd)
      (list (cons "Filename"  . File)
            (cons "Filesize"    (car (info File))) ]

[de process-body ()
  (let Body
    [make
      (while
        (> (car (link-response-block Request))
            0 ]

    (cons "Body" (pack Body)) ]
