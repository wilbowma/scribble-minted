#lang info
(define collection 'multi)
(define deps '("rackunit-lib"
               "scribble-lib"
               "base"))
(define test-omit-paths '("scribble/minted.rkt"))
(define build-deps '())
(define pkg-desc "A package for typesetting code in Scribble via Pygmentize. Inspired by LaTeX's minted.")
(define version "0.4.1")
(define pkg-authors '(wilbowma))
