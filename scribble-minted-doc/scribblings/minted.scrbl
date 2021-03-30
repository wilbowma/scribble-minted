#lang scribble/manual

@(require
  scribble/minted
  (for-label
   scribble/core
   scribble/decode
   scribble/minted
   racket/base
   racket/dict
   racket/contract))

@title{Minted for Scribble}
@author[
@author+email["William J. Bowman" "wjb@williamjbowman.com"]
]
@defmodule[scribble/minted]

This package provides an interface to Pygmentize for typesetting code.
It relies on @tt{pygmentize} as an external dependency, which must be the path
while @tt{scribble} is being run.

@defproc[(minted [lang string?]
                 [#:options options dict? '()]
                 [exprs pre-flow?] ...)
         block?]{
Typesets @racket[exprs] as a block using @tt{pygmentize}.
Uses the lexer @racket[lang] for typesetting, and passes @racket[options] using
@tt{-O} to control various typesetting options.

For example,
@verbatim|{
@minted["racket"]{
(begin
  (let fact ([n 5])
    (if (zero? n)
        1
        (* n (fact (sub1 n))))))
}
}|

produces the output:
@minted["racket"]{
(begin
  (let fact ([n 5])
    (if (zero? n)
        1
        (* n (fact (sub1 n))))))
}

Other options, such as @tt{linenos} and @tt{style}, can be used to alter the
output. See @tt{pygmentize} documentation for more details.

For example,
@verbatim|{
@minted["racket"
#:options '((linenos . true)
            (style . colorful))]{
(begin
  (let fact ([n 5])
    (if (zero? n)
        1
        (* n (fact (sub1 n))))))
}
}|

produces the output:
@minted["racket"
#:options '((linenos . true)
            (style . colorful))]{
(begin
  (let fact ([n 5])
    (if (zero? n)
        1
        (* n (fact (sub1 n))))))
}

Example:
@verbatim|{
@minted["coq" #:options '((linenos . true))]{
Inductive Vec {A : Set} : nat -> Set :=
| nil : Vec 0
| cons : forall {n:nat}, A -> Vec n -> Vec (1 + n).
}
}|

produces the output:

@minted["coq" #:options '((linenos . true))]{
Inductive Vec {A : Set} : nat -> Set :=
| nil : Vec 0
| cons : forall {n:nat}, A -> Vec n -> Vec (1 + n).
}
}

@defproc[(mintinline [lang string?]
                     [#:options options dict? '()]
                     [exprs pre-flow?] ...)
         element?]{
Typesets @racket[exprs] as an inline element using @tt{pygmentize}.
Options are the same as for @racket[minted].

Examples:

@tt|{@mintinline["coq"]{cons 0 nil}}|

produces @mintinline["coq"]{cons 0 nil}.

@tt|{@mintinline["javascript" #:options '((style .
solarized-light))]{function(x){return x;}}.}|

produces @mintinline["javascript" #:options '((style . solarized-light))]{function(x){return x;}}.
}
