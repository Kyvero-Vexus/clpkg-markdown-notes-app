;;; verify-export-surfaces.lisp

(defun slurp (path)
  (with-open-file (in path :direction :input)
    (let ((s (make-string (file-length in))))
      (read-sequence s in)
      s)))

(defun must-contain (content needle path)
  (unless (search needle content :test #'char=)
    (error "Missing required token ~S in ~A" needle path))
  (format t "PASS ~A contains ~S~%" path needle))

;; Org-mode renderer
(let* ((path "/home/slime/projects/clpkg-markdown-notes-app/src/export/orgmode.coal")
       (c (slurp path)))
  (dolist (needle '("module Export.OrgMode" "data OrgConfig" "render-to-org"))
    (must-contain c needle path)))

;; JSON graph export
(let* ((path "/home/slime/projects/clpkg-markdown-notes-app/src/export/json-graph.coal")
       (c (slurp path)))
  (dolist (needle '("module Export.JsonGraph" "data GraphNode" "data GraphEdge"
                    "data NoteGraph" "build-note-graph" "serialize-graph"))
    (must-contain c needle path)))

(format t "EXPORT SURFACES PASSED~%")
(sb-ext:exit :code 0)
