;;; attachment.lisp --- typed attachment storage + dedupe + size policy

(defpackage #:clpkg-markdown-notes/attachment
  (:use #:cl)
  (:import-from #:clpkg-markdown-notes/vault
                #:normalize-vault-root
                #:resolve-vault-relative-path)
  (:export
   #:attachment-record #:attachment-record-p #:make-attachment-record
   #:attachment-key #:attachment-path #:attachment-mime #:attachment-size #:attachment-deduped-p
   #:attachment-too-large #:attachment-blocked-mime
   #:store-attachment
   #:allowed-mime-p))

(in-package #:clpkg-markdown-notes/attachment)

#+sbcl
(eval-when (:compile-toplevel :load-toplevel :execute)
  (require :sb-md5))

(define-condition attachment-too-large (error)
  ((size :initarg :size :reader attachment-too-large-size)
   (max-size :initarg :max-size :reader attachment-too-large-max-size)))

(define-condition attachment-blocked-mime (error)
  ((mime :initarg :mime :reader attachment-blocked-mime-value)))

(defstruct (attachment-record
             (:constructor make-attachment-record
                 (&key key path mime size deduped-p))
             (:conc-name attachment-))
  (key "" :type string)
  (path #P"" :type pathname)
  (mime "application/octet-stream" :type string)
  (size 0 :type fixnum)
  (deduped-p nil :type boolean))

(defparameter *default-allowed-mimes*
  '("image/png" "image/jpeg" "image/webp" "application/pdf" "text/plain"))

(declaim (ftype (function (string list) (values boolean &optional)) allowed-mime-p)
         (ftype (function (pathname string string
                                  &key (:max-size fixnum)
                                       (:allowed-mimes list)
                                       (:mime string))
                          (values attachment-record &optional))
                store-attachment))

(defun allowed-mime-p (mime allowed-mimes)
  (declare (type string mime))
  (not (null (find mime allowed-mimes :test #'string=))))

(defun %hex-key-for-string (content)
  #+sbcl
  (let ((digest (sb-md5:md5sum-string content)))
    (with-output-to-string (out)
      (dotimes (i (length digest))
        (format out "~2,'0x" (aref digest i)))))
  #-sbcl
  (format nil "~36R" (sxhash content)))

(defun store-attachment (vault-root relative-name content
                          &key (max-size (* 10 1024 1024))
                            (allowed-mimes *default-allowed-mimes*)
                            (mime "application/octet-stream"))
  (declare (type pathname vault-root)
           (type string relative-name content mime)
           (type fixnum max-size))
  (let* ((root (normalize-vault-root vault-root))
         (size (length content)))
    (when (> size max-size)
      (error 'attachment-too-large :size size :max-size max-size))
    (unless (allowed-mime-p mime allowed-mimes)
      (error 'attachment-blocked-mime :mime mime))
    (let* ((key (%hex-key-for-string content))
           (target (resolve-vault-relative-path root
                                               (format nil "attachments/~A-~A" key relative-name)))
           (deduped (probe-file target)))
      (unless deduped
        (ensure-directories-exist target)
        (with-open-file (out target :direction :output :if-exists :error :if-does-not-exist :create)
          (write-string content out)))
      (make-attachment-record :key key :path target :mime mime :size size :deduped-p (not (null deduped))))))
