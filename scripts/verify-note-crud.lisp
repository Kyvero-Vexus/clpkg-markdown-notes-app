;;; verify-note-crud.lisp

(load "/home/slime/projects/clpkg-markdown-notes-app/src/vault/vault.lisp")
(load "/home/slime/projects/clpkg-markdown-notes-app/src/vault/note.lisp")

(use-package :clpkg-markdown-notes/note)

(defun ok (x) (format t "PASS ~A~%" x))

(let* ((root (pathname (format nil "/tmp/clpkg-notes-vault-~D/" (get-universal-time))))
       (trash (merge-pathnames #P".trash/" root)))
  (ensure-directories-exist trash)

  (let ((n (create-note root "alpha" "hello")))
    (assert (note-record-p n))
    (ok "create-note"))

  (let ((n (read-note root "alpha")))
    (assert (string= "hello" (note-content n)))
    (ok "read-note"))

  (let ((n (update-note root "alpha" "updated")))
    (assert (string= "updated" (note-content n)))
    (ok "update-note"))

  (let ((p (rename-note root "alpha" "beta")))
    (assert (pathnamep p))
    (ok "rename-note"))

  (assert (delete-note root "beta" :trash t))
  (ok "delete-note-to-trash")

  (create-note root "beta" "moved")
  (let ((p (move-note root "beta" "archive")))
    (assert (pathnamep p))
    (ok "move-note"))

  (handler-case
      (progn (create-note root "../bad" "x") (error "expected invalid-name"))
    (note-invalid-name () (ok "invalid-name-rejected"))))

(format t "ALL NOTE CRUD CHECKS PASSED~%")
(sb-ext:exit :code 0)
