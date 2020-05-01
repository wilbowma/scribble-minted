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
 current-pygmentize-path
 current-pygmentize-default-style)

(define-runtime-path minted-tex-path "minted.tex")
(define-runtime-path minted-css-path "minted.css")

;; Default value #f means "try to find the path and error if not found".
(define current-pygmentize-path (make-parameter #f))

(define current-pygmentize-default-style (make-parameter 'default))

(define (system*-maybe bin . args)
  (let ([res (apply system*/exit-code bin args)])
    (if (not (zero? res))
        (error (format "Error running ~a, which returned the error code" bin) res)
        res)))

(define (maybe-assoc key als)
  (findf (lambda (x)
           (and (pair? x) (equal? (car x) key)))
         als))

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
            (printf x)
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
                                  ;; NB: Inline is not wrapped from pygments to avoid extra paragraphs.
                                  ;; Instead, wrap it code manually.
                                  ;; Would prefer to use <pre>, but this seems
                                  ;; to prevent Scribble from folding it into the previous paragraph.
                                  ;; Instead, highlight-inline asks CSS to do white-space: pre.
                                  ;; Not sure how compatible this is with older browsers
                                  (format "<code class=\"highlight-inline\">~a</code>"
                                          ;; Remove trailing <br /> for inline
                                          (string-trim x "<br />" #:left? #f))
                                  x))
                 (cdata #f #f ""))))
              "")
             part
             ri)))]
        [else (error "Not sure how to mint-ify the renderer for" (super current-render-mode))]))

    ; NOTE: Has support for multiple styles in a single document, but pygmentize
    ; doesn't support this natively as it reuses names.
    ; Could manually rewrite the generate CSS to add some kind of scopeing using
    ; spans, e.g., by prefixing each of the generated classes, and adding the
    ; prefix to the generated span/div.
    ; This only works for html output, though.
    (define/override (traverse-content i fp)
      (when (and (element? i)
                 (let ([s (element-style i)])
                   (and (style? s)
                        (or
                         (equal? (style-name s) "ScrbMintInline")
                         (equal? (style-name s) "ScrbMint")))))
        (let* ([options (cdr (maybe-assoc 'mt-options (style-properties (element-style i))))]
               [style (cond
                        [(maybe-assoc 'style options) => cdr]
                        [else (current-pygmentize-default-style)])]
               [pygmentize-style-file
                (format "~a/minted-~a-style~a"
                        dir-prefix
                        style
                        pygmentize-style-file-suffix)])
          (set-field! style-extra-files this
                      (cons pygmentize-style-file style-extra-files))
          ;; setup style files in the dest-dir
          (unless (file-exists? pygmentize-style-file)
            (with-output-to-file pygmentize-style-file
              (thunk
               ; format is polymorphic to-string
               (system*-maybe pygmentize-bin "-S" (format "~a" style) "-f"
                              pygmentize-format))))))
      (super traverse-content i fp))

    (define/override (render-content i part ri)
      (if (and (element? i)
               (let ([s (element-style i)])
                 (and (style? s)
                      (or
                       (equal? (style-name s) "ScrbMintInline")
                       (equal? (style-name s) "ScrbMint")))))
          ; Generate style file style specified by i, or default, if style file
          ; doesn't exist.
          (let* ([options (cdr (maybe-assoc 'mt-options (style-properties (element-style i))))])
            (pygmentize-outputer
             (element-style i)
             (with-output-to-string
               (thunk
                (with-input-from-string (apply string-append (element-content i))
                  (thunk
                   (apply
                    system*-maybe
                    pygmentize-bin
                    "-l"
                    (cdr (maybe-assoc 'lang (style-properties (element-style i))))
                    "-f"
                    pygmentize-format
                    (for/fold ([ls '()])
                              ([p options])
                      (list* "-O" (format "~a=~a" (car p) (cdr p)) ls)))))))
             part ri))
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

;; TODO: Probably want some intermediate between inline and minted that allows
;; boxed, but in a scenario where the caller has control over the preceding
;; paragraph and thus can "fix up" the paragraph I'm trying to avoid with some
;; of the inline formatting.
(define inline-options
  '((envname . "BVerbatim")
    (cssclass . "highlight-inline")
    (lineseparator . "<br />")
    ;; NB: The default is baseline=b, but this works badly in nested flows,
    ;; which are the default scribble composition?
    (verboptions . "baseline=t")
    (nowrap . "True")
    ))

(define (mintinline lang #:options [options '()] . code)
  (element
   (make-style "ScrbMintInline"
               (list* `(lang . ,lang)
                      `(mt-options . ,(append inline-options options))
                      minted-style-props))
   code))
