# scribble/minted

A small Scribble library with support for rendering code using `pygmentize`.
This library hijacks Scribble to add a mixin to the `current-render-mixin`
that pre-processes certain elements using `pygmentize` to get pretty code
typesetting.
These elements can be added using the `minted` and `mintinline` commands from
this library.
This mixin supports the LaTeX, PDF, and HTML backends.

I have not thoroughly tested this.

## Example
```racket
(require scribble/minted)

@title{Ohh pretty}
@minted["coq"]{
Inductive Vec {A : Set} : nat -> Set :=
| nil : Vec 0
| cons : forall {n:nat}, A -> Vec n -> Vec (1 + n).
}

This is a Coq expression @mintinline["coq"]{cons 0 nil}.
```

## Install
`raco pkg install scribble-minted`
