;;; nano-modeline.el --- N Λ N O header line  -*- lexical-binding: t -*-

;; Copyright (C) 2020 - N Λ N O developers

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

;; mode lineの代わりに、header lineに次の形で情報を出す。
;;
;; [ status | name (primary)                              secondary ]
;;
;; mode lineは、ウィンドウを区切る細い線にする。
;;
;;   (nano-modeline-mode 1)
;;
;; モードごとの表示は、`nano-modeline-renderers'の表で決まる。

;;; Code:

(require 'subr-x)
(require 'face-remap)
(require 'nano-faces)

(defvar Info-current-file)
(defvar Info-current-node)
(defvar Info-breadcrumbs-depth)
(defvar Info-use-header-line)
(defvar org-mode-line-string)
(defvar org-capture-mode)
(declare-function Info-toc-nodes "info" (filename))
(declare-function doc-view-current-page "doc-view" (&optional win))
(declare-function doc-view-last-page-number "doc-view" ())

;;; Parts

(defun nano-modeline--vc-branch ()
  "Return \"#BRANCH\" of the current buffer, or nil."
  (when (and vc-mode buffer-file-name)
    ;; vc-modeは" Git:main"や" Git-main"の形。Emacs 30以降で
    ;; `vc-display-status'がno-backendなら" main"になる。
    (let ((status (string-trim (substring-no-properties vc-mode)))
          (backend (vc-backend buffer-file-name)))
      (when (and backend
                 (string-prefix-p (symbol-name backend) status)
                 (> (length status) (length (symbol-name backend))))
        (setq status (substring status (1+ (length (symbol-name backend))))))
      (concat "#" status))))

(defun nano-modeline--remote-host ()
  "Return \"@host\" when visiting a remote file, or nil."
  (when (and buffer-file-name (file-remote-p buffer-file-name))
    (concat "@" (file-remote-p default-directory 'host))))

(defun nano-modeline--mode-name ()
  "Return `mode-name' as a string.
`mode-name' can be a mode line construct, e.g. in `mhtml-mode'."
  (substring-no-properties (format-mode-line mode-name)))

;; From https://amitp.blogspot.com/2011/08/emacs-custom-mode-line.html
(defun nano-modeline--shorten-directory (dir max-length)
  "Show up to MAX-LENGTH characters of the directory name DIR."
  (let ((path (reverse (split-string (abbreviate-file-name dir) "/")))
        (output ""))
    (when (and path (equal "" (car path)))
      (setq path (cdr path)))
    (while (and path (< (string-width output) (- max-length 4)))
      (setq output (concat (car path) "/" output))
      (setq path (cdr path)))
    (when path
      (setq output (concat "…/" output)))
    output))

(defun nano-modeline-status ()
  "Return the buffer status: modified (**), read-only (RO) or read-write (RW)."
  (cond ((and buffer-file-name (buffer-modified-p)) "**")
        (buffer-read-only "RO")
        (t "RW")))

(defun nano-modeline-compose (status name primary secondary)
  "Compose the header line from STATUS, NAME, PRIMARY and SECONDARY."
  (let* ((char-width (window-font-width nil 'header-line))
         (dedicated (window-dedicated-p))
         (prefix (pcase status
                   ("RO" (propertize (if dedicated " -- " " RO ")
                                     'face 'nano-face-header-popout))
                   ("**" (propertize (if dedicated " -- " " ** ")
                                     'face 'nano-face-header-critical))
                   ("RW" (propertize (if dedicated " -- " " RW ")
                                     'face 'nano-face-header-faded))
                   (_ (propertize status 'face 'nano-face-header-popout))))
         (left (concat
                (propertize " " 'face 'nano-face-header-default
                            'display '(raise +0.15))
                (propertize name 'face 'nano-face-header-strong)
                (propertize " " 'face 'nano-face-header-default
                            'display '(raise -0.20))
                (propertize primary 'face 'nano-face-header-default)))
         (right (concat secondary " "))
         ;; 日本語などの全角文字があっても揃うように、文字数ではなく
         ;; `string-width'で数える。
         (available-width (max 1 (- (window-total-width)
                                    (string-width prefix)
                                    (string-width left)
                                    (string-width right)
                                    (/ (window-right-divider-width) char-width)))))
    (concat prefix
            left
            (propertize (make-string available-width ?\s)
                        'face 'nano-face-header-default)
            (propertize right 'face `(:inherit nano-face-header-default
                                      :foreground ,(face-foreground 'nano-face-faded nil t))))))

;;; Renderers

(defun nano-modeline--buffer (&optional secondary)
  "Show the buffer name, (mode, branch) and SECONDARY (the position by default)."
  (let ((branch (nano-modeline--vc-branch))
        (host (nano-modeline--remote-host)))
    (nano-modeline-compose (nano-modeline-status)
                           (format-mode-line "%b")
                           (concat "(" (nano-modeline--mode-name)
                                   (when branch
                                     (concat ", " (propertize branch 'face 'italic)))
                                   ")"
                                   (when host
                                     (concat " " (propertize host 'face 'italic))))
                           (or secondary (format-mode-line "%l:%c")))))

(defun nano-modeline--org-clock-p ()
  "Return non-nil when an org clock is running."
  (and (stringp (bound-and-true-p org-mode-line-string))
       (not (string-empty-p org-mode-line-string))))

(defun nano-modeline--org-clock ()
  "Show the buffer with the running org clock."
  (nano-modeline--buffer org-mode-line-string))

(defun nano-modeline--docview ()
  "Show the buffer with the page number."
  (nano-modeline--buffer
   (format "%s/%s" (doc-view-current-page)
           (or (ignore-errors (doc-view-last-page-number)) "???"))))

(defun nano-modeline--completion-list ()
  "Show the completion list."
  (nano-modeline-compose (nano-modeline-status)
                         (format-mode-line "%b") "" (format-mode-line "%l:%c")))

(defun nano-modeline--info-breadcrumbs ()
  "Return the breadcrumbs of the current Info node."
  (let ((nodes (Info-toc-nodes Info-current-file))
        (node Info-current-node)
        (crumbs ())
        (depth Info-breadcrumbs-depth)
        line)
    (while (> depth 0)
      (setq node (nth 1 (assoc node nodes)))
      (when node (push node crumbs))
      (setq depth (1- depth)))
    (setq crumbs (cons "Top" (if (member (pop crumbs) '(nil "Top"))
                                 crumbs
                               (cons nil crumbs))))
    (dolist (node crumbs)
      (let ((text (if (not (equal node "Top"))
                      node
                    (format "%s" (if (stringp Info-current-file)
                                     (file-name-sans-extension
                                      (file-name-nondirectory Info-current-file))
                                   Info-current-file)))))
        (setq line (concat line (if (null line) "" " > ")
                           (if (null node) "..." text)))))
    (when (and Info-current-node (not (equal Info-current-node "Top")))
      (setq line (concat line (if (null line) "" " > ") Info-current-node)))
    line))

(defun nano-modeline--info ()
  "Show the Info breadcrumbs."
  (nano-modeline-compose (nano-modeline-status) "Info"
                         (concat "(" (nano-modeline--info-breadcrumbs) ")") ""))

(defun nano-modeline--org-capture-p ()
  "Return non-nil in an org capture buffer."
  (bound-and-true-p org-capture-mode))

(defun nano-modeline--org-capture ()
  "Show the org capture buffer."
  (nano-modeline-compose (nano-modeline-status) "Capture" "(org)" ""))

(defun nano-modeline--org-agenda ()
  "Show the org agenda with the date."
  (nano-modeline-compose (nano-modeline-status) "Agenda" ""
                         (format-time-string "%A %-e %B %Y")))

(defun nano-modeline--term ()
  "Show the terminal with the shell and the directory."
  (nano-modeline-compose " >_ " "Terminal"
                         (concat "(" shell-file-name ")")
                         (nano-modeline--shorten-directory default-directory 32)))

(defun nano-modeline--message ()
  "Show the message draft."
  (nano-modeline-compose (nano-modeline-status) "Message" "(draft)" ""))

(defun nano-modeline--nano-help ()
  "Show the nano help."
  (nano-modeline-compose (nano-modeline-status) "GNU Emacs / N Λ N O" "(help)" ""))

(defun nano-modeline--calendar ()
  "Show nothing (the calendar has only an overline)."
  "")

(defvar nano-modeline-renderers
  '(((prog-mode)            . nano-modeline--buffer)
    ((nano-help-mode)       . nano-modeline--nano-help)
    ((message-mode)         . nano-modeline--message)
    ((Info-mode)            . nano-modeline--info)
    ((calendar-mode)        . nano-modeline--calendar)
    (nano-modeline--org-capture-p . nano-modeline--org-capture)
    ((org-agenda-mode)      . nano-modeline--org-agenda)
    (nano-modeline--org-clock-p   . nano-modeline--org-clock)
    ((term-mode vterm-mode) . nano-modeline--term)
    ((text-mode)            . nano-modeline--buffer)
    ((doc-view-mode)        . nano-modeline--docview)
    ((completion-list-mode) . nano-modeline--completion-list))
  "Alist of (CONDITION . RENDERER) for the header line.
CONDITION is a list of major modes (see `derived-mode-p') or a
predicate.  The RENDERER of the first matching CONDITION returns
the header line; `nano-modeline--buffer' if nothing matches.")

(defun nano-modeline--render ()
  "Return the header line of the current buffer."
  (funcall (or (cdr (seq-find (lambda (entry)
                                (let ((condition (car entry)))
                                  (if (listp condition)
                                      (apply #'derived-mode-p condition)
                                    (funcall condition))))
                              nano-modeline-renderers))
               #'nano-modeline--buffer)))

;;; Other modes

(defun nano-modeline--calendar-header ()
  "Show only an overline instead of the header line in the calendar."
  (setq header-line-format "")
  (face-remap-add-relative 'header-line
                           `(:overline ,(face-foreground 'default)
                             :height 0.5
                             :background ,(face-background 'default))))

(defun nano-modeline--org-capture-header ()
  "Use the nano header line instead of the one of org capture."
  (setq-local header-line-format (default-value 'header-line-format)))

(defun nano-modeline--buffer-menu ()
  "Give the column header of the buffer menu a background."
  (face-remap-add-relative 'header-line
                           `(:background ,(face-background 'nano-face-subtle nil t))))

(defun nano-modeline-update-windows ()
  "Show the mode line (a thin line) only above another window."
  (dolist (window (window-list))
    (with-current-buffer (window-buffer window)
      (set-window-parameter
       window 'mode-line-format
       (cond ((not mode-line-format) 'none)
             ((one-window-p t 'visible) (list ""))
             ((eq (window-in-direction 'below window) (minibuffer-window)) (list ""))
             ((not (window-in-direction 'below window)) (list ""))
             (t 'none))))))

;;; Minor mode

(defvar nano-modeline--saved nil
  "Alist of the values before `nano-modeline-mode' was turned on.")

(defconst nano-modeline--header-line-format '((:eval (nano-modeline--render)))
  "The `header-line-format' of `nano-modeline-mode'.")

(defconst nano-modeline--hooks
  '((window-configuration-change-hook . nano-modeline-update-windows)
    (calendar-initial-window-hook . nano-modeline--calendar-header)
    (org-capture-mode-hook . nano-modeline--org-capture-header)
    (Buffer-menu-mode-hook . nano-modeline--buffer-menu))
  "Hooks used by `nano-modeline-mode'.")

;;;###autoload
(define-minor-mode nano-modeline-mode
  "Show the nano header line instead of the mode line."
  :global t
  :group 'nano
  (if nano-modeline-mode
      (progn
        (unless nano-modeline--saved
          (setq nano-modeline--saved
                `((header-line-format . ,(default-value 'header-line-format))
                  (mode-line-format . ,(default-value 'mode-line-format))
                  (Info-use-header-line
                   . ,(if (boundp 'Info-use-header-line) Info-use-header-line t)))))
        (setq-default header-line-format nano-modeline--header-line-format)
        ;; 空のmode-line-formatだと、うまく動かないモードがある
        ;; （YaTeXの環境の補完など）ので、幅のない空白にする。
        (setq-default mode-line-format "​")
        (setq Info-use-header-line nil)
        (pcase-dolist (`(,hook . ,fn) nano-modeline--hooks)
          (add-hook hook fn))
        (nano-modeline-update-windows))
    (pcase-dolist (`(,hook . ,fn) nano-modeline--hooks)
      (remove-hook hook fn))
    (when nano-modeline--saved
      (setq-default header-line-format
                    (alist-get 'header-line-format nano-modeline--saved))
      (setq-default mode-line-format
                    (alist-get 'mode-line-format nano-modeline--saved))
      (setq Info-use-header-line
            (alist-get 'Info-use-header-line nano-modeline--saved))
      (setq nano-modeline--saved nil))
    (dolist (window (window-list-1 nil t t))
      (set-window-parameter window 'mode-line-format nil)))
  (force-mode-line-update t))

(provide 'nano-modeline)
;;; nano-modeline.el ends here
