;;; search.lisp --- full-text trigram search engine

(defpackage #:clpkg-markdown-notes/search
  (:use #:cl)
  (:export
   #:search-index #:search-index-p #:make-search-index
   #:si-entries
   #:index-entry #:index-entry-p #:make-index-entry
   #:ie-path #:ie-trigrams
   #:extract-trigrams
   #:index-note! #:search-notes
   #:search-no-results))

(in-package #:clpkg-markdown-notes/search)

(define-condition search-no-results (condition)
  ((query :initarg :query :reader search-no-results-query)))

(defstruct (index-entry
             (:constructor make-index-entry (&key path trigrams))
             (:conc-name ie-))
  (path "" :type string)
  (trigrams '() :type list))

(defstruct (search-index
             (:constructor make-search-index (&key (entries nil)))
             (:conc-name si-))
  (entries '() :type list))

(declaim (ftype (function (string) (values list &optional)) extract-trigrams)
         (ftype (function (search-index string string) (values search-index &optional)) index-note!)
         (ftype (function (search-index string) (values list &optional)) search-notes))

(defun extract-trigrams (text)
  "Extract unique trigrams from text (lowercased)."
  (declare (type string text))
  (let ((lower (string-downcase text))
        (result '()))
    (loop for i from 0 below (max 0 (- (length lower) 2))
          do (pushnew (subseq lower i (+ i 3)) result :test #'string=))
    (nreverse result)))

(defun index-note! (index path content)
  (declare (type search-index index) (type string path content))
  (let ((trigrams (extract-trigrams content))
        (existing (find path (si-entries index) :key #'ie-path :test #'string=)))
    (if existing
        (setf (ie-trigrams existing) trigrams)
        (push (make-index-entry :path path :trigrams trigrams)
              (si-entries index))))
  index)

(defun search-notes (index query)
  "Search index for notes matching query. Returns list of (path . score) sorted by score desc."
  (declare (type search-index index) (type string query))
  (let* ((qtrigrams (extract-trigrams query))
         (results '()))
    (dolist (entry (si-entries index))
      (let ((score (count-if (lambda (qt)
                               (member qt (ie-trigrams entry) :test #'string=))
                             qtrigrams)))
        (when (> score 0)
          (push (cons (ie-path entry) score) results))))
    (sort results #'> :key #'cdr)))
