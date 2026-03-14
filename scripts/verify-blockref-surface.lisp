;;; verify-blockref-surface.lisp

(defun slurp (path)
  (with-open-file (in path :direction :input)
    (let ((s (make-string (file-length in))))
      (read-sequence s in)
      s)))

(defun must-contain (content needle path)
  (unless (search needle content :test #'char=)
    (error "Missing ~S in ~A" needle path))
  (format t "PASS ~A contains ~S~%" (file-namestring path) needle))

(let* ((path "/home/slime/projects/clpkg-markdown-notes-app/src/core/blockref.coal")
       (c (slurp path)))
  (dolist (needle '("module Core.BlockRef" "data BlockId" "data BlockRef"
                    "data TransclusionResult" "parse-block-ref" "resolve-block-ref"
                    "Transcluded" "NotFound" "Circular"))
    (must-contain c needle path)))

(format t "BLOCKREF SURFACE PASSED~%")
(sb-ext:exit :code 0)
