;;; nano-base-colors.el --- The 9 basic colors of N Λ N O  -*- lexical-binding: t -*-

;; Copyright (C) 2020 - N Λ N O developers

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

;; nanoの9つの基本色。既定値は、読み込んだときのEmacsのfaceから取る。
;; 普通は`nano-theme-set'で、`nano-theme-palettes'の配色に切り替える。
;;
;; ほかに、配色によっては次の2色を使う（nilならsubtleと同じ）。
;; - `nano-color-header-background'：header lineの背景
;; - `nano-color-border'：ウィンドウの区切り線（mode lineの下線）

;;; Code:

(defgroup nano nil
  "Faces and colors for the nano emacs theme."
  :group 'faces)

;; customizeは、defcustomのSTANDARDを評価し直して既定値かどうかを
;; 判断するので、既定の色は読み込んだときに一度だけ取っておく。
(defvar nano-base-colors--defaults
  `((foreground . ,(face-foreground 'default nil t))
    (background . ,(face-background 'default nil t))
    (highlight  . ,(face-background 'fringe nil t))
    (critical   . ,(face-foreground 'error nil t))
    (salient    . ,(face-foreground 'font-lock-keyword-face nil t))
    (strong     . ,(face-foreground 'default nil t))
    (popout     . ,(face-foreground 'font-lock-string-face nil t))
    (subtle     . ,(face-background 'mode-line-inactive nil t))
    (faded      . ,(face-foreground 'shadow nil t)))
  "Default colors, taken from the faces when this file was loaded.")

(defun nano-base-colors--get (name)
  "Return the default color of NAME, a symbol such as `foreground'."
  (alist-get name nano-base-colors--defaults))

(defcustom nano-color-foreground (nano-base-colors--get 'foreground)
  "Foreground color of the regular text."
  :type 'color :group 'nano)

(defcustom nano-color-background (nano-base-colors--get 'background)
  "Background color of the frame."
  :type 'color :group 'nano)

(defcustom nano-color-highlight (nano-base-colors--get 'highlight)
  "Background color of the current line (`hl-line')."
  :type 'color :group 'nano)

(defcustom nano-color-critical (nano-base-colors--get 'critical)
  "Color for information that requires immediate action."
  :type 'color :group 'nano)

(defcustom nano-color-salient (nano-base-colors--get 'salient)
  "Color for important information, such as links and keywords."
  :type 'color :group 'nano)

(defcustom nano-color-strong (nano-base-colors--get 'strong)
  "Color for structural information, such as titles."
  :type 'color :group 'nano)

(defcustom nano-color-popout (nano-base-colors--get 'popout)
  "Color for information that needs attention, such as strings."
  :type 'color :group 'nano)

(defcustom nano-color-subtle (nano-base-colors--get 'subtle)
  "Background color that suggests an area, such as the region."
  :type 'color :group 'nano)

(defcustom nano-color-faded (nano-base-colors--get 'faded)
  "Color for less important information, such as comments."
  :type 'color :group 'nano)

(defcustom nano-color-header-background nil
  "Background color of the header line, or nil to use `nano-color-subtle'."
  :type '(choice (const :tag "Same as subtle" nil) color) :group 'nano)

(defcustom nano-color-border nil
  "Color of the window separators, or nil to use `nano-color-subtle'."
  :type '(choice (const :tag "Same as subtle" nil) color) :group 'nano)

(provide 'nano-base-colors)
;;; nano-base-colors.el ends here
