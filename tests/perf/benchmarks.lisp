;;; benchmarks.lisp — performance benchmarks + budget verification

(load "/home/slime/projects/clpkg-markdown-notes-app/src/vault/vault.lisp")
(load "/home/slime/projects/clpkg-markdown-notes-app/src/vault/note.lisp")
(load "/home/slime/projects/clpkg-markdown-notes-app/src/vault/attachment.lisp")
(load "/home/slime/projects/clpkg-markdown-notes-app/src/index/search.lisp")
(load "/home/slime/projects/clpkg-markdown-notes-app/src/index/backlinks.lisp")
(load "/home/slime/projects/clpkg-markdown-notes-app/src/index/tag-index.lisp")

(use-package :clpkg-markdown-notes/note)
(use-package :clpkg-markdown-notes/attachment)
(use-package :clpkg-markdown-notes/search)
(use-package :clpkg-markdown-notes/backlinks)
(use-package :clpkg-markdown-notes/tags)

(defun ms-since (start)
  (/ (- (get-internal-real-time) start)
     (/ internal-time-units-per-second 1000.0)))

(defvar *pass* 0)
(defvar *fail* 0)

(defun budget-check (name elapsed-ms budget-ms)
  (if (<= elapsed-ms budget-ms)
      (progn (incf *pass*)
             (format t "PASS ~A: ~,2fms (budget ~Dms)~%" name elapsed-ms budget-ms))
      (progn (incf *fail*)
             (format t "FAIL ~A: ~,2fms exceeds budget ~Dms~%" name elapsed-ms budget-ms))))

(let ((root (pathname (format nil "/tmp/clpkg-perf-~D/" (get-universal-time)))))
  (ensure-directories-exist (merge-pathnames #P".trash/" root))
  (ensure-directories-exist (merge-pathnames #P"attachments/" root))

  ;; B1: Note create 1KB — budget 50ms
  (let* ((content (make-string 1024 :initial-element #\x))
         (t0 (get-internal-real-time)))
    (create-note root "perf-1k" content)
    (budget-check "note-create-1KB" (ms-since t0) 50))

  ;; B2: Note read 1KB — budget 20ms
  (let ((t0 (get-internal-real-time)))
    (read-note root "perf-1k")
    (budget-check "note-read-1KB" (ms-since t0) 20))

  ;; B3: Note update 1KB — budget 50ms
  (let* ((content (make-string 1024 :initial-element #\y))
         (t0 (get-internal-real-time)))
    (update-note root "perf-1k" content)
    (budget-check "note-update-1KB" (ms-since t0) 50))

  ;; B4: Note create 100KB — budget 100ms
  (let* ((content (make-string (* 100 1024) :initial-element #\z))
         (t0 (get-internal-real-time)))
    (create-note root "perf-100k" content)
    (budget-check "note-create-100KB" (ms-since t0) 100))

  ;; B5: Note read 100KB — budget 50ms
  (let ((t0 (get-internal-real-time)))
    (read-note root "perf-100k")
    (budget-check "note-read-100KB" (ms-since t0) 50))

  ;; B6: Attachment store 10KB — budget 50ms
  (let* ((content (make-string (* 10 1024) :initial-element #\a))
         (t0 (get-internal-real-time)))
    (store-attachment root "perf.txt" content :mime "text/plain" :max-size (* 1024 1024))
    (budget-check "attachment-store-10KB" (ms-since t0) 50))

  ;; B7: Index 100 notes — budget 200ms
  (let ((idx (make-search-index))
        (t0 (get-internal-real-time)))
    (dotimes (i 100)
      (index-note! idx (format nil "note-~D" i)
                   (format nil "Content for note ~D with some words for trigram indexing" i)))
    (budget-check "index-100-notes" (ms-since t0) 200))

  ;; B8: Search 100-note index — budget 50ms
  (let ((idx (make-search-index)))
    (dotimes (i 100)
      (index-note! idx (format nil "note-~D" i)
                   (format nil "Content for note ~D with trigrams" i)))
    (let ((t0 (get-internal-real-time)))
      (search-notes idx "trigram")
      (budget-check "search-100-notes" (ms-since t0) 50)))

  ;; B9: Register 100 backlinks — budget 50ms
  (let ((bi (make-backlink-index))
        (t0 (get-internal-real-time)))
    (dotimes (i 100)
      (register-links! bi (format nil "note-~D" i)
                       (list (format nil "note-~D" (mod (1+ i) 100)))))
    (budget-check "register-100-backlinks" (ms-since t0) 50))

  ;; B10: Register 500 tags — budget 100ms
  (let ((ti (make-tag-index))
        (t0 (get-internal-real-time)))
    (dotimes (i 100)
      (register-tags! ti (format nil "note-~D" i)
                      (list "common" "lisp" (format nil "tag-~D" i)
                            (format nil "cat-~D" (mod i 10))
                            (format nil "group-~D" (mod i 5)))))
    (budget-check "register-500-tags" (ms-since t0) 100)))

(format t "~%BENCHMARK RESULTS: ~D/~D within budget~%" *pass* (+ *pass* *fail*))
(assert (= 0 *fail*))
(sb-ext:exit :code 0)
