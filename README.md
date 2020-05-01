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

Put the following in `meow.scrbl`.
```racket
#lang scribble/base
@(require scribble/minted)

@title{Ohh pretty}
@; Specify new default style
@(current-pygmentize-default-style 'colorful)

@; Or specify style as an option (not actually locally scoped, though)
@minted["coq" #:options '((linenos . true) (style . colorful)]{
Inductive Vec {A : Set} : nat -> Set :=
| nil : Vec 0
| cons : forall {n:nat}, A -> Vec n -> Vec (1 + n).
}

This is a Coq expression @mintinline["coq"]{cons 0 nil}.
```

Run `scribble`, with multiple backends.

`scribble --pdf meow.scrbl`
`scribble --html meow.scrbl`

See pretty code!

## Install
`raco pkg install scribble-minted`

You must have `pygmentize` installed and in your `PATH`.


## NB
Note that the `style` option affects the style of everything typeset in the
page due to limitations in Pygmentize.
I'll eventually work around this to make it scoped to `@minted` call, allowing
multiple styles in the same document.
I recommend you avoid it and just use `current-pygmentize-default-style` for
now.
