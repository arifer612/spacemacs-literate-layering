;;; -*- lexical-binding: t; -*-
;;; packages.el --- example layer packages file for Spacemacs.
;;
;; Copyright (c) 2012-2023 John Doe
;;
;; Author: John Doe <john@doe.com>
;; URL: https://github.com/johndoe/example-layer
;;
;; This file is not part of GNU Emacs.
;;
;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.
;;
;;; Commentary:
;;
;;; Code:

(defconst example-packages
  '(abc
    (def :location
         (recipe
          :fetcher github
          :repo "johndoe/def"))))

(defun example/pre-init-abc ()
  (when (eq example-use-abc t)
    (add-to-list 'abc-global-modes 'def)))

(defun example/post-init-abc ()
  (use-package abc
    :config
    (spacemacs|hide-lighter abc-mode)
    (message "abc is started up for the example layer"))

(defun example/init-def ()
  (use-package def
    :after abc
    :bind (:map def-mode-map
                ([C-tab] . def-forward)
                ([S-tab] . def-backward))
    :hook ((prog-mode . def-mode))))

;;; packages.el ends here
