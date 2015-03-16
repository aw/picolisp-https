# internal.l
#
# The MIT License (MIT)
#
# Copyright (c) 2015 Alexander Williams, Unscramble <license@unscramble.jp>

[de throw-error (Session Message)
  (throw 'InternalError (cons 'HttpsError (if Session
                                              (ne-get-error Session)
                                              Message ]

[de create-session-request (Method Url Headers)
  (let ((Session . Path) (create-session Url)
        Request (ne-request-create Session Method Path) )

    (set-headers Headers Request)
    (list Session Path Request) ]

[de create-session (Fullurl)
  (let (Uri     (parse-uri Fullurl)
        Scheme  (car Uri)
        Host    (cadr Uri)
        Auth    (; Uri 3)
        Port    (get-port Scheme (; Uri 4))
        Session (ne-session-create Scheme Host Port)
        Path    (pack (; Uri 5) (when (; Uri 6) (pack "?" (; Uri 6)))) )

    (set-auth-credentials Session Auth)

    (when (= Scheme "https") (ne-ssl-trust-default-ca Session))

    (cons Session Path) ]

[de parse-uri (Fullurl)
  (let Result
    (ne-uri-parse Fullurl '(56 (S S S N S S S))) # *ne_uri URI structure (56 Bytes)
    (if (=0 (car Result))
        (cadr Result)
        (throw-error NIL "Unable to parse URI") ]

[de get-port (Scheme Port)
  (if (> Port 0)
      Port
      (ne-uri-defaultport Scheme) ]

[de set-auth-credentials (Session Auth)
  [let Credentials (split (chop Auth) ":")
    (setq *User (pack (car Credentials))
          *Pass (pack (cdr Credentials)) ]

  (ne-set-server-auth
    Session
    (lisp 'ne_auth_creds '((A B C D E) (do-auth A B C D E)))
    0 ]

(de do-auth (Userdata Realm Attempt Username Password)
  (native "@" "strncpy" NIL Username *User *NE_ABUFSIZ)
  (native "@" "strncpy" NIL Password *Pass *NE_ABUFSIZ)
  Attempt )

[de del-auth-credentials (Session)
  (ne-forget-auth Session)
  (off *User)
  (off *Pass) ]

[de set-headers (Headers Request)
  (mapcar
    '((L) (ne-add-request-header Request (car L) (cdr L)))
    (append Headers *Headers) ]

[de set-request-body (Request Body)
  (when Body
    (let (Size (size Body)
          Buf (native "@" "malloc" 'N Size) )

      (native "@" "memset" NIL Buf Body Size)
      (let Buffer (native "@" "strncpy" 'N Buf Body Size)
        (ne-set-request-body-buffer Request Buffer Size)
        Buf ]

[de request-dispatch (Request Session)
  (use Body
    (loop
      (begin-request)

      (setq Body (if Filename
                    (download-file Request Filename)
                    (process-body Request) ) )

        (T (end-request) 'done) )
    Body ]

[de download-file (Request Filename)
  (let File (if (=T Filename)
                (random-filename)
                Filename )

    (let Fd (open File)
      (ne-read-response-to-fd Request Fd)
      (close Fd)
      (list (cons "Filename"  . File)
            (cons "Filesize"    (car (info File))) ]

(de random-filename ()
  (tmp (pack "dl-" (random-id) ".tmp")) )

[de random-id ()
  (lowc (hex (abs (rand) ]

[de process-body (Request)
  (let Body
    [make
      (while
        (> (car (link-response-block Request))
            0 ]

    (cons "Body" (pack Body)) ]

[de link-response-block (Request)
  (let Result (ne-read-response-block Request '(`*Buffer_size B . `*Buffer_size) *Buffer_size)
    (link (pack-body Result)) ]

[de pack-body (Result)
  (pack (mapcar char (head (car Result) (cdr Result) ]

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

(de end-request-session (Request Session Buffer)
  (when Buffer (native "@" "free" NIL Buffer))
  (ne-request-destroy Request)
  (del-auth-credentials Session)
  (end-session Session) )

(de end-session (Session)
  (ne-close-connection Session)
  (ne-session-destroy Session) )

# Request and Session rely on their context (dynamic scope)
# in case of bugs, look here first ;)
[de begin-request ()
  (unless (= *NE_OK (ne-begin-request Request))
          (throw-error Session) ]

[de end-request ()
  (let Result (ne-end-request Request)
    (cond ((= *NE_RETRY Result) (wait 1000) NIL)
          ((unless  (= *NE_OK Result)
                    (throw-error Session) ) )
          (T T) ]
