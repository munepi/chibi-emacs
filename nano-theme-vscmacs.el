;;; nano-theme-vscmacs.el --- N Λ N O dark theme with VS Code Dark+ colors  -*- lexical-binding: t -*-
;; ---------------------------------------------------------------------
;; GNU Emacs / N Λ N O - Emacs made simple
;; Copyright (C) 2020 - N Λ N O developers
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
;; ---------------------------------------------------------------------
;;; Commentary:
;;
;; A dark variant of the nano theme with the colors of Visual Studio
;; Code Dark+ (as in vscode-dark-plus-theme / vscmacs-theme).
;;
;; Unlike `nano-theme-set-dark', the font-lock faces keep the Dark+
;; syntax colors instead of the nano core faces.
;;
;; Usage:
;;   (require 'nano-theme-vscmacs)
;;   (nano-theme-set-vscmacs)
;;   (call-interactively 'nano-refresh-theme)
;;
;;; Code:

(require 'nano-base-colors)

(defvar nano-theme-var)
(defvar nano-theme-hook)

(defconst nano-theme-vscmacs-font-lock-colors
  '((font-lock-comment-face        . "#6A9955")
    (font-lock-doc-face            . "#CE9178")
    (font-lock-string-face         . "#CE9178")
    (font-lock-keyword-face        . "#569CD6")
    (font-lock-builtin-face        . "#C586C0")
    (font-lock-preprocessor-face   . "#C586C0")
    (font-lock-constant-face       . "#569CD6")
    (font-lock-negation-char-face  . "#569CD6")
    (font-lock-function-name-face  . "#DCDCAA")
    (font-lock-type-face           . "#4EC9B0")
    (font-lock-variable-name-face  . "#9CDCFE")
    ;; Emacs 29+ (mostly used by tree-sitter modes)
    (font-lock-number-face         . "#B5CEA8")
    (font-lock-function-call-face  . "#DCDCAA")
    (font-lock-variable-use-face   . "#9CDCFE")
    (font-lock-property-name-face  . "#9CDCFE")
    (font-lock-property-use-face   . "#9CDCFE")
    (font-lock-escape-face         . "#D7BA7D")
    (font-lock-regexp-face         . "#D16969")
    (font-lock-regexp-grouping-backslash . "#D7BA7D")
    (font-lock-regexp-grouping-construct . "#D7BA7D"))
  "Foreground colors of the font-lock faces in the vscmacs theme.")

(defun nano-theme-set-vscmacs ()
  "Apply the vscmacs (VS Code Dark+) Nano theme base."
  (setq frame-background-mode     'dark)
  (setq nano-color-foreground "#D4D4D4") ;; editor.foreground
  (setq nano-color-background "#1E1E1E") ;; editor.background
  (setq nano-color-highlight  "#252526") ;; sideBar.background
  (setq nano-color-critical   "#D7BA7D") ;; light orange
  (setq nano-color-salient    "#569CD6") ;; keyword blue
  (setq nano-color-strong     "#E8E8E8") ;;
  (setq nano-color-popout     "#CE9178") ;; string orange
  (setq nano-color-subtle     "#333333") ;;
  (setq nano-color-faded      "#858585") ;; editorLineNumber.foreground
  ;; to allow for toggling of the themes.
  (setq nano-theme-var "vscmacs"))

(defun nano-theme-vscmacs--font-lock ()
  "Set the Dark+ syntax colors when the vscmacs theme is active.
Otherwise reset them, so that the other nano themes are not affected."
  (let ((active (equal nano-theme-var "vscmacs")))
    (dolist (elt nano-theme-vscmacs-font-lock-colors)
      (when (facep (car elt))
        (set-face-attribute (car elt) nil
                            :foreground (if active (cdr elt) 'unspecified))))))

(add-hook 'nano-theme-hook #'nano-theme-vscmacs--font-lock)

(provide 'nano-theme-vscmacs)
;;; nano-theme-vscmacs.el ends here
