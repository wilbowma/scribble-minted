#lang racket/base

(require
 (only-in rackunit require/expose)
 racket/runtime-path
 scribble/core
 scribble/base
 scribble/latex-properties
 scribble/html-properties
 racket/function
 racket/system
 racket/port
 racket/list
 racket/string
 racket/dict
 (only-in xml string->xexpr cdata))

(provide
 minted
 mintinline
 current-pygmentize-path
 current-pygmentize-default-style)

(define-runtime-path minted-tex-path "minted.tex")
(define-runtime-path minted-css-path "minted.css")
(define-runtime-path scribbleeqsue-minted-css-path "minted-scribbleesque-style.css")

(define current-custom-styles
  (make-parameter
   `((scribbleesque . ,(list
                        (css-style-addition scribbleeqsue-minted-css-path))))))

(define (add-custom-style name file)
  (current-custom-styles
   (cons (cons name file) (current-custom-styles))))

(define (custom-style? style)
  (member style (dict-keys (current-custom-styles))))

;; Default value #f means "try to find the path and error if not found".
(define current-pygmentize-path (make-parameter #f))

(define current-pygmentize-default-style (make-parameter 'default))

(define (system*-maybe bin . args)
  (let ([res (apply system*/exit-code bin args)])
    (if (not (zero? res))
        (error (format "Error running ~a, which returned the error code" bin) res)
        res)))

(define (maybe-assoc key als)
  (findf (lambda (x) (and (pair? x) (equal? (car x) key)))
         als))

(define pygmentize-bin
  (or (current-pygmentize-path)
      (find-executable-path "pygmentize")
      (error "Could not find pygmentize in path; try setting current-pygmentize-path manually.")))

;; Not needed at all any more, I think.
(define minted-style-props
  (list
   (make-css-addition minted-css-path)
   (make-tex-addition minted-tex-path)))

(require scriblib/render-cond)

(define (make-minted-style-file-addition backend style)
  (let-values ([(style-file-suffix pygmentize-format make-addition)
                (case backend
                  [(latex pdf)
                   (values ".tex" "latex" tex-addition)]
                  [(html)
                   (values ".css" "html" css-style-addition)])])
    (let* ([options (cdr (maybe-assoc 'mt-options (style-properties style)))]
           [style (cond
                    [(maybe-assoc 'style options) => cdr]
                    [else (current-pygmentize-default-style)])]
           [pygmentize-style-file
            (format "~a/minted-~a-style~a"
                    (find-system-path 'temp-dir)
                    style
                    style-file-suffix)])

      (if (custom-style? style)
          (dict-ref (current-custom-styles) style)
          (make-addition
           (begin
             (unless (file-exists? pygmentize-style-file)
               (with-output-to-file pygmentize-style-file
                 (thunk
                  ; format is polymorphic to-string
                  (system*-maybe pygmentize-bin "-S" (format "~a" style)
                                 "-f" pygmentize-format
                                 ; Use style name as an extra CSS selector to
                                 ; support multiple styles in HTML
                                 "-a" (format ".~a" style)
                                 "-O" (format "commandprefix=PY~a" style)))))
             pygmentize-style-file))))))

(define (render-pygmentize pygmentize-format style contents)
  (let ([options (cdr (maybe-assoc 'mt-options (style-properties style)))])
    (with-output-to-string
      (thunk
       (with-input-from-string (apply string-append contents)
         (thunk
          (apply
           system*-maybe
           pygmentize-bin
           "-l"
           (cdr (maybe-assoc 'lang (style-properties style)))
           "-f"
           pygmentize-format
           "-O" (format "commandprefix=PY~a" (dict-ref options 'style (current-pygmentize-default-style)))
           (for/fold ([ls '()])
                     ([p options])
             (if (eq? (car p) 'style)
                 ls
                 (list* "-O" (format "~a=~a" (car p) (cdr p)) ls))))))))))

(define (minted-element s contents)
  (cond-element
   [html
    (let* ([style (make-style
                  (style-name s)
                  (cons
                   (make-minted-style-file-addition 'html s)
                   (style-properties s)))]
           [output (render-pygmentize "html" style contents)])
      (element
       (make-style
        #f
        (list*
         #;(list (string->xexpr ...))
         (make-minted-style-file-addition 'html s)
         (xexpr-property
          (cdata #f #f (if (equal? (style-name style) "ScrbMintInline")
                           ;; NB: Inline is not wrapped from pygments to avoid extra paragraphs.
                           ;; Instead, wrap it code manually.
                           ;; Would prefer to use <pre>, but this seems
                           ;; to prevent Scribble from folding it into the previous paragraph.
                           ;; Instead, highlight-inline asks CSS to do white-space: pre.
                           ;; Not sure how compatible this is with older browsers
                           (format "<code class=\"highlight-inline\">~a</code>"
                                   ;; Remove trailing <br /> for inline
                                   (string-trim output "<br />" #:left? #f))
                           output))
          (cdata #f #f ""))
         minted-style-props))
       ""))]
   [(or latex pdf)
    (let ([style (make-style
                  (style-name s)
                  (cons
                   (make-minted-style-file-addition 'latex s)
                   (style-properties s)))])
      (render-element
       (make-style
        #f
        (cons
         (make-minted-style-file-addition 'latex s)
         minted-style-props))
       ""
       (lambda (renderer part ri)
         (printf (render-pygmentize "latex" style contents))
         null)))]))

(define (minted lang #:options [options '()] . code)
  ;; Wrap in extra style selector
  (paragraph
   (make-style (format "~a" (dict-ref options 'style (current-pygmentize-default-style)))
               (list 'div 'never-indents))
   (minted-element
    (make-style "ScrbMint"
                (list `(lang . ,lang) `(mt-options . ,options)))
    code)))

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
    (nowrap . "True")))

(define (mintinline lang #:options [options '()] . code)
  (element
   (make-style (format "~a" (dict-ref options 'style (current-pygmentize-default-style)))
               '())
   (minted-element
    (make-style "ScrbMintInline"
                (list
                 `(lang . ,lang)
                 `(mt-options . ,(append inline-options options))))
    code)))
