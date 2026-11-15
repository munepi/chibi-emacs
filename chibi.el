;;; chibi.el --- chibi Emacs: a Japanese-friendly N Λ N O derivative  -*- lexical-binding: t -*-

;; Copyright (C) 2020 - N Λ N O developers
;; Copyright (C) 2026 Munehiro Yamamoto

;; Author: Nicolas P. Rougier and N Λ N O developers
;; Maintainer: Munehiro Yamamoto
;; Version: 0.1.0
;; Package-Requires: ((emacs "29.1"))
;; Keywords: faces, frames
;; URL: https://github.com/munepi/chibi-emacs

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

;; N Λ N O Emacs（rougier/nano-emacs）をもとにした、日本語環境向けの
;; 個人的なpackage。
;;
;; このファイルはpackageのmain fileで、中身はない。各モジュールは
;; `require'しただけでは設定を変えないので、init.elから次のように
;; 呼ぶ（詳しくはREADME.mdを参照）。
;;
;;   (setq chibi-font-family-monospaced "PlemolJP35 Console NFJ"
;;         chibi-font-family-cjk        "PlemolJP35 Console NFJ"
;;         chibi-font-size              20)
;;   (require 'chibi-layout)
;;   (require 'chibi-theme)
;;   (require 'chibi-modeline)
;;   (require 'chibi-splash)
;;   (chibi-layout-setup)
;;   (chibi-theme-set 'vscmacs)          ; light, dark, vscmacs
;;   (chibi-refresh-theme)
;;   (chibi-modeline-mode 1)
;;   (chibi-splash-setup)

;;; Code:

(provide 'chibi)
;;; chibi.el ends here
