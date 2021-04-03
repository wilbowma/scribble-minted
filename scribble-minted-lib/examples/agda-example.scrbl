#lang scribble/manual

@require[scribble/minted]

@(current-pygmentize-default-style 'manni)

@title{Demo: Agda in Action}

This chapter contains a brief demonstration of Agda,
the language used in PLFA and in CS 747.
I won't be explaining everything in detail,
and you shouldn't expect to understand everything fully.
We'll go over everything more carefully later.

Interactions with Agda take place within the text editor Emacs,
using short keyboard sequences.
One sequence brings in the demonstration file
(@tt{demo.agda}, linked on the Handouts page;
we're using the starter version)
and another activates Agda,
checking syntax and providing highlighting.

The file starts with these lines:

@minted["agda"]|{
module demo where

open import Relation.Binary.PropositionalEquality
open import Data.Nat
}|

These lines start the module defined by the file,
and import library code for using equality and natural numbers.
These very basic notions are not built into Agda;
they are constructed, and later we will see how this is done.
