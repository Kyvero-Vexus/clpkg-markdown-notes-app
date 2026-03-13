;;; verify-attachment-storage.lisp

(load "/home/slime/projects/clpkg-markdown-notes-app/src/vault/vault.lisp")
(load "/home/slime/projects/clpkg-markdown-notes-app/src/vault/attachment.lisp")
(use-package :clpkg-markdown-notes/attachment)

(defun ok (x) (format t "PASS ~A~%" x))

(let* ((root (pathname (format nil "/tmp/clpkg-attach-vault-~D/" (get-universal-time)))))
  (ensure-directories-exist (merge-pathnames #P"attachments/" root))

  (let ((a1 (store-attachment root "a.txt" "hello"
                              :mime "text/plain" :max-size 100)))
    (assert (attachment-record-p a1))
    (ok "store attachment"))

  (let* ((a1 (store-attachment root "a.txt" "hello"
                               :mime "text/plain" :max-size 100))
         (a2 (store-attachment root "a.txt" "hello"
                               :mime "text/plain" :max-size 100)))
    (assert (string= (attachment-key a1) (attachment-key a2)))
    (assert (attachment-deduped-p a2))
    (ok "dedupe key reuse"))

  (handler-case
      (progn (store-attachment root "x.bin" "0123456789" :mime "text/plain" :max-size 2)
             (error "expected too-large"))
    (attachment-too-large () (ok "size policy")))

  (handler-case
      (progn (store-attachment root "evil.bin" "abc" :mime "application/x-msdownload")
             (error "expected blocked mime"))
    (attachment-blocked-mime () (ok "mime policy"))))

(format t "ALL ATTACHMENT CHECKS PASSED~%")
(sb-ext:exit :code 0)
