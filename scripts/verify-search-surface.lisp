;;; verify-search-surface.lisp

(defun slurp (path)
  (with-open-file (in path :direction :input)
    (let ((s (make-string (file-length in))))
      (read-sequence s in)
      s)))

(defun must-contain (content needle path)
  (unless (search needle content :test #'char=)
    (error "Missing required token ~S in ~A" needle path))
  (format t "PASS ~A contains ~S~%" path needle))

(let* ((path "/home/slime/projects/clpkg-markdown-notes-app/src/core/search.coal")
       (c (slurp path)))
  (dolist (needle '("module Core.Search"
                    "data Trigram"
                    "data TrigramIndex"
                    "data LinkEdge"
                    "data LinkGraph"
                    "extract-trigrams"
                    "trigram-score"
                    "build-link-graph"))
    (must-contain c needle path)))

(format t "SEARCH SURFACE CHECKS PASSED~%")
(sb-ext:exit :code 0)
