;;; verify-index-layer.lisp

(load "/home/slime/projects/clpkg-markdown-notes-app/src/index/search.lisp")
(load "/home/slime/projects/clpkg-markdown-notes-app/src/index/backlinks.lisp")
(load "/home/slime/projects/clpkg-markdown-notes-app/src/index/tag-index.lisp")

(use-package :clpkg-markdown-notes/search)
(use-package :clpkg-markdown-notes/backlinks)
(use-package :clpkg-markdown-notes/tags)

(defun ok (x) (format t "PASS ~A~%" x))

;; Trigram extraction
(let ((tris (extract-trigrams "hello")))
  (assert (member "hel" tris :test #'string=))
  (assert (member "ell" tris :test #'string=))
  (assert (member "llo" tris :test #'string=))
  (ok "trigram extraction"))

;; Search indexing + query
(let ((idx (make-search-index)))
  (index-note! idx "a.md" "hello world")
  (index-note! idx "b.md" "goodbye world")
  (let ((results (search-notes idx "hello")))
    (assert (string= "a.md" (caar results)))
    (assert (> (cdar results) 0)))
  (ok "search index + query"))

;; Backlinks
(let ((bi (make-backlink-index)))
  (register-links! bi "a.md" '("b.md" "c.md"))
  (assert (member "a.md" (get-backlinks bi "b.md") :test #'string=))
  (assert (equal '("b.md" "c.md") (get-forward-links bi "a.md")))
  (ok "backlink index"))

;; Orphan detection
(let ((bi (make-backlink-index)))
  (register-links! bi "a.md" '("b.md"))
  (let ((orphans (find-orphans bi '("a.md" "b.md" "c.md"))))
    (assert (member "c.md" orphans :test #'string=))
    (assert (not (member "a.md" orphans :test #'string=))))
  (ok "orphan detection"))

;; Tag index
(let ((ti (make-tag-index)))
  (register-tags! ti "a.md" '("lisp" "cl"))
  (register-tags! ti "b.md" '("lisp"))
  (assert (= 2 (length (get-notes-by-tag ti "lisp"))))
  (assert (= 1 (length (get-notes-by-tag ti "cl"))))
  (assert (member "lisp" (all-tags ti) :test #'string=))
  (ok "tag index"))

(format t "INDEX LAYER CHECKS PASSED~%")
(sb-ext:exit :code 0)
