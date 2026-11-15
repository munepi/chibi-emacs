;;; chibi-layout.el --- chibi frame layout  -*- lexical-binding: t -*-

;; Copyright (C) 2020 - N Λ N O developers
;; Copyright (C) 2026 Munehiro Yamamoto

;; This file is not part of GNU Emacs.

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

;; フレームの余白、ウィンドウの区切り、折り返しの記号などの見た目。
;;
;;   (chibi-layout-setup)
;;
;; frame parameterは、`default-frame-alist'にまだないものだけを足す。
;; early-init.elなどで決めた大きさは、そのまま使われる。
;;
;; macOSでは、ターミナルで次のようにすると1pixelの枠が出る。
;;   defaults write com.apple.universalaccess increaseContrast -bool YES
;; anti-aliasingの強さ（0〜3）は次で変えられる。
;;   defaults write org.gnu.Emacs AppleFontSmoothing -int 1

;;; Code:

(require 'disp-table)
(require 'chibi-faces)

(defcustom chibi-layout-frame-parameters
  '((min-height . 1)
    (height     . 45)
    (min-width  . 1)
    (width      . 81)
    (vertical-scroll-bars . nil)
    (internal-border-width . 24)
    (left-fringe    . 1)
    (right-fringe   . 1)
    (tool-bar-lines . 0)
    (menu-bar-lines . 0))
  "Frame parameters added to `default-frame-alist' by `chibi-layout-setup'.
Parameters that are already in `default-frame-alist' are kept."
  :group 'chibi
  :type '(alist :key-type symbol :value-type sexp))

(defun chibi-layout--term-display-table ()
  "Use an empty display table in term mode.
Otherwise, zsh shows a spurious % after each command on macOS."
  (setq buffer-display-table (make-display-table)))

;;;###autoload
(defun chibi-layout-setup ()
  "Set up the frame layout of chibi."
  (dolist (param chibi-layout-frame-parameters)
    (unless (assq (car param) default-frame-alist)
      (setq default-frame-alist (append default-frame-alist (list param)))))
  (when (fboundp 'tool-bar-mode) (tool-bar-mode -1))
  (when (fboundp 'scroll-bar-mode) (scroll-bar-mode -1))
  (when (fboundp 'tooltip-mode) (tooltip-mode -1))
  (menu-bar-mode -1)
  ;; Vertical window divider
  (setq window-divider-default-right-width 24
        window-divider-default-places 'right-only)
  (window-divider-mode 1)
  ;; Truncation and wrap glyphs
  (set-display-table-slot standard-display-table 'truncation
                          (make-glyph-code ?… 'chibi-face-fallback))
  (set-display-table-slot standard-display-table 'wrap
                          (make-glyph-code ?↩ 'chibi-face-fallback))
  (add-hook 'term-mode-hook #'chibi-layout--term-display-table))

(provide 'chibi-layout)
;;; chibi-layout.el ends here
