;;; nano-theme.el --- Palettes and face assignments of N Λ N O  -*- lexical-binding: t -*-

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

;; 配色（`nano-theme-palettes'）と、Emacsや各packageのfaceを
;; nanoの基本のfaceに割り当てる処理。
;;
;;   (nano-theme-set 'vscmacs)   ; 配色を選ぶ（`nano-color-*'を設定する）
;;   (nano-refresh-theme)        ; faceに反映する
;;
;; packageのfaceは、そのpackageが読み込まれたときに割り当てる
;; （`nano-theme-faces'）。
;;
;; 例外：
;; - `hl-line'は、`nano-color-highlight'を背景にする。
;; - termの色は、Material designの色を使う。
;; - 配色に:font-lockがあれば、構文のfaceにその色を付ける（vscmacs）。

;;; Code:

(require 'nano-faces)
(require 'face-remap)

;;; Palettes

(defcustom nano-theme-palettes
  '((light
     ;; Colors from Material design at https://material.io/
     :mode light
     :foreground "#37474F"              ; Blue Grey / L800
     :background "#FFFFFF"              ; White
     :highlight  "#FAFAFA"              ; Very Light Grey
     :critical   "#FF6F00"              ; Amber / L900
     :salient    "#673AB7"              ; Deep Purple / L500
     :strong     "#000000"              ; Black
     :popout     "#FFAB91"              ; Deep Orange / L200
     :subtle     "#ECEFF1"              ; Blue Grey / L50
     :faded      "#B0BEC5")             ; Blue Grey / L200
    (dark
     ;; Colors from Nord theme at https://www.nordtheme.com
     :mode dark
     :foreground "#ECEFF4"              ; Snow Storm 3  / nord  6
     :background "#2E3440"              ; Polar Night 0 / nord  0
     :highlight  "#3B4252"              ; Polar Night 1 / nord  1
     :critical   "#EBCB8B"              ; Aurora        / nord 11
     :salient    "#81A1C1"              ; Frost         / nord  9
     :strong     "#ECEFF4"              ; Snow Storm 3  / nord  6
     :popout     "#D08770"              ; Aurora        / nord 12
     :subtle     "#434C5E"              ; Polar Night 2 / nord  2
     :faded      "#677691")
    (vscmacs
     ;; Visual Studio Code Dark Modern
     ;; (extensions/theme-defaults/themes/dark_modern.json).
     ;; Dark ModernはDark+を含むので、構文色はDark+のもの。
     :mode dark
     :foreground "#CCCCCC"              ; editor.foreground
     :background "#1F1F1F"              ; editor.background
     :highlight  "#2B2B2B"              ; panel.border
     :critical   "#F85149"              ; errorForeground
     :salient    "#569CD6"              ; Dark+ keyword blue
     :strong     "#FFFFFF"              ; tab.activeForeground
     :popout     "#CE9178"              ; Dark+ string orange
     :subtle     "#3C3C3C"              ; input.border
     :faded      "#9D9D9D"              ; descriptionForeground
     ;; ステータスバーはエディタの背景より暗い。subtleはregionなどにも
     ;; 使うので、header lineの背景だけを変える。
     :header-background "#181818"       ; statusBar.background
     :border     "#2B2B2B"              ; statusBar.border
     :font-lock
     ((font-lock-comment-face        . "#6A9955")
      (font-lock-doc-face            . "#CE9178")
      (font-lock-string-face         . "#CE9178")
      (font-lock-keyword-face        . "#569CD6")
      (font-lock-builtin-face        . "#C586C0")
      (font-lock-preprocessor-face   . "#C586C0")
      (font-lock-constant-face       . "#569CD6")
      (font-lock-negation-char-face  . "#569CD6")
      (font-lock-function-name-face  . "#DCDCAA")
      (font-lock-type-face           . "#4EC9B0")
      (font-lock-variable-name-face  . "#9CDCFE")
      (font-lock-number-face         . "#B5CEA8")
      (font-lock-function-call-face  . "#DCDCAA")
      (font-lock-variable-use-face   . "#9CDCFE")
      (font-lock-property-name-face  . "#9CDCFE")
      (font-lock-property-use-face   . "#9CDCFE")
      (font-lock-escape-face         . "#D7BA7D")
      (font-lock-regexp-face         . "#D16969")
      (font-lock-regexp-grouping-backslash . "#D7BA7D")
      (font-lock-regexp-grouping-construct . "#D7BA7D"))))
  "Alist of (NAME . PLIST) of the nano palettes.
PLIST has the 9 colors (:foreground, :background, :highlight,
:critical, :salient, :strong, :popout, :subtle, :faded) and :mode,
which is `light' or `dark'.  Optionally:
  :header-background  background of the header line
  :border             color of the window separators
  :font-lock          alist of (FACE . COLOR) for the syntax faces"
  :group 'nano
  :type '(alist :key-type symbol :value-type plist))

(defvar nano-theme-current nil
  "Name of the palette set by `nano-theme-set', or nil.")

(defvar nano-theme-font-lock-colors nil
  "Alist of (FACE . COLOR) of the current palette, set by `nano-theme-set'.")

(defvar nano-theme--last-dark 'dark
  "The dark palette used last, for `nano-toggle-theme'.")

(defcustom nano-theme-hook nil
  "Hook run at the end of `nano-theme'."
  :group 'nano
  :type 'hook)

(defun nano-theme-set (name)
  "Set the `nano-color-*' values to the palette NAME.
NAME is a key of `nano-theme-palettes'.  Interactively, also
refresh the faces."
  (interactive
   (list (intern (completing-read "Palette: " nano-theme-palettes nil t))))
  (let ((palette (or (alist-get name nano-theme-palettes)
                     (error "No such nano palette: %s" name))))
    (dolist (key '(foreground background highlight critical salient
                   strong popout subtle faded))
      (set (intern (format "nano-color-%s" key))
           (plist-get palette (intern (format ":%s" key)))))
    (setq nano-color-header-background (plist-get palette :header-background)
          nano-color-border (plist-get palette :border)
          nano-theme-font-lock-colors (plist-get palette :font-lock)
          frame-background-mode (plist-get palette :mode)
          nano-theme-current name)
    (when (eq frame-background-mode 'dark)
      (setq nano-theme--last-dark name)))
  (when (called-interactively-p 'any)
    (nano-refresh-theme)))

(defun nano-theme-set-light ()
  "Set the light palette (Material)."
  (nano-theme-set 'light))

(defun nano-theme-set-dark ()
  "Set the dark palette (Nord)."
  (nano-theme-set 'dark))

(defun nano-theme-set-vscmacs ()
  "Set the vscmacs palette (VS Code Dark Modern)."
  (nano-theme-set 'vscmacs))

;;; Face assignments

(defun nano-theme--set-face (face style)
  "Reset FACE and make it inherit STYLE.  Do nothing if FACE is undefined."
  (when (facep face)
    (set-face-attribute face nil
                        :foreground 'unspecified :background 'unspecified
                        :family     'unspecified :slant      'unspecified
                        :weight     'unspecified :height     'unspecified
                        :underline  'unspecified :overline   'unspecified
                        :box        'unspecified :inherit    style)))

(defconst nano-theme-faces
  '((nil
     ;; Structural
     (bold                         . nano-face-strong)
     (italic                       . nano-face-faded)
     (bold-italic                  . nano-face-strong)
     (region                       . nano-face-subtle)
     (highlight                    . nano-face-subtle)
     (fixed-pitch-serif            . nano-face-default)
     (cursor                       . nano-face-default)
     ;; Semantic
     (shadow                       . nano-face-faded)
     (success                      . nano-face-salient)
     (warning                      . nano-face-popout)
     (error                        . nano-face-critical)
     (match                        . nano-face-popout)
     ;; General
     (buffer-menu-buffer           . nano-face-strong)
     (minibuffer-prompt            . nano-face-strong)
     (link                         . nano-face-salient)
     (fringe                       . nano-face-faded)
     (isearch                      . nano-face-strong)
     (isearch-fail                 . nano-face-faded)
     (lazy-highlight               . nano-face-subtle)
     (trailing-whitespace          . nano-face-subtle)
     (show-paren-match             . nano-face-popout)
     (show-paren-mismatch          . nano-face-critical)
     (secondary-selection          . nano-face-subtle)
     (completions-common-part      . nano-face-faded)
     (completions-first-difference . nano-face-default)
     ;; Font lock
     (font-lock-comment-face       . nano-face-faded)
     (font-lock-doc-face           . nano-face-faded)
     (font-lock-string-face        . nano-face-popout)
     (font-lock-constant-face      . nano-face-salient)
     (font-lock-warning-face       . nano-face-popout)
     (font-lock-function-name-face . nano-face-strong)
     (font-lock-variable-name-face . nano-face-strong)
     (font-lock-builtin-face       . nano-face-salient)
     (font-lock-type-face          . nano-face-salient)
     (font-lock-keyword-face       . nano-face-salient))
    (info
     (info-menu-header             . nano-face-strong)
     (info-header-node             . nano-face-default)
     (info-index-match             . nano-face-salient)
     (Info-quoted                  . nano-face-faded)
     (info-title-1                 . nano-face-strong)
     (info-title-2                 . nano-face-strong)
     (info-title-3                 . nano-face-strong)
     (info-title-4                 . nano-face-strong))
    (bookmark
     (bookmark-menu-bookmark       . nano-face-salient))
    (message
     (message-cited-text           . nano-face-faded)
     (message-cited-text-1         . nano-face-faded)
     (message-cited-text-2         . nano-face-faded)
     (message-cited-text-3         . nano-face-faded)
     (message-cited-text-4         . nano-face-faded)
     (message-header-cc            . nano-face-default)
     (message-header-name          . nano-face-strong)
     (message-header-newsgroups    . nano-face-default)
     (message-header-other         . nano-face-default)
     (message-header-subject       . nano-face-salient)
     (message-header-to            . nano-face-salient)
     (message-header-xheader       . nano-face-default)
     (message-mml                  . nano-face-popout)
     (message-separator            . nano-face-faded))
    (outline
     (outline-1                    . nano-face-strong)
     (outline-2                    . nano-face-strong)
     (outline-3                    . nano-face-strong)
     (outline-4                    . nano-face-strong)
     (outline-5                    . nano-face-strong)
     (outline-6                    . nano-face-strong)
     (outline-7                    . nano-face-strong)
     (outline-8                    . nano-face-strong))
    (cus-edit
     (widget-field                 . nano-face-subtle)
     (widget-button                . nano-face-strong)
     (widget-single-line-field     . nano-face-subtle)
     (custom-group-subtitle        . nano-face-strong)
     (custom-group-tag             . nano-face-strong)
     (custom-group-tag-1           . nano-face-strong)
     (custom-comment               . nano-face-faded)
     (custom-comment-tag           . nano-face-faded)
     (custom-changed               . nano-face-salient)
     (custom-modified              . nano-face-salient)
     (custom-face-tag              . nano-face-strong)
     (custom-variable-tag          . nano-face-strong)
     (custom-invalid               . nano-face-popout)
     (custom-visibility            . nano-face-salient)
     (custom-state                 . nano-face-salient)
     (custom-link                  . nano-face-salient))
    (package
     (package-description          . nano-face-default)
     (package-help-section-name    . nano-face-default)
     (package-name                 . nano-face-salient)
     (package-status-avail-obso    . nano-face-faded)
     (package-status-available     . nano-face-default)
     (package-status-built-in      . nano-face-salient)
     (package-status-dependency    . nano-face-salient)
     (package-status-disabled      . nano-face-faded)
     (package-status-external      . nano-face-default)
     (package-status-held          . nano-face-default)
     (package-status-incompat      . nano-face-faded)
     (package-status-installed     . nano-face-salient)
     (package-status-new           . nano-face-default)
     (package-status-unsigned      . nano-face-default))
    (flyspell
     (flyspell-duplicate           . nano-face-popout)
     (flyspell-incorrect           . nano-face-popout))
    (diff-mode
     (diff-header                  . nano-face-faded)
     (diff-file-header             . nano-face-strong)
     (diff-context                 . nano-face-default)
     (diff-removed                 . nano-face-faded)
     (diff-changed                 . nano-face-popout)
     (diff-added                   . nano-face-salient)
     (diff-refine-added            . (nano-face-salient nano-face-strong))
     (diff-refine-changed          . nano-face-popout)
     (diff-refine-removed          . nano-face-faded))
    (term
     (term-bold                    . nano-face-strong))
    (calendar
     (calendar-today               . nano-face-strong))
    (org-agenda
     (org-agenda-calendar-event    . nano-face-default)
     (org-agenda-calendar-sexp     . nano-face-salient)
     (org-agenda-clocking          . nano-face-faded)
     (org-agenda-column-dateline   . nano-face-faded)
     (org-agenda-current-time      . nano-face-strong)
     (org-agenda-date              . nano-face-salient)
     (org-agenda-date-today        . (nano-face-salient nano-face-strong))
     (org-agenda-date-weekend      . nano-face-faded)
     (org-agenda-diary             . nano-face-faded)
     (org-agenda-dimmed-todo-face  . nano-face-faded)
     (org-agenda-done              . nano-face-faded)
     (org-agenda-filter-category   . nano-face-faded)
     (org-agenda-filter-effort     . nano-face-faded)
     (org-agenda-filter-regexp     . nano-face-faded)
     (org-agenda-filter-tags       . nano-face-faded)
     (org-agenda-restriction-lock  . nano-face-faded)
     (org-agenda-structure         . nano-face-strong))
    (org
     (org-archived                 . nano-face-faded)
     (org-block                    . hl-line)
     (org-block-begin-line         . nano-face-faded)
     (org-block-end-line           . nano-face-faded)
     (org-checkbox                 . nano-face-faded)
     (org-checkbox-statistics-done . nano-face-faded)
     (org-checkbox-statistics-todo . nano-face-faded)
     (org-clock-overlay            . nano-face-faded)
     (org-code                     . nano-face-faded)
     (org-column                   . nano-face-faded)
     (org-column-title             . nano-face-faded)
     (org-date                     . nano-face-faded)
     (org-date-selected            . nano-face-faded)
     (org-default                  . nano-face-faded)
     (org-document-info            . nano-face-faded)
     (org-document-info-keyword    . nano-face-faded)
     (org-document-title           . nano-face-faded)
     (org-done                     . nano-face-default)
     (org-drawer                   . nano-face-faded)
     (org-ellipsis                 . nano-face-faded)
     (org-footnote                 . nano-face-faded)
     (org-formula                  . nano-face-faded)
     (org-headline-done            . nano-face-faded)
     (org-latex-and-related        . nano-face-faded)
     (org-level-1                  . nano-face-strong)
     (org-level-2                  . nano-face-strong)
     (org-level-3                  . nano-face-strong)
     (org-level-4                  . nano-face-strong)
     (org-level-5                  . nano-face-strong)
     (org-level-6                  . nano-face-strong)
     (org-level-7                  . nano-face-strong)
     (org-level-8                  . nano-face-strong)
     (org-link                     . nano-face-salient)
     (org-list-dt                  . nano-face-faded)
     (org-macro                    . nano-face-faded)
     (org-meta-line                . nano-face-faded)
     (org-mode-line-clock          . nano-face-faded)
     (org-mode-line-clock-overrun  . nano-face-faded)
     (org-priority                 . nano-face-faded)
     (org-property-value           . nano-face-faded)
     (org-quote                    . nano-face-faded)
     (org-scheduled                . nano-face-faded)
     (org-scheduled-previously     . nano-face-faded)
     (org-scheduled-today          . (nano-face-salient nano-face-strong))
     (org-sexp-date                . nano-face-faded)
     (org-special-keyword          . nano-face-faded)
     (org-table                    . nano-face-faded)
     (org-tag                      . nano-face-popout)
     (org-tag-group                . nano-face-faded)
     (org-target                   . nano-face-faded)
     (org-time-grid                . nano-face-faded)
     (org-todo                     . nano-face-salient)
     (org-upcoming-deadline        . nano-face-default)
     (org-verbatim                 . nano-face-popout)
     (org-verse                    . nano-face-faded)
     (org-warning                  . nano-face-popout))
    (markdown-mode
     (markdown-blockquote-face        . nano-face-default)
     (markdown-bold-face              . nano-face-strong)
     (markdown-code-face              . nano-face-default)
     (markdown-comment-face           . nano-face-faded)
     (markdown-footnote-marker-face   . nano-face-default)
     (markdown-footnote-text-face     . nano-face-default)
     (markdown-gfm-checkbox-face      . nano-face-default)
     (markdown-header-delimiter-face  . nano-face-faded)
     (markdown-header-face            . nano-face-strong)
     (markdown-header-face-1          . nano-face-strong)
     (markdown-header-face-2          . nano-face-strong)
     (markdown-header-face-3          . nano-face-strong)
     (markdown-header-face-4          . nano-face-strong)
     (markdown-header-face-5          . nano-face-strong)
     (markdown-header-face-6          . nano-face-strong)
     (markdown-header-rule-face       . nano-face-default)
     (markdown-highlight-face         . nano-face-default)
     (markdown-hr-face                . nano-face-default)
     (markdown-html-attr-name-face    . nano-face-default)
     (markdown-html-attr-value-face   . nano-face-default)
     (markdown-html-entity-face       . nano-face-default)
     (markdown-html-tag-delimiter-face . nano-face-default)
     (markdown-html-tag-name-face     . nano-face-default)
     (markdown-inline-code-face       . nano-face-popout)
     (markdown-italic-face            . nano-face-faded)
     (markdown-language-info-face     . nano-face-default)
     (markdown-language-keyword-face  . nano-face-default)
     (markdown-line-break-face        . nano-face-default)
     (markdown-link-face              . nano-face-salient)
     (markdown-link-title-face        . nano-face-default)
     (markdown-list-face              . nano-face-faded)
     (markdown-markup-face            . nano-face-faded)
     (markdown-math-face              . nano-face-default)
     (markdown-metadata-key-face      . nano-face-faded)
     (markdown-metadata-value-face    . nano-face-faded)
     (markdown-missing-link-face      . nano-face-default)
     (markdown-plain-url-face         . nano-face-default)
     (markdown-pre-face               . nano-face-default)
     (markdown-reference-face         . nano-face-salient)
     (markdown-strike-through-face    . nano-face-faded)
     (markdown-table-face             . nano-face-default)
     (markdown-url-face               . nano-face-salient)))
  "Alist of (FEATURE (FACE . STYLE) ...).
Each FACE is reset and made to inherit STYLE, when FEATURE is
loaded (immediately if FEATURE is nil).")

;; faceの継承だけでは済まない設定
(defun nano-theme--basics ()
  "Set the attributes of the basic faces that are not inherited."
  (set-foreground-color nano-color-foreground)
  (set-background-color nano-color-background)
  (set-face-attribute 'default nil
                      :foreground nano-color-foreground
                      :background nano-color-background
                      :weight 'light
                      :family (face-attribute 'nano-face-default :family)
                      :height (face-attribute 'nano-face-default :height))
  (if nano-font-family-proportional
      ;; mixed-pitchのために、継承ではなく値を設定する
      (set-face-attribute 'variable-pitch nil
                          :foreground nano-color-foreground
                          :background nano-color-background
                          :family (face-attribute 'nano-face-variable-pitch :family)
                          :height (face-attribute 'nano-face-variable-pitch :height))
    (nano-theme--set-face 'variable-pitch 'nano-face-default))
  (set-face-attribute 'cursor nil :background nano-color-foreground)
  (set-face-attribute 'window-divider nil :foreground nano-color-background)
  (set-face-attribute 'window-divider-first-pixel nil
                      :foreground nano-color-background)
  (set-face-attribute 'window-divider-last-pixel nil
                      :foreground nano-color-background)
  (set-face-foreground 'vertical-border nano-color-subtle)
  (set-face-attribute 'fringe nil
                      :foreground nano-color-subtle
                      :background nano-color-background)
  (set-face-attribute 'tooltip nil :height 0.85))

(defun nano-theme--font-lock ()
  "Set the syntax colors of the current palette, or reset them."
  (let ((faces (delete-dups
                (mapcan (lambda (palette)
                          (mapcar #'car (plist-get (cdr palette) :font-lock)))
                        nano-theme-palettes))))
    (dolist (face faces)
      (when (facep face)
        (set-face-attribute face nil
                            :foreground (or (alist-get face nano-theme-font-lock-colors)
                                            'unspecified))))))

(defun nano-theme--mode-line ()
  "Set the mode line, the header line and the internal border.
The mode line is only a thin line that separates the windows."
  (let ((graphic (display-graphic-p)))
    (dolist (face '(mode-line mode-line-inactive))
      (set-face-attribute face nil
                          :height 0.1
                          :foreground (if graphic nano-color-background
                                        nano-color-foreground)
                          :background nano-color-background
                          :underline (if graphic
                                         (or nano-color-border nano-color-subtle)
                                       t)
                          :overline nil
                          :box nil))
    (set-face-attribute 'mode-line-inactive nil :inherit nil))
  (set-face-attribute 'header-line nil
                      :weight 'light
                      :foreground nano-color-foreground
                      :background nano-color-background
                      :overline nil
                      :underline nil
                      :box (nano-faces--box nano-color-background)
                      :inherit nil)
  (set-face-attribute 'internal-border nil :background nano-color-background))

(defvar-local nano-theme--minibuffer-cookie nil
  "Cookie of the face remapping in the minibuffer and the echo area.")

(defun nano-theme--minibuffer ()
  "Show the text of the minibuffer and the echo area with `nano-face-faded'."
  (dolist (buffer '(" *Minibuf-0*" " *Echo Area 0*"
                    " *Minibuf-1*" " *Echo Area 1*"))
    (when (get-buffer buffer)
      (with-current-buffer buffer
        (unless nano-theme--minibuffer-cookie
          (setq nano-theme--minibuffer-cookie
                (face-remap-add-relative 'default 'nano-face-faded)))))))

(defun nano-theme--hl-line ()
  "Set the background of `hl-line'."
  (set-face-attribute 'hl-line nil :background nano-color-highlight))

(defun nano-theme--buttons ()
  "Set the faces of the customize buttons."
  (set-face-attribute 'custom-button nil
                      :foreground nano-color-faded
                      :background nano-color-background
                      :box (nano-faces--box nano-color-faded))
  (set-face-attribute 'custom-button-mouse nil
                      :foreground nano-color-faded
                      :background nano-color-subtle
                      :box (nano-faces--box nano-color-faded))
  (set-face-attribute 'custom-button-pressed nil
                      :foreground nano-color-background
                      :background nano-color-salient
                      :inherit 'nano-face-salient
                      :box (nano-faces--box nano-color-salient)
                      :inverse-video nil))

(defun nano-theme--diff ()
  "Strike through the refined removed text."
  (set-face-attribute 'diff-refine-removed nil :strike-through t))

(defun nano-theme--org ()
  "Extend the background of the org blocks to the window edge."
  (dolist (face '(org-block org-block-begin-line org-block-end-line))
    (set-face-attribute face nil :extend t)))

(defun nano-theme--term ()
  "Set the term colors from nano and Material design."
  (set-face-attribute 'term-color-black nil
                      :foreground nano-color-foreground
                      :background nano-color-foreground)
  (set-face-attribute 'term-color-white nil
                      :foreground nano-color-background
                      :background nano-color-background)
  (pcase-dolist (`(,face ,fg ,bg)
                 '((term-color-blue    "#42A5F5" "#BBDEFB")   ; blue L400/L100
                   (term-color-cyan    "#26C6DA" "#B2EBF2")   ; cyan
                   (term-color-green   "#66BB6A" "#C8E6C9")   ; green
                   (term-color-magenta "#AB47BC" "#E1BEE7")   ; purple
                   (term-color-red     "#EF5350" "#FFCDD2")   ; red
                   (term-color-yellow  "#FFEE58" "#FFF9C4"))) ; yellow
    (set-face-attribute face nil :foreground fg :background bg)))

(defconst nano-theme-functions
  '((nil       nano-theme--basics nano-theme--font-lock
               nano-theme--mode-line nano-theme--minibuffer)
    (hl-line   nano-theme--hl-line)
    (cus-edit  nano-theme--buttons)
    (diff-mode nano-theme--diff)
    (org       nano-theme--org)
    (term      nano-theme--term))
  "Alist of (FEATURE FUNCTION ...).
Each FUNCTION is called after the faces of `nano-theme-faces',
when FEATURE is loaded (immediately if FEATURE is nil).")

(defun nano-theme--apply (feature)
  "Set the faces that belong to FEATURE."
  (pcase-dolist (`(,face . ,style) (alist-get feature nano-theme-faces))
    (nano-theme--set-face face style))
  (mapc #'funcall (alist-get feature nano-theme-functions)))

(defvar nano-theme--pending nil
  "Features whose faces are set when they are loaded.")

(defun nano-theme ()
  "Derive many, many faces from the core nano faces."
  (dolist (feature (delete-dups (append (mapcar #'car nano-theme-faces)
                                        (mapcar #'car nano-theme-functions))))
    (cond ((or (null feature) (featurep feature))
           (nano-theme--apply feature))
          ((not (memq feature nano-theme--pending))
           ;; 読み込まれたときに、その時点の配色で設定する
           (push feature nano-theme--pending)
           (with-eval-after-load feature
             (setq nano-theme--pending (delq feature nano-theme--pending))
             (nano-theme--apply feature)))))
  (run-hooks 'nano-theme-hook))

(defun nano-refresh-theme ()
  "Apply the `nano-color-*' values to the nano faces and the other faces."
  (interactive)
  (nano-faces)
  (nano-theme))

(defun nano-toggle-theme ()
  "Toggle between the light palette and the dark one used last."
  (interactive)
  (nano-theme-set (if (eq frame-background-mode 'dark)
                      'light
                    nano-theme--last-dark))
  (nano-refresh-theme))

(provide 'nano-theme)
;;; nano-theme.el ends here
