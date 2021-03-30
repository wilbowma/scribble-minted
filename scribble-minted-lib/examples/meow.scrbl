#lang scribble/manual

@(require scribble/minted)

@title{Ohh pretty}

Here's some Coq code in the default style
@minted["coq" #:options '((linenos . true))]{
Inductive Vec {A : Set} : nat -> Set :=
| nil : Vec 0
| cons : forall {n:nat}, A -> Vec n -> Vec (1 + n).
}

And in the colorful style
@minted["coq" #:options '((linenos . true) (style . colorful))]{
Inductive Vec {A : Set} : nat -> Set :=
| nil : Vec 0
| cons : forall {n:nat}, A -> Vec n -> Vec (1 + n).
}

This is a Coq expression @mintinline["coq"]{cons 0 nil}.


@; These aren't support in latex/pdf backend
@;Here's some Racket using the Scribbleesque style
@;@minted["racket" #:options '((style . scribbleesque))]{
@;(begin
@;  (let loop ([n 0])
@;    (displayln "Hello world")
@;    (loop (add1 n))))
@;}

@;with line numbers
@;@minted["racket" #:options '((linenos . true) (style . scribbleesque))]{
@;(begin
@;(let loop ([n 0])
@;(displayln "Hello world")
@;(loop (add1 n))))
@;}

A colorful Racket
@minted["racket" #:options '((style . colorful))]{
(begin
  (let loop ([n 0])
    (displayln "Hello world")
    (loop (add1 n))))
}

A @racket[racketblock] for comparison
@racketblock[
(begin
  (let loop ([n 0])
    (displayln "Hello world")
    (loop (add1 n))))
]
