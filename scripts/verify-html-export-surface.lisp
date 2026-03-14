;;; verify-html-export-surface.lisp

(defun slurp (path)
  (with-open-file (in path :direction :input)
    (let ((s (make-string (file-length in))))
      (read-sequence s in)
      s)))

(defun must-contain (content needle path)
  (unless (search needle content :test #'char=)
    (error "Missing required token ~S in ~A" needle path))
  (format t "PASS ~A contains ~S~%" path needle))

(let* ((path "/home/slime/projects/clpkg-markdown-notes-app/src/export/html.coal")
       (c (slurp path)))
  (dolist (needle '("module Export.Html"
                    "data HtmlConfig"
                    "data SanitizePolicy"
                    "render-to-html"
                    "sanitize-html"
                    "AllowAll" "StripAll" "AllowList"))
    (must-contain c needle path)))

(format t "HTML EXPORT SURFACE CHECKS PASSED~%")
(sb-ext:exit :code 0)
