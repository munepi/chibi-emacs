;;; chibi-modeline.el --- chibi header line  -*- lexical-binding: t -*-

;; Copyright (C) 2020 - N Λ N O developers
;; Copyright (C) 2026 Munehiro Yamamoto

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
;;   (chibi-modeline-mode 1)
;;
;; モードごとの表示は、`chibi-modeline-renderers'の表で決まる。

;;; Code:

(require 'subr-x)
(require 'face-remap)
(require 'chibi-faces)

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

(defun chibi-modeline--vc-branch ()
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

(defun chibi-modeline--remote-host ()
  "Return \"@host\" when visiting a remote file, or nil."
  (when (and buffer-file-name (file-remote-p buffer-file-name))
    (concat "@" (file-remote-p default-directory 'host))))

(defun chibi-modeline--mode-name ()
  "Return `mode-name' as a string.
`mode-name' can be a mode line construct, e.g. in `mhtml-mode'."
  (substring-no-properties (format-mode-line mode-name)))

;; From https://amitp.blogspot.com/2011/08/emacs-custom-mode-line.html
(defun chibi-modeline--shorten-directory (dir max-length)
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

(defun chibi-modeline-status ()
  "Return the buffer status: modified (**), read-only (RO) or read-write (RW)."
  (cond ((and buffer-file-name (buffer-modified-p)) "**")
        (buffer-read-only "RO")
        (t "RW")))

(defun chibi-modeline-compose (status name primary secondary)
  "Compose the header line from STATUS, NAME, PRIMARY and SECONDARY."
  (let* ((char-width (window-font-width nil 'header-line))
         (dedicated (window-dedicated-p))
         (prefix (pcase status
                   ("RO" (propertize (if dedicated " -- " " RO ")
                                     'face 'chibi-face-header-popout))
                   ("**" (propertize (if dedicated " -- " " ** ")
                                     'face 'chibi-face-header-critical))
                   ("RW" (propertize (if dedicated " -- " " RW ")
                                     'face 'chibi-face-header-faded))
                   (_ (propertize status 'face 'chibi-face-header-popout))))
         (left (concat
                (propertize " " 'face 'chibi-face-header-default
                            'display '(raise +0.15))
                (propertize name 'face 'chibi-face-header-strong)
                (propertize " " 'face 'chibi-face-header-default
                            'display '(raise -0.20))
                (propertize primary 'face 'chibi-face-header-default)))
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
                        'face 'chibi-face-header-default)
            (propertize right 'face `(:inherit chibi-face-header-default
                                      :foreground ,(face-foreground 'chibi-face-faded nil t))))))

;;; Renderers

(defun chibi-modeline--buffer (&optional secondary)
  "Show the buffer name, (mode, branch) and SECONDARY (the position by default)."
  (let ((branch (chibi-modeline--vc-branch))
        (host (chibi-modeline--remote-host)))
    (chibi-modeline-compose (chibi-modeline-status)
                           (format-mode-line "%b")
                           (concat "(" (chibi-modeline--mode-name)
                                   (when branch
                                     (concat ", " (propertize branch 'face 'italic)))
                                   ")"
                                   (when host
                                     (concat " " (propertize host 'face 'italic))))
                           (or secondary (format-mode-line "%l:%c")))))

(defun chibi-modeline--org-clock-p ()
  "Return non-nil when an org clock is running."
  (and (stringp (bound-and-true-p org-mode-line-string))
       (not (string-empty-p org-mode-line-string))))

(defun chibi-modeline--org-clock ()
  "Show the buffer with the running org clock."
  (chibi-modeline--buffer org-mode-line-string))

(defun chibi-modeline--docview ()
  "Show the buffer with the page number."
  (chibi-modeline--buffer
   (format "%s/%s" (doc-view-current-page)
           (or (ignore-errors (doc-view-last-page-number)) "???"))))

(defun chibi-modeline--completion-list ()
  "Show the completion list."
  (chibi-modeline-compose (chibi-modeline-status)
                         (format-mode-line "%b") "" (format-mode-line "%l:%c")))

(defun chibi-modeline--info-breadcrumbs ()
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

(defun chibi-modeline--info ()
  "Show the Info breadcrumbs."
  (chibi-modeline-compose (chibi-modeline-status) "Info"
                         (concat "(" (chibi-modeline--info-breadcrumbs) ")") ""))

(defun chibi-modeline--org-capture-p ()
  "Return non-nil in an org capture buffer."
  (bound-and-true-p org-capture-mode))

(defun chibi-modeline--org-capture ()
  "Show the org capture buffer."
  (chibi-modeline-compose (chibi-modeline-status) "Capture" "(org)" ""))

(defun chibi-modeline--org-agenda ()
  "Show the org agenda with the date."
  (chibi-modeline-compose (chibi-modeline-status) "Agenda" ""
                         (format-time-string "%A %-e %B %Y")))

(defun chibi-modeline--term ()
  "Show the terminal with the shell and the directory."
  (chibi-modeline-compose " >_ " "Terminal"
                         (concat "(" shell-file-name ")")
                         (chibi-modeline--shorten-directory default-directory 32)))

(defun chibi-modeline--message ()
  "Show the message draft."
  (chibi-modeline-compose (chibi-modeline-status) "Message" "(draft)" ""))

(defun chibi-modeline--help ()
  "Show the chibi help."
  (chibi-modeline-compose (chibi-modeline-status) "GNU Emacs / chibi" "(help)" ""))

(defun chibi-modeline--calendar ()
  "Show nothing (the calendar has only an overline)."
  "")

(defvar chibi-modeline-renderers
  '(((prog-mode)            . chibi-modeline--buffer)
    ((chibi-help-mode)      . chibi-modeline--help)
    ((message-mode)         . chibi-modeline--message)
    ((Info-mode)            . chibi-modeline--info)
    ((calendar-mode)        . chibi-modeline--calendar)
    (chibi-modeline--org-capture-p . chibi-modeline--org-capture)
    ((org-agenda-mode)      . chibi-modeline--org-agenda)
    (chibi-modeline--org-clock-p   . chibi-modeline--org-clock)
    ((term-mode vterm-mode) . chibi-modeline--term)
    ((text-mode)            . chibi-modeline--buffer)
    ((doc-view-mode)        . chibi-modeline--docview)
    ((completion-list-mode) . chibi-modeline--completion-list))
  "Alist of (CONDITION . RENDERER) for the header line.
CONDITION is a list of major modes (see `derived-mode-p') or a
predicate.  The RENDERER of the first matching CONDITION returns
the header line; `chibi-modeline--buffer' if nothing matches.")

(defun chibi-modeline--render ()
  "Return the header line of the current buffer."
  (funcall (or (cdr (seq-find (lambda (entry)
                                (let ((condition (car entry)))
                                  (if (listp condition)
                                      (apply #'derived-mode-p condition)
                                    (funcall condition))))
                              chibi-modeline-renderers))
               #'chibi-modeline--buffer)))

;;; Other modes

(defun chibi-modeline--calendar-header ()
  "Show only an overline instead of the header line in the calendar."
  (setq header-line-format "")
  (face-remap-add-relative 'header-line
                           `(:overline ,(face-foreground 'default)
                             :height 0.5
                             :background ,(face-background 'default))))

(defun chibi-modeline--org-capture-header ()
  "Use the chibi header line instead of the one of org capture."
  (setq-local header-line-format (default-value 'header-line-format)))

(defun chibi-modeline--buffer-menu ()
  "Give the column header of the buffer menu a background."
  (face-remap-add-relative 'header-line
                           `(:background ,(face-background 'chibi-face-subtle nil t))))

(defun chibi-modeline-update-windows ()
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

(defvar chibi-modeline--saved nil
  "Alist of the values before `chibi-modeline-mode' was turned on.")

(defconst chibi-modeline--header-line-format '((:eval (chibi-modeline--render)))
  "The `header-line-format' of `chibi-modeline-mode'.")

(defconst chibi-modeline--hooks
  '((window-configuration-change-hook . chibi-modeline-update-windows)
    (calendar-initial-window-hook . chibi-modeline--calendar-header)
    (org-capture-mode-hook . chibi-modeline--org-capture-header)
    (Buffer-menu-mode-hook . chibi-modeline--buffer-menu))
  "Hooks used by `chibi-modeline-mode'.")

;;;###autoload
(define-minor-mode chibi-modeline-mode
  "Show the chibi header line instead of the mode line."
  :global t
  :group 'chibi
  (if chibi-modeline-mode
      (progn
        (unless chibi-modeline--saved
          (setq chibi-modeline--saved
                `((header-line-format . ,(default-value 'header-line-format))
                  (mode-line-format . ,(default-value 'mode-line-format))
                  (Info-use-header-line
                   . ,(if (boundp 'Info-use-header-line) Info-use-header-line t)))))
        (setq-default header-line-format chibi-modeline--header-line-format)
        ;; 空のmode-line-formatだと、うまく動かないモードがある
        ;; （YaTeXの環境の補完など）ので、幅のない空白にする。
        (setq-default mode-line-format "​")
        (setq Info-use-header-line nil)
        (pcase-dolist (`(,hook . ,fn) chibi-modeline--hooks)
          (add-hook hook fn))
        (chibi-modeline-update-windows))
    (pcase-dolist (`(,hook . ,fn) chibi-modeline--hooks)
      (remove-hook hook fn))
    (when chibi-modeline--saved
      (setq-default header-line-format
                    (alist-get 'header-line-format chibi-modeline--saved))
      (setq-default mode-line-format
                    (alist-get 'mode-line-format chibi-modeline--saved))
      (setq Info-use-header-line
            (alist-get 'Info-use-header-line chibi-modeline--saved))
      (setq chibi-modeline--saved nil))
    (dolist (window (window-list-1 nil t t))
      (set-window-parameter window 'mode-line-format nil)))
  (force-mode-line-update t))

(provide 'chibi-modeline)
;;; chibi-modeline.el ends here
