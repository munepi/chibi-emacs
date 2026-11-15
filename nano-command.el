;;; nano-command.el --- N Λ N O header line command prompt  -*- lexical-binding: t -*-

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

;; An experimental header command prompt for entering non intrusive
;; short text, without auto-completion nor history.  The command
;; prompt is displayed using the header line and the content is
;; copied from a tiny one line window at the bottom of this window.
;; It takes care of setting the text to white and hiding the cursor
;; such that it is mostly invisible.
;;
;; キーは割り当てないので、好みで割り当てる。
;;
;;   (global-set-key (kbd "M-s-x") #'nano-command-x)
;;   (global-set-key (kbd "M-s-s") #'nano-command-shell)

;;; Code:

(require 'face-remap)
(require 'nano-faces)

(define-minor-mode nano-command-mode
  "Nano command mode"
  :keymap  (make-sparse-keymap))

(defvar nano-command--slave nil
  "Slave buffer displaying the command.")

(defvar nano-command--master "*nano-command*"
  "Master buffer recording keystrokes.")

(defvar nano-command--cookie nil
  "Cookie returned by face-remap-add-relative.")

(defun nano-command--update ()
  "This function makes sure the content of the master buffer is copied
to the slave buffer header line and cursor stays on first line."

  ;; Makes sure cursor stays on first line
  (with-current-buffer nano-command--master
   (let ((eol (save-excursion (goto-char (point-min)) (line-end-position))))
    (if (> (point) eol) (goto-char eol))))
  
  ;; Update slave header line
  (with-current-buffer nano-command--slave
    (force-mode-line-update nil)))


(defun nano-command--check-focus (&rest _args)
  "This function check if the maste buffer has focus.
If not, it closes nano command."

  (if (not (eq (selected-window)
               (get-buffer-window nano-command--master)))
      (nano-command--close)))
  
(defun nano-command--close ()
  "Close nano command"

  (interactive)
  
  ;; Remove advice
  (advice-remove #'select-window #'nano-command--check-focus)
  
  ;; Close master window
  (when (window-live-p (get-buffer-window nano-command--master))
    (delete-window (get-buffer-window nano-command--master)))

  ;; Kill master buffer
  (when (get-buffer nano-command--master)
    (kill-buffer nano-command--master))

  ;; Restore slave to normal state
  (with-selected-window (get-buffer-window nano-command--slave)
    (kill-local-variable 'header-line-format)
    (face-remap-remove-relative nano-command--cookie))
  
  ;; Update mode lines
  (force-mode-line-update t))


(defun nano-command (&optional prompt callback content information)
  "Read a line of text in the header line with PROMPT.
CONTENT is the initial text and INFORMATION is shown while the text
is empty.  When the text is entered, call CALLBACK with it, or show
it with `message' if CALLBACK is nil."

  ;; Cannot open nano command while in minibuffer
  (when (minibufferp)
    (error "Cannot open nano command while in minibuffer"))

  ;; Cannot open nano command while in nano command
  (when (eq (current-buffer) (get-buffer nano-command--master))
    (error "Cannot open nano command while in mini command"))
  
  ;; Kill the master buffer & window if openened (not strictly necessary)
  (when (window-live-p (get-buffer-window nano-command--master))
    (delete-window (get-buffer-window nano-command--master))
    (kill-buffer nano-command--master))

  ;; Save the slave buffer
  (setq nano-command--slave (current-buffer))

  ;; Install nano face command in the slave buffer
  (setq nano-command--cookie
        (face-remap-add-relative 'header-line 'nano-face-command))

  ;; Create master buffer by splitting slave buffer
  (let ((window-min-height 1)
        (window-safe-min-height 1)
        (window-resize-pixelwise t)
        (split-window-keep-point t))
    (with-selected-window (split-window-vertically -2)
      (switch-to-buffer (get-buffer-create nano-command--master))
      (erase-buffer)
      (org-mode)
      (nano-command-mode)
      (if content (insert content))
      (insert "\n")
      (insert "-")

      ;; This tries to hide most of the master window
      (goto-char (point-min))
      (overlay-put (make-overlay (line-beginning-position) (+ (line-end-position) 1))
                   'face '(:height 10))
     (setq cursor-type nil)
      
      (setq header-line-format nil)
      (setq mode-line-format nil)
      (face-remap-add-relative 'default `(:foreground ,nano-color-background))
      (face-remap-add-relative 'region  `(:background ,nano-color-background))
      (fit-window-to-buffer)
      (setq window-size-fixed t)

      ;; History
      ;; (goto-char (point-max))
      ;; (insert "history-item-1 history-item-2 history-item-3")  
      ;; (goto-char (point-min))
      ))


  ;; Install header line in master buffer
  (setq header-line-format
        (list

         ;; Prompt + one space
         (propertize " "  'face 'nano-face-command-prompt
		          'display `(raise -0.20))
         (propertize (or prompt "M-x") 'face 'nano-face-command-prompt)
         (propertize " "  'face 'nano-face-command-prompt
	  	          'display `(raise +0.15))
         (propertize " " )

         ;; Input (copied from master). we need to add a space at end
         ;; of content to be able to show cursor when it is at the end
         ;; of the line.
         `(:eval
           (let* ((content (with-current-buffer nano-command--master
                             (save-excursion (goto-char (point-min))
                               (buffer-substring (line-beginning-position) (line-end-position)))))
                  (content (cond ((> (length content) 0)
                                  (concat content " "))
                                 ((> (length ,information) 0) 
                                  (propertize ,information 'face 'nano-face-faded))
                                 (t " ")))
                  (point  (with-current-buffer nano-command--master (point)))
                  (region (with-current-buffer nano-command--master (region-active-p))))

             ;; Cursor 
             (put-text-property (- point 1) point
                                'face 'nano-face-command-cursor content)
             ;; Region
             (if region
                 (let ((beg (with-current-buffer nano-command--master (region-beginning)))
                       (end (with-current-buffer nano-command--master (region-end))))
                   (put-text-property (- beg 1) (- end 1)
                                      'face `(:foreground ,nano-color-background
                                              :background ,nano-color-faded) content)))
             content))))

  ;; Install key bindings
  (with-current-buffer nano-command--master
    (add-hook 'post-command-hook 'nano-command--update nil t)
    (define-key nano-command-mode-map (kbd "C-g") #'nano-command--close)
    (define-key nano-command-mode-map (kbd "<tab>")
      (lambda () (interactive) (dabbrev-expand nil)))
      
    (define-key nano-command-mode-map (kbd "<return>")
      (lambda ()
        (interactive)
        (let* ((content (with-current-buffer nano-command--master
                          (save-excursion (goto-char (point-min))
                          (buffer-substring (line-beginning-position) (line-end-position))))))
          (nano-command--close)
          (if callback (funcall callback content)
            (message content))))))

  ;; Update mode lines and swicch to master buffer
  (nano-command--update)
  (select-window (get-buffer-window nano-command--master) t)
  (redisplay)
  
  ;; Advice after select window to check for focus
  (advice-add #'select-window :after #'nano-command--check-focus))

(defun nano-command-x ()
  "Run a command entered in the header line."
  (interactive)
  (nano-command "M-x" #'nano-command-x-finalize "" "Enter command"))

(defun nano-command-x-finalize (command)
  "Run COMMAND, the name of a command."
  (let ((symbol (intern-soft command)))
    (if (commandp symbol)
        (command-execute symbol 'record)
      (user-error "No such command: %s" command))))

(defun nano-command-shell ()
  "Run a shell command entered in the header line."
  (interactive)
  (nano-command ">_" #'nano-command-shell-finalize
                "" "Enter shell command"))

(defun nano-command-shell-finalize (command)
  "Run the shell COMMAND and show its output."
  (shell-command command)
  (when (get-buffer "*Shell Command Output*")
    (switch-to-buffer "*Shell Command Output*")))

(provide 'nano-command)
;;; nano-command.el ends here
