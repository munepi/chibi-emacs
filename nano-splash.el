;;; nano-splash.el --- N Λ N O splash screen  -*- lexical-binding: t -*-

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

;; 起動時のsplash screen。
;;  - ロゴ、mode line、scroll barはない。
;;  - キーを押すかクリックすると閉じる。
;;  - `nano-splash-timeout'秒たつと閉じる。Mac port（emacs-mac）では
;;    fade outする。
;;  - ファイルを開いているバッファがあるときは出さない。
;;
;;   (nano-splash-setup)

;;; Code:

(require 'subr-x)
(require 'nano-faces)

(declare-function mac-start-animation "macfns.c")

(defgroup nano-splash nil
  "N Λ N O splash screen."
  :group 'nano)

(defcustom nano-splash-contents
  (lambda ()
    (list (cons "GNU Emacs / N Λ N O" 'nano-face-strong)
          (cons "Emacs made simple" 'nano-face-faded)))
  "Function returning the lines of the splash screen.
Each element is (STRING . FACE).  Every line is centered
horizontally; STRING may contain newlines."
  :group 'nano-splash
  :type 'function)

(defcustom nano-splash-center-vertically t
  "Non-nil means the splash contents are centered vertically."
  :group 'nano-splash
  :type 'boolean)

(defcustom nano-splash-timeout 0.50
  "Idle seconds before the splash screen fades out."
  :group 'nano-splash
  :type 'number)

(defcustom nano-splash-show-help t
  "Non-nil means show how to get help after the splash screen.
Only when `nano-help' is loaded."
  :group 'nano-splash
  :type 'boolean)

(defconst nano-splash--buffer-name "*splash*")

(defvar nano-splash--timers nil
  "Timers started by `nano-splash', except the one of the help message.")

(defvar nano-splash--help-timer nil
  "Timer to show the help message after the splash screen.")

(defun nano-splash--close (&optional keep-help)
  "Cancel the timers and kill the splash screen.
If KEEP-HELP is non-nil, the help message is still shown."
  (mapc #'cancel-timer nano-splash--timers)
  (setq nano-splash--timers nil)
  (when (and nano-splash--help-timer (not keep-help))
    (cancel-timer nano-splash--help-timer)
    (setq nano-splash--help-timer nil))
  (when (get-buffer nano-splash--buffer-name)
    (message nil)
    (kill-buffer nano-splash--buffer-name)))

(defun nano-splash--insert-contents (width)
  "Insert the lines of `nano-splash-contents', centered in WIDTH columns."
  (let ((first t))
    (dolist (line (funcall nano-splash-contents))
      (unless first (insert "\n"))
      (setq first nil)
      (let ((start (point)))
        (insert (propertize (car line) 'face (cdr line)))
        ;; ウィンドウより長い行（Featuresなど）は、truncate-linesがtだと
        ;; 切れてしまうので、幅に合わせて改行してから中央に寄せる。
        (let ((fill-column (max 20 (- width 4))))
          (fill-region start (point)))
        (save-excursion
          (goto-char start)
          (while (< (point) (point-max))
            (let ((fill-column width))
              (center-line))
            (forward-line 1)))))))

(defvar nano-splash-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map [t] #'nano-splash-kill)
    map)
  "Keymap of the splash screen: any key kills it.")

(defun nano-splash-help-message ()
  "Show how to get help in the echo area."
  (message
   (concat
    (when (display-graphic-p) (propertize "\n " 'face '(:height 0.4)))
    (propertize (substitute-command-keys
                 "Type \\[nano-quick-help] for quick help, \\[nano-help] for help.")
                'face 'nano-face-faded)
    (when (display-graphic-p) (propertize "\n " 'face '(:height 0.5))))))

;;;###autoload
(defun nano-splash ()
  "Show the nano splash screen."
  (interactive)
  (if (seq-some #'buffer-file-name (buffer-list))
      ;; ファイルを開いているときは出さない
      (nano-splash-kill)
    ;; 前のsplashが残っていれば閉じる
    (nano-splash--close)
    (let* ((buffer (get-buffer-create nano-splash--buffer-name))
           (window (progn
                     (with-current-buffer buffer
                       (setq header-line-format nil
                             mode-line-format nil))
                     (display-buffer-same-window buffer nil)))
           (height (1- (window-body-height window)))
           (width (window-body-width window)))
      (with-current-buffer buffer
        (let ((inhibit-read-only t))
          (erase-buffer)
          (setq-local cursor-type nil
                      line-spacing 0
                      vertical-scroll-bar nil
                      horizontal-scroll-bar nil)
          (face-remap-add-relative 'link :underline nil)
          (when nano-splash-center-vertically
            (insert-char ?\n (1+ (/ height 2))))
          (nano-splash--insert-contents width)
          (goto-char (point-min)))
        (read-only-mode 1)
        (use-local-map nano-splash-mode-map))
      (setq nano-splash--timers
            (list (run-with-idle-timer 0.05 nil (lambda () (message nil)))
                  (run-with-idle-timer nano-splash-timeout nil
                                       #'nano-splash-fade-out-slow)))
      (when (and nano-splash-show-help (fboundp 'nano-quick-help))
        (setq nano-splash--help-timer
              (run-with-idle-timer (+ nano-splash-timeout 0.05) nil
                                   #'nano-splash-help-message))))))

(defun nano-splash-kill ()
  "Kill the splash screen buffer (immediately)."
  (interactive)
  ;; クリックは down-mouse-N と mouse-N の2つのイベントで届く。
  ;; down-mouse-N でスプラッシュを閉じると、残りの mouse-N が、
  ;; スプラッシュでの位置のまま次のバッファに届いて
  ;; Args out of range になるので、読み捨てる。
  (when (and (mouse-event-p last-input-event)
             (memq 'down (event-modifiers last-input-event)))
    (read-event nil nil 1))
  (nano-splash--close))

(defun nano-splash-fade-out (&optional duration)
  "Kill the splash screen, fading out the frame for DURATION seconds.
Fading out needs the Mac port (emacs-mac) of Emacs."
  (interactive)
  (when (get-buffer nano-splash--buffer-name)
    (when (and (display-graphic-p) (fboundp 'mac-start-animation))
      (mac-start-animation nil :type 'fade-out :duration (or duration 1.0)))
    ;; 時間で閉じたときは、続けてhelpの案内を出す
    (nano-splash--close t)))

(defun nano-splash-fade-out-slow ()
  "Fade out the splash screen in 1 second."
  (interactive)
  (nano-splash-fade-out 1.00))

(defun nano-splash-fade-out-fast ()
  "Fade out the splash screen in 0.25 seconds."
  (interactive)
  (nano-splash-fade-out 0.25))

;;;###autoload
(defun nano-splash-setup ()
  "Show the splash screen at startup.
Do nothing if -no-splash, --file, --insert or --find-file is on the
command line."
  (unless (seq-some (lambda (option) (member option command-line-args))
                    '("-no-splash" "--file" "--insert" "--find-file"))
    (add-hook 'window-setup-hook #'nano-splash)
    (setq inhibit-startup-screen t
          inhibit-startup-message t
          inhibit-startup-echo-area-message t)))

(provide 'nano-splash)
;;; nano-splash.el ends here
