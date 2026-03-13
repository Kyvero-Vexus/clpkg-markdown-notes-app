(load "src/vault/vault.lisp")

#+sbcl
(require :sb-posix)

(defun ensure-dir-pathname (p)
  (let ((s (namestring p)))
    (if (and (> (length s) 0) (char= (char s (1- (length s))) #\/))
        p
        (pathname (concatenate 'string s "/")))))

(defun mode-0600-p (path)
  #+sbcl
  (= #o600 (logand #o777 (sb-posix:stat-mode (sb-posix:stat (namestring path)))))
  #-sbcl
  t)

(defun write-atomically (target content)
  (let* ((tmp (pathname (format nil "~A.tmp" (namestring target)))))
    (with-open-file (out tmp
                         :direction :output
                         :if-exists :supersede
                         :if-does-not-exist :create)
      (write-string content out)
      (finish-output out))
    #+sbcl (sb-posix:chmod (namestring tmp) #o600)
    (unless (mode-0600-p tmp)
      (error "temporary file permissions are not 0600"))
    (rename-file tmp target)
    target))

(defun main ()
  (let* ((root (ensure-dir-pathname (truename ".")))
         (target (merge-pathnames (pathname "docs/IO-ATOMIC-CHECK.txt") root))
         (safe (clpkg-markdown-notes/vault:resolve-vault-relative-path root "docs/SPEC.md")))
    (format t "safe-path=~A~%" safe)
    (handler-case
        (progn
          (clpkg-markdown-notes/vault:resolve-vault-relative-path root "../escape")
          (error "traversal should have been rejected"))
      (clpkg-markdown-notes/vault:vault-traversal-rejected ()
        (format t "traversal-rejected=ok~%")))
    (write-atomically target "atomic-write-check")
    (format t "atomic-write=ok target=~A~%" target)
    (format t "verification=pass~%")
    (sb-ext:exit :code 0)))

(main)
