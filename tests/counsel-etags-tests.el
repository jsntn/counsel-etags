;; counsel-etags-tests.el --- unit tests for counsel-etags -*- coding: utf-8 -*-

;; Author: Chen Bin <chenbin DOT sh AT gmail DOT com>

;;; License:

;; This file is not part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program; if not, write to the Free Software
;; Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

;;; Commentary:

(require 'ert)
(require 'js)

(defun get-full-path (filename)
  "Get full path of FILENAME."
  (concat
   (if load-file-name (file-name-directory load-file-name) default-directory)
   filename))

(ert-deftest counsel-etags-test-find-tag ()
  ;; one hello function in test.js
  ;; one hello function, one hello method and one test method in hello.js
  (let* (cands
         context
         (tags-file (get-full-path "TAGS.test")))
    ;; all tags across project, case insensitive, fuzzy match.
    ;; So "CHello" is also included
    (setq cands (counsel-etags-extract-cands tags-file "hello" t))
    (should (eq (length cands) 4))

    ;; all tags across project, case sensitive
    (setq cands (counsel-etags-extract-cands tags-file "hello" nil))
    (should (eq (length cands) 3))

    ;; one function named "test"
    (setq cands (counsel-etags-extract-cands tags-file "test" nil))
    (should (eq (length cands) 1))))

(ert-deftest counsel-etags-test-sort-cands-by-filename ()
  (let* (cands
         (tags-file (get-full-path "TAGS.test")))
    (setq cands (counsel-etags-extract-cands tags-file "hello" nil))
    (should (eq (length cands) 3))
    ;; the function in the external file is at the top
    (should (string-match "test.js" (car (nth 2 cands))))
    ;; sort the candidate by string-distance from "hello.js"
    (let* ((f (get-full-path "test.js")))
      (should (string-match "test.js" (car (nth 0 (counsel-etags-sort-candidates-maybe cands 3 nil f))))))))

(ert-deftest counsel-etags-test-tags-file-cache ()
  (let* (cands
         (tags-file (get-full-path "TAGS.test")))
    ;; clear cache
    (setq counsel-etags-cache nil)
    (setq cands (counsel-etags-extract-cands tags-file "hello" nil))
    (should (eq (length cands) 3))
    ;; cache is filled
    (should counsel-etags-cache)
    (should (counsel-etags-cache-content tags-file))))

(ert-deftest counsel-etags-test-tag-history ()
  (let* (cands
         (tags-file (get-full-path "TAGS.test"))
         (dir (get-full-path "")))
    ;; clear history
    (setq counsel-etags-tag-history nil)
    (setq cands (counsel-etags-extract-cands tags-file "hello" nil))
    (should (eq (length cands) 3))
    ;; only add tag when it's accessed by user manually
    (should (not counsel-etags-tag-history))
    (setq cands (mapcar 'car cands))
    (dolist (c cands) (counsel-etags-remember c dir))
    (should counsel-etags-tag-history)
    (should (eq (length counsel-etags-tag-history) 3))))

(ert-run-tests-batch-and-exit)
