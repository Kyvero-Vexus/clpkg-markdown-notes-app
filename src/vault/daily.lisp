;;; daily.lisp --- date-keyed daily note auto-creation

(defpackage #:clpkg-markdown-notes/daily
  (:use #:cl)
  (:import-from #:clpkg-markdown-notes/note
                #:create-note #:read-note #:note-record #:note-content)
  (:export
   #:daily-note-path
   #:ensure-daily-note!
   #:daily-note-exists-p))

(in-package #:clpkg-markdown-notes/daily)

(declaim (ftype (function (integer integer integer) (values string &optional)) daily-note-path)
         (ftype (function (pathname integer integer integer &key (:template string))
                          (values note-record &optional))
                ensure-daily-note!)
         (ftype (function (pathname integer integer integer) (values boolean &optional))
                daily-note-exists-p))

(defun daily-note-path (year month day)
  "Return canonical daily note name: daily-YYYY-MM-DD"
  (declare (type integer year month day))
  (format nil "daily-~4,'0D-~2,'0D-~2,'0D" year month day))

(defun daily-note-exists-p (vault-root year month day)
  (declare (type pathname vault-root) (type integer year month day))
  (let ((path (merge-pathnames
               (make-pathname :name (daily-note-path year month day)
                              :type "md")
               vault-root)))
    (not (null (probe-file path)))))

(defun ensure-daily-note! (vault-root year month day
                            &key (template "# {{date}}~%~%"))
  "Create daily note if it doesn't exist. Returns the note record."
  (declare (type pathname vault-root) (type integer year month day)
           (type string template))
  (let ((name (daily-note-path year month day)))
    (unless (daily-note-exists-p vault-root year month day)
      (let ((content (format nil "~A"
                             (substitute-date-vars template year month day))))
        (create-note vault-root name content)))
    (read-note vault-root name)))

(defun substitute-date-vars (template year month day)
  (declare (type string template) (type integer year month day))
  (let* ((date-str (format nil "~4,'0D-~2,'0D-~2,'0D" year month day))
         (result template))
    (setf result (cl-ppcre-free-replace result "{{date}}" date-str))
    (setf result (cl-ppcre-free-replace result "{{year}}" (format nil "~4,'0D" year)))
    (setf result (cl-ppcre-free-replace result "{{month}}" (format nil "~2,'0D" month)))
    (setf result (cl-ppcre-free-replace result "{{day}}" (format nil "~2,'0D" day)))
    result))

(defun cl-ppcre-free-replace (string old new)
  "Simple substring replace without cl-ppcre dependency."
  (declare (type string string old new))
  (let ((pos (search old string :test #'char=)))
    (if pos
        (concatenate 'string
                     (subseq string 0 pos)
                     new
                     (cl-ppcre-free-replace (subseq string (+ pos (length old))) old new))
        string)))
