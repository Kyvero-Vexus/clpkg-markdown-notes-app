;;; note.lisp --- typed note CRUD API on top of vault sandbox helpers

(defpackage #:clpkg-markdown-notes/note
  (:use #:cl)
  (:import-from #:clpkg-markdown-notes/vault
                #:normalize-vault-root
                #:resolve-vault-relative-path)
  (:export
   #:note-record
   #:note-record-p
   #:make-note-record
   #:note-name
   #:note-path
   #:note-content
   #:note-invalid-name
   #:note-not-found
   #:create-note
   #:read-note
   #:update-note
   #:delete-note
   #:rename-note
   #:move-note))

(in-package #:clpkg-markdown-notes/note)

(define-condition note-invalid-name (error)
  ((name :initarg :name :reader note-invalid-name-value)))

(define-condition note-not-found (error)
  ((name :initarg :name :reader note-not-found-value)
   (path :initarg :path :reader note-not-found-path)))

(defstruct (note-record
             (:constructor make-note-record (&key name path content))
             (:conc-name note-))
  (name "" :type string)
  (path #P"" :type pathname)
  (content "" :type string))

(declaim (ftype (function (string) (values string &optional)) %validate-note-name)
         (ftype (function (pathname string) (values pathname &optional)) %note-path)
         (ftype (function (pathname string string) (values note-record &optional)) create-note)
         (ftype (function (pathname string) (values note-record &optional)) read-note)
         (ftype (function (pathname string string) (values note-record &optional)) update-note)
         (ftype (function (pathname string &key (:trash boolean)) (values boolean &optional)) delete-note)
         (ftype (function (pathname string string) (values pathname &optional)) rename-note)
         (ftype (function (pathname string string) (values pathname &optional)) move-note))

(defun %validate-note-name (name)
  (declare (type string name))
  (when (or (zerop (length name))
            (search "../" name)
            (search "..\\" name)
            (search "/" name)
            (search "\\" name))
    (error 'note-invalid-name :name name))
  name)

(defun %note-path (root name)
  (declare (type pathname root)
           (type string name))
  (let* ((safe-name (%validate-note-name name))
         (with-ext (if (search ".md" safe-name :from-end t)
                       safe-name
                       (concatenate 'string safe-name ".md"))))
    (resolve-vault-relative-path root with-ext)))

(defun %read-file-string (path)
  (with-open-file (in path :direction :input :if-does-not-exist nil)
    (unless in
      nil)
    (let ((s (make-string (file-length in))))
      (read-sequence s in)
      s)))

(defun create-note (vault-root name content)
  (declare (type pathname vault-root)
           (type string name content))
  (let* ((root (normalize-vault-root vault-root))
         (path (%note-path root name)))
    (ensure-directories-exist path)
    (with-open-file (out path :direction :output :if-exists :error :if-does-not-exist :create)
      (write-string content out))
    (make-note-record :name name :path path :content content)))

(defun read-note (vault-root name)
  (declare (type pathname vault-root)
           (type string name))
  (let* ((root (normalize-vault-root vault-root))
         (path (%note-path root name))
         (content (%read-file-string path)))
    (unless content
      (error 'note-not-found :name name :path path))
    (make-note-record :name name :path path :content content)))

(defun update-note (vault-root name new-content)
  (declare (type pathname vault-root)
           (type string name new-content))
  (let* ((root (normalize-vault-root vault-root))
         (path (%note-path root name))
         (tmp (merge-pathnames (make-pathname :name (format nil ".~A.tmp" name) :type "md")
                               (make-pathname :name nil :type nil :defaults path))))
    (unless (probe-file path)
      (error 'note-not-found :name name :path path))
    (with-open-file (out tmp :direction :output :if-exists :supersede :if-does-not-exist :create)
      (write-string new-content out)
      (finish-output out))
    (rename-file tmp path)
    (make-note-record :name name :path path :content new-content)))

(defun delete-note (vault-root name &key (trash t))
  (declare (type pathname vault-root)
           (type string name)
           (type boolean trash))
  (let* ((root (normalize-vault-root vault-root))
         (path (%note-path root name)))
    (unless (probe-file path)
      (error 'note-not-found :name name :path path))
    (if trash
        (let ((trash-path (resolve-vault-relative-path root
                                                       (format nil ".trash/~A.md" (%validate-note-name name)))))
          (ensure-directories-exist trash-path)
          (rename-file path trash-path)
          t)
        (progn
          (delete-file path)
          t))))

(defun rename-note (vault-root old-name new-name)
  (declare (type pathname vault-root)
           (type string old-name new-name))
  (let* ((root (normalize-vault-root vault-root))
         (old-path (%note-path root old-name))
         (new-path (%note-path root new-name)))
    (unless (probe-file old-path)
      (error 'note-not-found :name old-name :path old-path))
    (ensure-directories-exist new-path)
    (rename-file old-path new-path)
    new-path))

(defun move-note (vault-root name new-relative-folder)
  (declare (type pathname vault-root)
           (type string name new-relative-folder))
  (let* ((root (normalize-vault-root vault-root))
         (old-path (%note-path root name))
         (safe-folder (%validate-note-name (substitute #\- #\/ new-relative-folder)))
         (new-path (resolve-vault-relative-path root (format nil "~A/~A.md" safe-folder (%validate-note-name name)))))
    (unless (probe-file old-path)
      (error 'note-not-found :name name :path old-path))
    (ensure-directories-exist new-path)
    (rename-file old-path new-path)
    new-path))
