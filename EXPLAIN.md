# Explanation: HTTP(S) client for PicoLisp

This document provides a short walkthrough of the source code for the [PicoLisp-HTTPS](https://github.com/aw/picolisp-https.git) client.

I won't cover concepts which were covered in previous source code explanations. You can read them here:

* [Nanomsg Explanation](https://github.com/aw/picolisp-nanomsg/blob/master/EXPLAIN.md)
* [JSON Explanation](https://github.com/aw/picolisp-json/blob/master/EXPLAIN.md)

This document is split into a few sections:

1. [Loading and initialization](#loading-and-initialization): Loading files and performing initial work.
2. [Error handling](#error-handling): An idiom for handling errors.
3. [Internal functions](#internal-functions): Destructuring, native C callbacks, and memory management.
  * [making HTTPS requests](#making-https-requests)
  * [parsing HTTPS responses](#parsing-https-responses)
  * [cleaning up errors](#cleaning-up-errors)

Make sure you read the [README](README.md) to get an idea of what this library does.

# Loading and initialization

We've made some changes to how we load files across all libraries.

### Loading

[PicoLisp](http://picolisp.com) loads files from the _current working directory_ [pwd](http://software-lab.de/doc/refP.html#pwd), which is in relation to where you ran the command:

```lisp
alex@dev-box:~/picolisp-https$ pil +
: (pwd)
-> "/home/aw/picolisp-https"
```

So far so good, but what happens when the file you load also loads a file in a different directory? Depending if the path is relative or absolute, you will not necessarily get what you want.

To fix this, we use [file](http://software-lab.de/doc/refF.html#file):

```lisp
*Https              (pack (car (file)) "lib/libneon.so")
```
```

What this does is load the file `lib/libneon.so` relative to the file that's loading it. 

We use this technique further down as well:

```lisp
# ffi-bindings
(load (pack (car (file)) "ffi.l"))

# internal
(load (pack (car (file)) "internal.l"))
```

Perhaps there should be a `(cwd)` primitive for that? ;)

### Initialization

There is a concept of `constructors` in PicoLisp, but it's only used with classes and objects. We're trying to be functional here.

Our approach is simple: perform initialization tasks after loading all the necessary files.

```lisp
(when (=0 (ne-has-support *NE_FEATURE_SSL))
      (throw-error NIL "Missing support for SSL/TLS") )
```

What we've done here is try to ensure `SSL` is compiled into the shared library. If it's not, an error is thrown. [Error handling](#error-handling) is explained in the next section.

We also ensure to [seed](http://software-lab.de/doc/refS.html#seed) some random data from the system's PRNG:

```lisp
(seed (in "/dev/urandom" (rd 20)))
```

This tries to obtain `20 bytes` from `/dev/urandom` using [rd](http://software-lab.de/doc/refR.html#rd), a function for reading raw bytes from an input stream, and initializes the seed with it.

# Error handling

PicoLisp provides us with a few ways to handle errors, so why not use them to our advantage?

My idea was:

1. Throw errors in the library, but don't quit/exit disgracefully (a.k.a. be nice).
2. Provide a _type_ of error, and a brief message explaining what happened.
3. Allow the user to catch the errors outside the library.

```lisp
[de throw-error (Session Message)
  (throw 'InternalError (cons 'HttpsError (if Session
                                              (ne-get-error Session)
                                              Message ]
```

The **Neon C library** has a function (`ne-get-error`) which returns a string containing an error message (if any). Sometimes, we want to provide our own error message though.

In the `(throw-error)` function, we satisfy the first two requirements by using [throw](http://software-lab.de/doc/refT.html#throw) to send an `'InternalError`, along with a [cons](http://software-lab.de/doc/refC.html#cons) pair containing the `'HttpsError` _type_ in the [car](http://software-lab.de/doc/refC.html#car) and the error _message_ in the [cdr](http://software-lab.de/doc/refC.html#cdr).

The third requirement is satisfied in user applications with something like this:

```lisp
(println (catch 'InternalError
  .. ) )

-> (HttpsError . "Could not connect to server: Connection timed out")
```

# Internal functions

As usual, the bulk of the library occurs in the internal functions.

## making HTTPS requests

PicoLisp 64-bit got a new feature in 2015: `destructuring 'let'`.

If you're coming from other languages such as Ruby, you would destructure an array like this:

```ruby
var1, var2 = ["one", "two"]
```

In PicoLisp, we use this to obtain a Session (pointer) and Path (string), which is a cons pair returned by the `(create-session)` function.

```lisp
[de create-session-request (Method Url Headers)
  (let ((Session . Path) (create-session Url)
        Request (ne-request-create Session Method Path) )

    (set-headers Headers Request)
    (list Session Path Request) ]
```

### (create-session)

In `(create-session)`, we parse the Url and obtain all the separate components, which are returned to us in a simple list. We're already familiar with `(car)`, `(cdr)`, `(cddr)`, etc, but there's another primitive to get the exact item in a list: it's the dreaded [semicolon (;)](http://software-lab.de/doc/ref_.html#;) _(insert JavaScript joke here)_

```lisp
[de create-session (Fullurl)
  (let (Uri     (parse-uri Fullurl)
        Scheme  (car Uri)
        Host    (cadr Uri)
        Auth    (; Uri 3)
        Port    (get-port Scheme (; Uri 4))
        Session (ne-session-create Scheme Host Port)
        Path    (pack (; Uri 5) (when (; Uri 6) (pack "?" (; Uri 6)))) )
..
```

Notice we use `(; Uri 3)`. This is cool, it'll get the item in the 3rd position in the list. In this case, it's the auth credentials (usually user:password).

The semicolon has other uses as well, so make sure you read about it.

### (set-auth-credentials)

This function does two things, one is dangerous, the other is cool.

```lisp
[de set-auth-credentials (Session Auth)
  [let Credentials (split (chop Auth) ":")
    (setq *User (pack (car Credentials))
          *Pass (pack (cdr Credentials)) ]

  (ne-set-server-auth
    Session
    (lisp 'ne_auth_creds '((A B C D E) (do-auth A B C D E)))
    0 ]
```

Let's talk about danger first. In this function, we uses [setq](http://software-lab.de/doc/refS.html#setq) to create some _temporary_ global variables. I say temporary because we get rid of them later. The danger here is this is **NOT functional**. It's a side-effect which could be the source of bugs in the future. OOP lovers don't care about this kind of stuff, but in FP land it's a big no-no.

> **Note:** The reason we do this is because of the `(do-auth)` function, which we'll explain later.

The [lisp](http://software-lab.de/doc/refL.html#lisp) function is quite special. When using `(native)` for C calls, certain functions require a callback as an argument, or "function pointer" (Google it).

The `(ne-set-server-auth)` function requires a callback as its second argument, so we create one using `(lisp)`. If you've read the [JSON explanations](https://github.com/aw/picolisp-json/blob/master/EXPLAIN.md#make-array), you'll quickly notice there's an anonymous function in this `(lisp)` call. It essentially sends 5 arguments (which are numbers) to the `(do-auth)` function, under the name `ne_auth_creds`.

Here's the C code to give a better picture:

```C
typedef int (*ne_auth_creds)(void *userdata, const char *realm, int attempt,
			     char *username, char *password);

void ne_set_server_auth(ne_session *sess, ne_auth_creds creds, void *userdata);
```

See that? All arguments for `ne_auth_creds` are numbers (void, pointers, int)..

### (do-auth)

This function is our actual callback function. It's the one that will be called from the C library.

The main requirement is to set the `username`, `password`, and return an integer. We do that here:

```lisp
(de do-auth (Userdata Realm Attempt Username Password)
  (native "@" "strncpy" NIL Username *User *NE_ABUFSIZ)
  (native "@" "strncpy" NIL Password *Pass *NE_ABUFSIZ)
  Attempt )
```

Whoa wait, what's that `@` thing doing there? Remember we talked about the [@ result](https://github.com/aw/picolisp-nanomsg/blob/master/EXPLAIN.md#nn_symbols)? Well, this is **NOT** that.

This is actually a [transient symbol](http://software-lab.de/doc/native.html#libs) which refers to the main program (PicoLisp).

> **Note:** In english, this means you can call standard C functions like `malloc` and `strcpy` (j/k, at least use strncpy).

This function uses the `*User and *Pass` global variables we defined earlier and the C `strncpy()` functions to copy the global variables into the `Username` and `Password` _pointers_. The other approach would be to hardcode the username/password in the function, but really.. who does that?

At the end of `(do-auth)`, we return the `Attempt` variable, which based on the **Neon** documentation, would only perform _one_ authentication attempt before failing.

### (del-auth-credentials)

Of course, we need to remove the auth credentials once we're done with them. The `(ne-forget-auth)` function will remove them from memory, and [off](http://software-lab.de/doc/refO.html#off) will set the global variables to `NIL`.

```lisp
[de del-auth-credentials (Session)
  (ne-forget-auth Session)
  (off *User)
  (off *Pass) ]
```

> **Note:** We could have also done: `(off *User *Pass)`.

### (set-headers)

There's nothing magical in this function, just the usual mapping over a list with an **anonymous function**.

```lisp
[de set-headers (Headers Request)
  (mapcar
    '((L) (ne-add-request-header Request (car L) (cdr L)))
    (append Headers *Headers) ]
```

I want to highlight [append](http://software-lab.de/doc/refA.html#append) which can be used to _append_ a list to another. Who would have known?

The tricky thing is there's an order to it. We want the `Headers` variable to be used before the `*Headers` global variable. This way if you specify your own `User-Agent`, then it'll use that instead of the default.

There were other ways to do this, but I just wanted to use `(append)`.

### (set-request-body)

Now here's some more dangerous code if you haven't seen it yet. This function is used to set the request Body (ex: in a `POST` or `PUT` request) in a manually allocated buffer.

The reason for this is due to an _interesting_ coding choice used in the **Neon** C library. It doesn't copy the body in memory for you, so at the end of a `(native)` call, the body (memory) is free'd and **Neon** can't use it anymore (because PicoLisp automatically frees memory).

```lisp
[de set-request-body (Request Body)
  (when Body
    (let (Size (size Body)
          Buf (native "@" "malloc" 'N Size) )

      (native "@" "memset" NIL Buf Body Size)
      (let Buffer (native "@" "strncpy" 'N Buf Body Size)
        (ne-set-request-body-buffer Request Buffer Size)
        Buf ]
```

We'll first obtain the [size](http://software-lab.de/doc/refS.html#size) of the request body. We do this for safety, and because it makes us feel warm inside.

Since **Neon** is a bit strange, we're forced to manually allocate a buffer for the request body. You can see lots of funky C stuff in there.

In the end though, we're able to send a perfectly good request body (`Buffer`) in our HTTP(S) request.

Some sharp eyes may notice we don't `free` the allocated memory here. _evil laugh_. Don't worry, we've actually handled this elegantly, which you can read about in [cleaning up errors](#cleaning-up-errors).

## Parsing HTTPS responses

Here we cover the function which dispatches a request, and then processes the response.

### (request-dispatch)

The **Neon** C library provides a function to dispatch HTTP(S) requests, except for some odd reason it discards the response body before you can do anything with it. How horrible.

```lisp
[de request-dispatch (Request Session)
  (use Body
    (loop
      (begin-request)

      (setq Body (if Filename
                    (download-file Request Filename)
                    (process-body Request) ) )

        (T (end-request) 'done) )
    Body ]
```

In this function, we've got an infinite [loop](http://software-lab.de/doc/refL.html#loop) which tries to make a request, save the **response body** to a file or whatever, and exits the loop when all is good.

The `(end-request)` function implements a _retry_ mechanism, and returns either `T` or `NIL` (or throws an error). If the result is `T`, we execute `'done`, which is nothing really, and returns the response body. Otherwise it loops.

There's something _very_ different in this function though. Do you see it?

The `Filename` variable is not sent as an argument to the function. So, how does it work? If you look at the `(req)` function in `https.l`, you'll see the filename is (optionally) set as an argument. Our `(request-dispatch)` function uses the `Filename` variable from there.

This is called `dynamic scoping`, one of the great advantages of PicoLisp. You can do stuff like that.

> **Mr. Burger's Note:** As much as this is an advantage, it's also a sword hanging over your head. Use wisely.

### (download-file)

This is a cool function. It checks if the `Filename` is set to `T`. If yes, then it generates a `(random-filename)`, otherwise it uses the filename provided.

```lisp
[de download-file (Request Filename)
  (let File (if (=T Filename)
                (random-filename)
                Filename )

    (let Fd (open File)
      (ne-read-response-to-fd Request Fd)
      (close Fd)
      (list (cons "Filename"  . File)
            (cons "Filesize"    (car (info File))) ]
```

We use [open](http://software-lab.de/doc/refO.html#open) and [close](http://software-lab.de/doc/refC.html#close) when working with file descriptors. The `(ne-read-response-to-d)` function is designed to write to the response body to a file descriptor. How convenient.

Finally, we return a list with two cons pairs, one containing the Filename (potentially randomly generated) and the other containing the Filesize, which is captured using the [info](http://software-lab.de/doc/refI.html#info) function.

### random stuff

Earlier, we looked at seeding random data, why? Well here's why:

```lisp
(de random-filename ()
  (tmp (pack "dl-" (random-id) ".tmp")) )

[de random-id ()
  (lowc (hex (abs (rand) ]
```

The `(random-filename)` function generates a string that looks like this: `dl-7d702f36.tmp`.

It uses [tmp](http://software-lab.de/doc/refT.html#tmp) to obtain the PicoLisp processes's temp directory, and the `(random-id)` function to generate a random id.

Some cool functional stuff here: [lowc](http://software-lab.de/doc/refL.html#lowc) is used to lowercase a string, [hex](http://software-lab.de/doc/refH.html#hex) to generate a hexadecimal string, [abs](http://software-lab.de/doc/refA.html#abs) to return the absolute value of [rand](http://software-lab.de/doc/refR.html#rand) which returns a random integer (which should truly be random thanks to our [seed initialization](#initialization) from earlier).

### (process-body)

This doesn't do anything we haven't seen before. It uses the familiar `(make)`, `(link)`, and `(pack)` to generate a list.

In fact, the `(ne-read-response-block)` function is set to only read a specific `*Buffer_size` _(8192 bytes)_ of data at a time. We have a simple loop in `(process-body)` to obtain the full body and then pack it all together.

### (parse-response)

Without going into too much detail for `(parse-response)`, I want to discuss something we haven't seen yet: [struct](http://software-lab.de/doc/refS.html#struct).

```lisp
..
(struct (ne-get-status Request) '(I I I I S)) # *ne_status Status structure
..
```

The `(struct)` function can be used to _extract_ a C structure. The first argument is the structure, in our case it's the result of `(ne-get-status)`, and the structure contains 4 integers and 1 string.

The C code for this:

```C
typedef struct {
    int major_version;
    int minor_version;
    int code; /* Status-Code value */
    int klass; /* Class of Status-Code (1-5) */
    char *reason_phrase;
} ne_status;
```

We return those in the response for each request. Actually we don't return `klass` because who cares.

### Skipping ahead: (end-request-session)

When we're done with our request/response, it's time to clean up. We've got a nice function for that:

```
(de end-request-session (Request Session Buffer)
  (when Buffer (native "@" "free" NIL Buffer))
  (ne-request-destroy Request)
  (del-auth-credentials Session)
  (end-session Session) )
```

This free's the `Buffer` we allocated earlier using `malloc`.

The real question is: when is this called? Let's get to that right now.

## Cleaning up errors

Earlier, we discussed the ability to `(throw)` and error, and that's nice when something is there to catch it. But, what happens when that _thing_ doesn't know about the internals? Does it to know cleanly end the request, end the session, free up manually allocated buffers?

Nope.

Our solution happens at the highest level in the most important function: `(req)`.

### (req)

This is our public function which does it all.

```lisp
..
(let Buffer (set-request-body Request Body)
  (finally
    (end-request-session Request Session Buffer)
    (let Output (request-dispatch Request Session)
      (parse-response Request Url Output) ]
```

The first thing we do is obtain the request `Buffer` (which may possibly be empty). Next, we have this very useful [finally](http://software-lab.de/doc/refF.html#finally) call. That's our safety net. The first argument is the "thing you do if an error is throw, or when you're done processing". The second argument is the "processing" part.

In other words, if a `(throw)` is called in our code, it will execute `(end-request-session)` which cleans memory and keeps things sane. Otherwise, it runs the `(request-dispatch)` and `(parse-response)`, then (finally) it runs `(end-request-session)` before returning the response from `(parse-response)`.

Isn't that amazing? Sasuga PicoLisp.

# The end

That's pretty much all I have to explain about the HTTP(S) client for PicoLisp FFI bindings. I'm very open to providing more details about functionality I've skipped, so just file an [issue](https://github.com/aw/picolisp-https/issues/new) and I'll do my best.

# License

This work is licensed under a [Creative Commons Attribution-ShareAlike 4.0 International License](http://creativecommons.org/licenses/by-sa/4.0/).

Copyright (c) 2015 Alexander Williams, Unscramble <license@unscramble.jp>
