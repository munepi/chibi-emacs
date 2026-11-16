;;; chibi-command.el --- chibi header line command prompt  -*- lexical-binding: t -*-

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

;; ミニバッファを使わずに、header lineで短い文字列を入力するprompt。
;;
;; 入力は、いまのウィンドウの下に作る小さなウィンドウ（入力用の
;; バッファ）で受け、その内容と擬似的なカーソルを、元のウィンドウの
;; header lineに表示する。入力用のウィンドウは、文字を背景色にして
;; 目立たないようにしている。
;;
;;   RET          入力を確定する
;;   C-g          やめる（ほかのウィンドウを選んでもやめる）
;;   TAB          補完する（chibi-command-xではコマンド名）
;;   M-p / M-n    履歴（↑ / ↓でも）
;;
;; キーは割り当てないので、好みで割り当てる。
;;
;;   (global-set-key (kbd "M-s-x") #'chibi-command-x)
;;   (global-set-key (kbd "M-s-s") #'chibi-command-shell)

;;; Code:

(require 'subr-x)
(require 'face-remap)
(require 'chibi-faces)

(defconst chibi-command--buffer-name " *chibi-command*"
  "Name of the input buffer.
The leading space keeps globalized minor modes (corfu, whitespace
and so on) away from it.")

;; 実行中のpromptの状態
(defvar chibi-command--input nil "The input buffer.")
(defvar chibi-command--input-window nil "The window of the input buffer.")
(defvar chibi-command--target nil "The buffer whose header line shows the prompt.")
(defvar chibi-command--target-window nil "The window where the prompt was opened.")
(defvar chibi-command--cookie nil "Face remapping of the header line of the target.")
(defvar chibi-command--information nil "Text shown while the input is empty.")
(defvar chibi-command--callback nil "Function called with the entered text.")
(defvar chibi-command--collection nil "Completion table for TAB, or nil.")
(defvar chibi-command--predicate nil "Predicate for `chibi-command--collection'.")
(defvar chibi-command--history nil "History variable (a symbol), or nil.")
(defvar chibi-command--history-index 0 "Position in the history; 0 is the input.")
(defvar chibi-command--history-input "" "The input before moving in the history.")

(defvar-keymap chibi-command-map
  :doc "Keymap of the input buffer of `chibi-command'."
  "RET"      #'chibi-command-submit
  "<return>" #'chibi-command-submit
  "C-g"      #'chibi-command-cancel
  "TAB"      #'chibi-command-complete
  "<tab>"    #'chibi-command-complete
  "M-p"      #'chibi-command-history-previous
  "<up>"     #'chibi-command-history-previous
  "M-n"      #'chibi-command-history-next
  "<down>"   #'chibi-command-history-next)

;;; Input

(defun chibi-command--active-p ()
  "Return non-nil while a prompt is open."
  (buffer-live-p chibi-command--input))

(defun chibi-command--text ()
  "Return the entered text (the first line of the input buffer)."
  (with-current-buffer chibi-command--input
    (buffer-substring-no-properties
     (point-min) (save-excursion (goto-char (point-min)) (line-end-position)))))

(defun chibi-command--set-text (text)
  "Replace the entered text with TEXT and move point to its end."
  (with-current-buffer chibi-command--input
    (goto-char (point-min))
    (delete-region (point-min) (line-end-position))
    (insert text)))

(defun chibi-command--update ()
  "Keep point on the first line and redisplay the header line."
  (when (chibi-command--active-p)
    (with-current-buffer chibi-command--input
      (let ((eol (save-excursion (goto-char (point-min)) (line-end-position))))
        (when (> (point) eol) (goto-char eol))))
    (when (buffer-live-p chibi-command--target)
      (with-current-buffer chibi-command--target
        (force-mode-line-update)))))

;;; Header line

(defun chibi-command--escape (string)
  "Double the % of STRING, keeping the text properties."
  (apply #'concat
         (mapcar (lambda (i)
                   (let ((char (substring string i (1+ i))))
                     (if (equal char "%") (concat char char) char)))
                 (number-sequence 0 (1- (length string))))))

(defun chibi-command--header ()
  "Return the entered text with a cursor and the region, for the header line."
  (if (not (chibi-command--active-p))
      ""
    (let* ((text (chibi-command--text))
           (content (if (string-empty-p text)
                        (propertize (concat (or chibi-command--information "") " ")
                                    'face 'chibi-face-faded)
                      ;; 行末のカーソルを見せるため、空白を足しておく
                      (concat text " "))))
      (with-current-buffer chibi-command--input
        (when (and (region-active-p) (not (string-empty-p text)))
          (put-text-property (min (1- (region-beginning)) (length text))
                             (1- (min (region-end) (1+ (length text))))
                             'face `(:foreground ,chibi-color-background
                                     :background ,chibi-color-faded)
                             content))
        (put-text-property (1- (point)) (point) 'face 'chibi-face-command-cursor content))
      ;; header lineでは%が特別な意味を持つ
      (chibi-command--escape content))))

(defun chibi-command--header-line-format (prompt)
  "Return the header line showing PROMPT and the input."
  (list (propertize " " 'face 'chibi-face-command-prompt 'display '(raise -0.20))
        (propertize (chibi-command--escape prompt) 'face 'chibi-face-command-prompt)
        (propertize " " 'face 'chibi-face-command-prompt 'display '(raise +0.15))
        " "
        '(:eval (chibi-command--header))))

;;; Open and close

(defun chibi-command--check-focus (window)
  "Cancel the prompt when WINDOW, the input window, is deselected.
Called from `window-selection-change-functions', which ignores
temporary selections such as `with-selected-window'."
  (unless (eq (selected-window) window)
    ;; ウィンドウ構成の変更は、hookの外でする
    (run-at-time 0 nil (lambda ()
                         (when (and (chibi-command--active-p)
                                    (not (eq (selected-window)
                                             chibi-command--input-window)))
                           (chibi-command--close))))))

(defun chibi-command--close ()
  "Close the prompt and restore the header line of the target."
  (let ((input chibi-command--input)
        (window chibi-command--input-window)
        (target chibi-command--target)
        (target-window chibi-command--target-window))
    (setq chibi-command--input nil
          chibi-command--input-window nil)
    (when (buffer-live-p target)
      (with-current-buffer target
        (kill-local-variable 'header-line-format)
        (when chibi-command--cookie
          (face-remap-remove-relative chibi-command--cookie))))
    (setq chibi-command--cookie nil)
    (let ((was-selected (eq (selected-window) window)))
      (when (window-live-p window)
        (ignore-errors (delete-window window)))
      (when (buffer-live-p input)
        (kill-buffer input))
      (when (and was-selected (window-live-p target-window))
        (select-window target-window)))
    (force-mode-line-update t)))

(defun chibi-command (&optional prompt callback content information
                                collection predicate history)
  "Read a line of text in the header line with PROMPT.
CONTENT is the initial text and INFORMATION is shown while the text
is empty.  When the text is entered, call CALLBACK with it, or show
it with `message' if CALLBACK is nil.  TAB completes the text with
COLLECTION and PREDICATE (see `try-completion'), or with
`dabbrev-expand' if COLLECTION is nil.  HISTORY is a history
variable (a symbol)."
  (when (minibufferp)
    (user-error "Cannot open chibi command in the minibuffer"))
  (when (chibi-command--active-p)
    (chibi-command--close))
  (let* ((window-min-height 1)
         (window-safe-min-height 1)
         (window-resize-pixelwise t)
         (split-window-keep-point t)
         (target-window (selected-window))
         (input (get-buffer-create chibi-command--buffer-name))
         (input-window (split-window target-window -2 'below)))
    (setq chibi-command--input input
          chibi-command--input-window input-window
          chibi-command--target (window-buffer target-window)
          chibi-command--target-window target-window
          chibi-command--information information
          chibi-command--callback callback
          chibi-command--collection collection
          chibi-command--predicate predicate
          chibi-command--history history
          chibi-command--history-index 0
          chibi-command--history-input "")
    ;; 入力用のバッファ。major modeの関数を呼ばない（hookを走らせない）
    ;; ので、fundamental-modeのまま、ほかのモードも有効にならない。
    (with-current-buffer input
      (let ((inhibit-read-only t))
        (erase-buffer)
        (insert (or content "") "\n-"))
      (goto-char (point-min))
      (end-of-line)
      ;; 1行目をほぼ見えない高さにし、文字は背景色にする
      (overlay-put (make-overlay (point-min) (1+ (line-end-position)))
                   'face '(:height 10))
      (setq-local cursor-type nil
                  header-line-format nil
                  mode-line-format nil)
      (dolist (face '(default region hl-line))
        (face-remap-add-relative face `(:foreground ,chibi-color-background
                                        :background ,chibi-color-background)))
      (use-local-map chibi-command-map)
      (add-hook 'post-command-hook #'chibi-command--update nil t)
      (add-hook 'window-selection-change-functions
                #'chibi-command--check-focus nil t))
    (set-window-buffer input-window input)
    (set-window-dedicated-p input-window t)
    (with-selected-window input-window
      (fit-window-to-buffer))
    (with-current-buffer input
      (setq-local window-size-fixed t))
    ;; 元のバッファのheader lineに、promptと入力を出す
    (with-current-buffer chibi-command--target
      (setq chibi-command--cookie
            (face-remap-add-relative 'header-line 'chibi-face-command))
      (setq-local header-line-format
                  (chibi-command--header-line-format (or prompt "M-x"))))
    (select-window input-window)
    (chibi-command--update)))

;;; Commands in the prompt

(defun chibi-command-submit ()
  "Enter the text."
  (interactive)
  (let ((text (chibi-command--text))
        (callback chibi-command--callback)
        (history chibi-command--history))
    (when (and history (not (string-empty-p text)))
      (add-to-history history text))
    (chibi-command--close)
    (if callback
        (funcall callback text)
      (message "%s" text))))

(defun chibi-command-cancel ()
  "Cancel the prompt."
  (interactive)
  (chibi-command--close))

(defun chibi-command-complete ()
  "Complete the text with the completion table of the prompt."
  (interactive)
  (if (not chibi-command--collection)
      (dabbrev-expand nil)
    (let* ((text (chibi-command--text))
           (completion (try-completion text chibi-command--collection
                                       chibi-command--predicate)))
      (cond ((null completion)
             (message "No match"))
            ((eq completion t)
             (message "Sole completion"))
            ((not (string= completion text))
             (chibi-command--set-text completion))
            (t
             (let ((all (sort (all-completions text chibi-command--collection
                                               chibi-command--predicate)
                              #'string<)))
               (message "%d candidates: %s%s" (length all)
                        (string-join (seq-take all 8) "  ")
                        (if (> (length all) 8) "  …" ""))))))))

(defun chibi-command--history-move (n)
  "Move N items back in the history (forward if N is negative)."
  (let* ((items (and chibi-command--history
                     (symbol-value chibi-command--history)))
         (index (+ chibi-command--history-index n)))
    (cond ((> index (length items)) (message "No earlier item"))
          ((< index 0) (message "No later item"))
          (t
           (when (= chibi-command--history-index 0)
             (setq chibi-command--history-input (chibi-command--text)))
           (setq chibi-command--history-index index)
           (chibi-command--set-text (if (= index 0)
                                        chibi-command--history-input
                                      (nth (1- index) items)))))))

(defun chibi-command-history-previous ()
  "Show the previous item of the history."
  (interactive)
  (chibi-command--history-move 1))

(defun chibi-command-history-next ()
  "Show the next item of the history."
  (interactive)
  (chibi-command--history-move -1))

;;; Commands

;;;###autoload
(defun chibi-command-x ()
  "Run a command entered in the header line."
  (interactive)
  (chibi-command "M-x" #'chibi-command-x-finalize "" "Enter command"
                 obarray #'commandp 'extended-command-history))

(defun chibi-command-x-finalize (command)
  "Run COMMAND, the name of a command."
  (let ((symbol (intern-soft command)))
    (if (commandp symbol)
        (command-execute symbol 'record)
      (user-error "No such command: %s" command))))

;;;###autoload
(defun chibi-command-shell ()
  "Run a shell command entered in the header line.
The command runs asynchronously, and its output buffer replaces the
buffer of the selected window at once (see
`chibi-command-shell-finalize')."
  (interactive)
  (chibi-command ">_" #'chibi-command-shell-finalize "" "Enter shell command"
                 nil nil 'shell-command-history))

(defun chibi-command-shell-finalize (command)
  "Run the shell COMMAND asynchronously and show its output buffer.
The buffer (`shell-command-buffer-name-async') replaces the buffer of
the selected window at once, and the output appears in it as the
command writes it.  See `async-shell-command-buffer' for what happens
when a command is still running in it."
  ;; shell-commandは終わるまで待つので、makeなどの間はEmacsが止まって
  ;; 見える。async-shell-commandにし、出力のバッファを選んでいる
  ;; ウィンドウにすぐ出す。
  (let ((display-buffer-overriding-action '(display-buffer-same-window)))
    (async-shell-command command)))

(provide 'chibi-command)
;;; chibi-command.el ends here
