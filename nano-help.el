;;; nano-help.el --- N Λ N O quick help and help screen  -*- lexical-binding: t -*-

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

;; よく使うキーをecho areaに出す`nano-quick-help'と、quick-help.orgを
;; 開く`nano-help'。キーは割り当てないので、好みで割り当てる。
;;
;;   (global-set-key (kbd "C-c h") #'nano-quick-help)

;;; Code:

(defvar org-confirm-elisp-link-function)

(defconst nano-help--file
  (expand-file-name "quick-help.org"
                    (file-name-directory (or load-file-name buffer-file-name)))
  "The help screen.")

;;;###autoload
(defun nano-quick-help ()
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

(defvar-keymap nano-help-mode-map
  "q" #'kill-current-buffer)

(define-derived-mode nano-help-mode org-mode "Nano help"
  "Major mode of the nano help screen.")

;;;###autoload
(defun nano-help ()
  "Show the nano help screen."
  (interactive)
  (find-file-read-only (if (file-exists-p nano-help--file)
                           nano-help--file
                         (locate-file "quick-help.org" load-path)))
  (nano-help-mode)
  ;; quick-help.orgのelispリンクを、確認なしで実行する
  (setq-local org-confirm-elisp-link-function nil))

(provide 'nano-help)
;;; nano-help.el ends here
