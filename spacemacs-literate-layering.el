;;; -*- lexical-binding: t -*-
;;; spacemacs-literate-layering.el --- Create new Spacemacs layers.

;; Copyright (C) 2023 Arif Er

;; Author: Arif Er <arifer612@proton.me>
;; Created: 2023-12-28
;; Version: 1.1.1
;; Package-Requires: ((org "9.6.6") (cl-lib "0.7.1"))
;; Keywords: spacemacs, tools
;; Homepage: https://github.com/arifer612/spacemacs-literate-layering

;; This file is not a part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; Create a new Spacemacs layer that is easy to read and document by using the
;; literate programming paradigm.

;;; Code:

(require 'ob-lob)
(require 'cl-lib)
(require 'core-dotspacemacs)
(require 'core-versions)
(require 'core-configuration-layer)

(defalias 'spacemacs-literate|create-layer
  'spacemacs-literate|layering/create-layer)

(defvar spacemacs-version)
(defvar configuration-layer-private-layer-directory)
(defvar spacemacs-literate-layering--previous-lob
  org-babel-library-of-babel
  "The previous library of babel before ingesting the
spacemacs-literate-layering library.")

(declare-function ivy-read "ivy" ())
(declare-function helm "helm-core" ())

(defun spacemacs-literate|layering/create-layer ()
  "Ask the user for a configuration layer name and the layer
directory to use. Create a layer with this name in the selected
layer directory."
  (interactive)
  (let* ((current-layer-paths (mapcar (lambda (dir) (expand-file-name dir))
                                      (cl-pushnew
                                       configuration-layer-private-layer-directory
                                       dotspacemacs-configuration-layer-path)))
         (other-choice "Another directory...")
         (helm-lp-source
          `((name . "Configuration Layer Paths")
            (candidates . ,(append current-layer-paths
                                   (list other-choice)))
            (action . (lambda (c) c))))
         (layer-path-sel (if (configuration-layer/layer-used-p 'ivy)
                             (ivy-read "Configuration layer path: "
                                       (append current-layer-paths
                                               (list other-choice)))
                           (helm :sources helm-lp-source
                                 :prompt "Configuration layer path: ")))
         (layer-path (cond
                      ((string-equal layer-path-sel other-choice)
                       (read-directory-name (concat "Other configuration "
                                                    "layer path: ") "~/"))
                      ((member layer-path-sel current-layer-paths)
                       layer-path-sel)
                      (t
                       (error "Please select an option from the list"))))
         (name (read-from-minibuffer "Configuration layer name: "))
         (layer-dir (directory-file-name (expand-file-name name
                                                           layer-path))))
    (cond
     ((string-equal "" name)
      (configuration-layer/message
       "Cannot create a configuration layer without a name."))
     ((file-exists-p layer-dir)
      (configuration-layer/message
       (concat "Cannot create configuration layer \"%s\", "
               "this layer already exists.") name))
     (t
      (make-directory layer-dir t)
      (spacemacs-literate|layering//copy-template name layer-dir)
      (configuration-layer/message
       "Configuration layer \"%s\" successfully created." name)))))

(defun spacemacs-literate|layering//copy-template (name &optional layer-dir)
  "Copy and replace special values of TEMPLATE to layer string NAME.
If LAYER_DIR is nil, the private directory is used."
  (cl-flet ((substitute (old new) (let ((case-fold-search nil))
                                    (save-excursion
                                      (goto-char (point-min))
                                      (while (search-forward old nil t)
                                        (replace-match new t))))))
    (expand-file-name "layer.org.template"
                      (file-name-directory (locate-library "pippel")))
    (let ((src (expand-file-name "layer.org.template"
                                 (file-name-directory
                                  (locate-library "spacemacs-literate-layering"))))
          (dest (if layer-dir
                    (expand-file-name "README.org" layer-dir)
                  (expand-file-name
                   "README.org"
                   (configuration-layer//get-private-layer-dir name)))))
      (copy-file src dest)
      (find-file dest)
      (substitute "%LAYER_NAME%" name)
      (cond
       (user-full-name
        (substitute "%USER_FULL_NAME%" user-full-name)
        (substitute "%USER_MAIL_ADDRESS%" user-mail-address))
       (t
        (substitute "%USER_FULL_NAME%" "Sylvain Benner & Contributors")
        (substitute "%USER_MAIL_ADDRESS%" "sylvain.benner@gmail.com")))
      (save-buffer)
      (spacemacs-literate|layering//reload-headers)
      (spacemacs-literate|layering//lob-ingest))))

(defun spacemacs-literate|layering//lob-ingest ()
  "Ingest the library of babel source blocks needed."
  (org-babel-lob-ingest (expand-file-name
                         "library.org"
                         (file-name-directory
                          (locate-library "spacemacs-literate-layering")))))

(defun spacemacs-literate|layering//reload-headers ()
  "Reload the Org header properties."
  (revert-buffer t t)
  (save-buffer))

(define-minor-mode spacemacs-literate-layering-minor-mode
  "Toggle the SLL mode, only for layer README files.

When SLL mode is enabled, SLL's Library of Babel is ingested. When SLL mode is
turned off, SLL's Library of Babel is removed and the previous Library of Babel
is reset."
  :global nil
  :init-value nil
  :lighter "[SLL]"
  :keymap nil
  (cl-flet ((reset-lob () (setq org-babel-library-of-babel
                                spacemacs-literate-layering--previous-lob)))
    (cond ((not buffer-file-name) "")
          ((string-match-p "layers/.*/README\\.org\\'" buffer-file-name)
           (if spacemacs-literate-layering-minor-mode
               (progn
                 (spacemacs-literate|layering//lob-ingest)
                 (let ((new-lob org-babel-library-of-babel))
                   (reset-lob)
                   (setq-local org-babel-library-of-babel new-lob)))
             (reset-lob)))
          (t (when spacemacs-literate-layering-minor-mode
               (reset-lob)
               (spacemacs-literate-layering-minor-mode 0))))))

(provide 'spacemacs-literate-layering)
;;; spacemacs-literate-layering.el ends here
