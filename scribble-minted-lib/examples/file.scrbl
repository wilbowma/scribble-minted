#lang scribble/manual
@(require scribble/minted racket)


@title{Ohh pretty}
@; Specify new default style
@(current-pygmentize-default-style 'colorful)

@; Or specify style as an option (not actually locally scoped, though)
@minted-file["coq" #:options '((linenos . true) (style . colorful) (firstline . 2) (lastline . 5))
"/tmp/test.v"
]


Take two:
@minted["coq" #:options '((linenos . true) (style . colorful) (firstline . 2) (lastline . 5))]{
Inductive Vec {A : Set} : nat -> Set :=
| nil : Vec 0
| cons : forall {n:nat}, A -> Vec n -> Vec (1 + n).
}

This is a Coq expression @mintinline["coq"]{cons 0 nil}.
