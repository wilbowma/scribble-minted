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
