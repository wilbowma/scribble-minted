#lang racket/base

(require
 (only-in rackunit require/expose)
 racket/runtime-path
 scribble/core
 scribble/latex-properties
 scribble/html-properties
 racket/function
 racket/system
 racket/port
 racket/list
 racket/string
 racket/class
 (only-in xml cdata))

(require/expose scribble/run (current-render-mixin))

(provide
 minted
 mintinline
 minted-render-mixin
 current-pygmentize-path)

(define-runtime-path minted-tex-path "minted.tex")
(define-runtime-path minted-css-path "minted.css")

;; These can only be used if the mixin is called after the parameters are set.

;; These are relative paths, not runtime paths
(define minted-tex-style-path "minted-style.tex")
(define minted-css-style-path "minted-style.css")

;; Default value #f means "try to find the path and error if not found".
(define current-pygmentize-path (make-parameter #f))

(define (system*-maybe bin . args)
  (let ([res (apply system*/exit-code bin args)])
    (if (not (zero? res))
        (error (format "Error running ~a, which returned the error code" bin) res)
        res)))

(define (minted-render-mixin %)
  (class %
    (super-new)

    (field
     (pygmentize-bin
      (or (current-pygmentize-path)
          (find-executable-path "pygmentize")
          (error "Could not find pygmentize in path; try setting current-pygmentize-path manually."))))

    (inherit/super current-render-mode)
    (inherit-field dest-dir style-extra-files)

    (define dir-prefix (or dest-dir "."))

    (define-values (pygmentize-format pygmentize-style-file-suffix pygmentize-outputer)
      (case (super current-render-mode)
        [((latex) (pdf))
         (values
          "latex"
          ".tex"
          (lambda (s x part ri)
            (printf
             ; TODO Should be handled by options to pygmentize
             (if (equal? (style-name s) "ScrbMintInline")
                 (string-replace x "Verbatim" "BVerbatim")
                 x))
            null))]
        [((html))
         (values
          "html"
          ".css"
          (lambda (s x part ri)
            (super
             render-content
             (element
              (make-style
               #f
               (list
                (xexpr-property
                 (cdata #f #f (if (equal? (style-name s) "ScrbMintInline")
                                  ; NB: Determined experimentally to fixup inline output.
                                  ; TODO: Some of these needs to be optional (string-normalize-spaces)
                                  ; Some of should be handled by options to pygmentize (removing <pre>)
                                  (for/fold ([x (string-normalize-spaces x)])
                                            ([replacer `(("<pre>" "")
                                                          ("</pre>" "")
                                                          ("highlight" "highlight-inline")
                                                          ("div" "code")
                                                          (" </code>" "</code>"))])
                                    (string-replace x (first replacer) (second replacer)))
                                  x))
                 (cdata #f #f ""))))
              "")
             part
             ri)))]
        [else (error "Not sure how to mint-ify the renderer for" (super current-render-mode))]))

    (set-field! style-extra-files this (cons (format "~a/minted-style~a" dir-prefix pygmentize-style-file-suffix) style-extra-files ))

    ;; setup style files in the dest-dir
    (define pygmentize-style-file (format "~a/minted-style~a" dir-prefix pygmentize-style-file-suffix))
    (unless (file-exists? pygmentize-style-file)
      (with-output-to-file pygmentize-style-file
        (thunk
         (system*-maybe pygmentize-bin "-S" "default" "-f" pygmentize-format))))

    (define/override (render-content i part ri)
      (if (and (element? i)
               (let ([s (element-style i)])
                 (and (style? s)
                      (or
                       (equal? (style-name s) "ScrbMintInline")
                       (equal? (style-name s) "ScrbMint")))))
          (pygmentize-outputer
           (element-style i)
           (with-output-to-string
             (thunk
              (with-input-from-string (apply string-append (element-content i))
                (thunk
                 (define options (cdr (assoc 'mt-options (style-properties (element-style i)))))
                 (apply
                  system*-maybe
                  pygmentize-bin
                  "-l"
                  (cdr (assoc 'lang (style-properties (element-style i))))
                  "-f"
                  pygmentize-format
                  (for/fold ([ls '()])
                            ([p options])
                    (list* "-O" (format "~a=~a" (car p) (cdr p)) ls)))))))
           part ri)
          (super render-content i part ri)))))

; NB: Relies on implementation details of scribble/run.rkt
; including order of evaluation, behavior of dynamic require
; In future, scribble will hopefully enable loading mixins automagically?
(let ([old (current-render-mixin)])
  (current-render-mixin (lambda (%) (minted-render-mixin (old %)))))

(define minted-style-props
  (list
   #;(make-css-addition minted-css-style-path)
   #;(make-tex-addition minted-tex-style-path)
   (make-css-addition minted-css-path)
   (make-tex-addition minted-tex-path)
   #;(attributes
    `((type . ,(format "text/minted"))
      (lang . ,lang)))
   #;(command-extras (list lang))))

(define (minted lang #:options [options '()] . code)
  (element
   (make-style "ScrbMint"
               (list* `(lang . ,lang) `(mt-options . ,options) minted-style-props))
   code))

(define (mintinline lang #:options [options '()] . code)
  (element
   (make-style "ScrbMintInline"
               (list* `(lang . ,lang) `(mt-options . ,options) minted-style-props))
   code))
