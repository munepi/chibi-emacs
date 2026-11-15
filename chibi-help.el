;;; chibi-help.el --- chibi quick help and help screen  -*- lexical-binding: t -*-

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

;; よく使うキーをecho areaに出す`chibi-quick-help'と、quick-help.orgを
;; 開く`chibi-help'。キーは割り当てないので、好みで割り当てる。
;;
;;   (global-set-key (kbd "C-c h") #'chibi-quick-help)

;;; Code:

(defvar org-confirm-elisp-link-function)

(defconst chibi-help--file
  (expand-file-name "quick-help.org"
                    (file-name-directory (or load-file-name buffer-file-name)))
  "The help screen.")

;;;###autoload
(defun chibi-quick-help ()
  "Show the most common keys in the echo area."
  (interactive)
  (let ((message-log-max nil))
    (message
     (concat
      (propertize "\n" 'face '(:height 0.4))
      " [C-x C-f] Open  [M-w] Copy   [C-w] Cut   [C-s] Search           "
      (propertize "[C-g]   Cancel" 'face 'bold)
      "\n"
      " [C-x C-s] Save  [C-y] Paste  [C-/] Undo  [M-x] Command          "
      (propertize "[C-x C-c] Quit" 'face 'bold)
      (propertize "\n " 'face '(:height 0.5))))
    (sit-for 30)))

(defvar-keymap chibi-help-mode-map
  "q" #'kill-current-buffer)

(define-derived-mode chibi-help-mode org-mode "chibi help"
  "Major mode of the chibi help screen.")

;;;###autoload
(defun chibi-help ()
  "Show the chibi help screen."
  (interactive)
  (find-file-read-only (if (file-exists-p chibi-help--file)
                           chibi-help--file
                         (locate-file "quick-help.org" load-path)))
  (chibi-help-mode)
  ;; quick-help.orgのelispリンクを、確認なしで実行する
  (setq-local org-confirm-elisp-link-function nil))

(provide 'chibi-help)
;;; chibi-help.el ends here
