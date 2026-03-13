;;; vault.lisp --- typed vault path sandbox helpers

(defpackage #:clpkg-markdown-notes/vault
  (:use #:cl)
  (:export
   #:vault-path-condition
   #:vault-invalid-root
   #:vault-absolute-path-rejected
   #:vault-traversal-rejected
   #:vault-out-of-root
   #:vault-canonicalization-failed
   #:normalize-vault-root
   #:resolve-vault-relative-path
   #:reject-escape-path
   #:validate-symlink-target-under-root))

(in-package #:clpkg-markdown-notes/vault)

#+sbcl
(eval-when (:compile-toplevel :load-toplevel :execute)
  (require :sb-posix))

(define-condition vault-path-condition (error)
  ((root :initarg :root :reader vault-condition-root)
   (path :initarg :path :reader vault-condition-path))
  (:documentation "Base condition for vault path sandbox violations."))

(define-condition vault-invalid-root (vault-path-condition) ()
  (:documentation "Root is missing, invalid, or not a directory."))

(define-condition vault-absolute-path-rejected (vault-path-condition) ()
  (:documentation "Absolute path input rejected; only relative paths are allowed."))

(define-condition vault-traversal-rejected (vault-path-condition) ()
  (:documentation "Lexical traversal attempt (..) rejected before filesystem resolution."))

(define-condition vault-out-of-root (vault-path-condition) ()
  (:documentation "Canonical target escaped normalized root."))

(define-condition vault-canonicalization-failed (vault-path-condition) ()
  (:documentation "Canonicalization failed for root/target path."))

(declaim (ftype (function (pathname) (values pathname &optional)) normalize-vault-root)
         (ftype (function (pathname string) (values pathname &optional)) resolve-vault-relative-path)
         (ftype (function (pathname pathname) (values pathname &optional)) reject-escape-path)
         (ftype (function (pathname pathname) (values pathname &optional)) validate-symlink-target-under-root)
         (ftype (function (pathname) (values pathname &optional)) %canonicalize-existing-target))

(defun %absolute-string-path-p (s)
  (or (and (> (length s) 0) (char= (char s 0) #\/))
      (and (> (length s) 2)
           (alpha-char-p (char s 0))
           (char= (char s 1) #\:))))

(defun %ensure-directory-pathname (p)
  (let ((s (namestring p)))
    (if (and (> (length s) 0) (char= (char s (1- (length s))) #\/))
        p
        (pathname (concatenate 'string s "/")))))

(defun normalize-vault-root (root)
  "Canonicalize and validate ROOT as an existing directory pathname."
  (handler-case
      (let* ((tru (truename root))
             (dir (%ensure-directory-pathname tru)))
        (unless (probe-file dir)
          (error 'vault-invalid-root :root root :path root))
        dir)
    (error ()
      (error 'vault-invalid-root :root root :path root))))

(defun resolve-vault-relative-path (root relative)
  "Resolve RELATIVE under ROOT after lexical safety checks."
  (declare (type pathname root)
           (type string relative))
  (when (%absolute-string-path-p relative)
    (error 'vault-absolute-path-rejected :root root :path relative))
  (when (or (search "../" relative)
            (string= relative "..")
            (search "..\\" relative))
    (error 'vault-traversal-rejected :root root :path relative))
  (merge-pathnames (pathname relative) root))

(defun reject-escape-path (root candidate)
  "Reject CANDIDATE when it escapes ROOT after canonicalization."
  (let* ((root* (namestring (%ensure-directory-pathname root)))
         (cand* (namestring candidate)))
    (unless (and (>= (length cand*) (length root*))
                 (string= root* cand* :end2 (length root*)))
      (error 'vault-out-of-root :root root :path candidate))
    candidate))

(defun %pathname-directory (p)
  (make-pathname :name nil :type nil :defaults p))

#+sbcl
(defun %pathname-symlink-p (p)
  (sb-posix:s-islnk (sb-posix:stat-mode (sb-posix:lstat (namestring p)))))

#+sbcl
(defun %resolve-symlink-referent (link-path)
  (let* ((raw (sb-posix:readlink (namestring link-path)))
         (candidate (if (%absolute-string-path-p raw)
                        (pathname raw)
                        (merge-pathnames (pathname raw)
                                         (%pathname-directory link-path)))))
    (truename candidate)))

(defun %canonicalize-existing-target (target)
  (let ((canonical (truename target)))
    #+sbcl
    (if (%pathname-symlink-p canonical)
        (%resolve-symlink-referent canonical)
        canonical)
    #-sbcl canonical))

(defun validate-symlink-target-under-root (root target)
  "Canonicalize TARGET and ensure it remains under ROOT."
  (handler-case
      (let* ((root* (normalize-vault-root root))
             (target* (%canonicalize-existing-target target)))
        (reject-escape-path root* target*))
    (file-error ()
      (error 'vault-canonicalization-failed :root root :path target))
    (error (e)
      (if (typep e 'vault-path-condition)
          (error e)
          (error 'vault-canonicalization-failed :root root :path target)))))
