;;; nano-theme-light.el --- N Λ N O light palette (Material)  -*- lexical-binding: t -*-

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

;; 以前の設定との互換のためのfeature。配色は`nano-theme-palettes'の
;; `light'にあり、`nano-theme-set-light'も`nano-theme'で定義している。
;;
;;   (nano-theme-set 'light)
;;   (nano-refresh-theme)

;;; Code:

(require 'nano-theme)

(provide 'nano-theme-light)
;;; nano-theme-light.el ends here
