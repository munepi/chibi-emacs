;;; nano.el --- N Λ N O Emacs (Japanese fork)  -*- lexical-binding: t -*-

;; Copyright (C) 2020 - N Λ N O developers
;; Copyright (C) 2026 Munehiro Yamamoto

;; Author: Nicolas P. Rougier and N Λ N O developers
;; Maintainer: Munehiro Yamamoto
;; Version: 0.1.0
;; Package-Requires: ((emacs "29.1"))
;; Keywords: faces, frames
;; URL: https://github.com/munepi/nano-emacs-ja

;; This file is not part of GNU Emacs.

;; This program is free software: you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation, either version 3 of the
;; License, or (at your option) any later version.

;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; rougier/nano-emacsをもとにした、日本語環境向けの個人的な改変版。
;;
;; このファイルはpackageのmain fileで、中身はない。各モジュールは
;; `require'しただけでは設定を変えないので、init.elから次のように
;; 呼ぶ（詳しくはREADME.mdを参照）。
;;
;;   (setq nano-font-family-monospaced "PlemolJP35 Console NFJ"
;;         nano-font-family-cjk        "PlemolJP35 Console NFJ"
;;         nano-font-size              20)
;;   (require 'nano-layout)
;;   (require 'nano-theme)
;;   (require 'nano-modeline)
;;   (require 'nano-splash)
;;   (nano-layout-setup)
;;   (nano-theme-set 'vscmacs)          ; light, dark, vscmacs
;;   (nano-refresh-theme)
;;   (nano-modeline-mode 1)
;;   (nano-splash-setup)

;;; Code:

(provide 'nano)
;;; nano.el ends here
