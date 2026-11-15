;;; chibi-theme.el --- Palettes and face assignments of chibi  -*- lexical-binding: t -*-

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

;; 配色（`chibi-theme-palettes'）と、Emacsや各packageのfaceを
;; chibiの基本のfaceに割り当てる処理。
;;
;;   (chibi-theme-set 'vscmacs)   ; 配色を選ぶ（`chibi-color-*'を設定する）
;;   (chibi-refresh-theme)        ; faceに反映する
;;
;; packageのfaceは、そのpackageが読み込まれたときに割り当てる
;; （`chibi-theme-faces'）。
;;
;; 例外：
;; - `hl-line'は、`chibi-color-highlight'を背景にする。
;; - termの色は、Material designの色を使う。
;; - 配色に:font-lockがあれば、構文のfaceにその色を付ける（vscmacs）。

;;; Code:

(require 'chibi-faces)
(require 'face-remap)

;;; Palettes

(defcustom chibi-theme-palettes
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
  "Alist of (NAME . PLIST) of the chibi palettes.
PLIST has the 9 colors (:foreground, :background, :highlight,
:critical, :salient, :strong, :popout, :subtle, :faded) and :mode,
which is `light' or `dark'.  Optionally:
  :header-background  background of the header line
  :border             color of the window separators
  :font-lock          alist of (FACE . COLOR) for the syntax faces"
  :group 'chibi
  :type '(alist :key-type symbol :value-type plist))

(defvar chibi-theme-current nil
  "Name of the palette set by `chibi-theme-set', or nil.")

(defvar chibi-theme-font-lock-colors nil
  "Alist of (FACE . COLOR) of the current palette, set by `chibi-theme-set'.")

(defvar chibi-theme--last-dark 'dark
  "The dark palette used last, for `chibi-toggle-theme'.")

(defcustom chibi-theme-hook nil
  "Hook run at the end of `chibi-theme'."
  :group 'chibi
  :type 'hook)

(defun chibi-theme-set (name)
  "Set the `chibi-color-*' values to the palette NAME.
NAME is a key of `chibi-theme-palettes'.  Interactively, also
refresh the faces."
  (interactive
   (list (intern (completing-read "Palette: " chibi-theme-palettes nil t))))
  (let ((palette (or (alist-get name chibi-theme-palettes)
                     (error "No such chibi palette: %s" name))))
    (dolist (key '(foreground background highlight critical salient
                   strong popout subtle faded))
      (set (intern (format "chibi-color-%s" key))
           (plist-get palette (intern (format ":%s" key)))))
    (setq chibi-color-header-background (plist-get palette :header-background)
          chibi-color-border (plist-get palette :border)
          chibi-theme-font-lock-colors (plist-get palette :font-lock)
          frame-background-mode (plist-get palette :mode)
          chibi-theme-current name)
    (when (eq frame-background-mode 'dark)
      (setq chibi-theme--last-dark name)))
  (when (called-interactively-p 'any)
    (chibi-refresh-theme)))




;;; Face assignments

(defun chibi-theme--set-face (face style)
  "Reset FACE and make it inherit STYLE.  Do nothing if FACE is undefined."
  (when (facep face)
    (set-face-attribute face nil
                        :foreground 'unspecified :background 'unspecified
                        :family     'unspecified :slant      'unspecified
                        :weight     'unspecified :height     'unspecified
                        :underline  'unspecified :overline   'unspecified
                        :box        'unspecified :inherit    style)))

(defconst chibi-theme-faces
  '((nil
     ;; Structural
     (bold                         . chibi-face-strong)
     (italic                       . chibi-face-faded)
     (bold-italic                  . chibi-face-strong)
     (region                       . chibi-face-subtle)
     (highlight                    . chibi-face-subtle)
     (fixed-pitch-serif            . chibi-face-default)
     (cursor                       . chibi-face-default)
     ;; Semantic
     (shadow                       . chibi-face-faded)
     (success                      . chibi-face-salient)
     (warning                      . chibi-face-popout)
     (error                        . chibi-face-critical)
     (match                        . chibi-face-popout)
     ;; General
     (buffer-menu-buffer           . chibi-face-strong)
     (minibuffer-prompt            . chibi-face-strong)
     (link                         . chibi-face-salient)
     (fringe                       . chibi-face-faded)
     (isearch                      . chibi-face-strong)
     (isearch-fail                 . chibi-face-faded)
     (lazy-highlight               . chibi-face-subtle)
     (trailing-whitespace          . chibi-face-subtle)
     (show-paren-match             . chibi-face-popout)
     (show-paren-mismatch          . chibi-face-critical)
     (secondary-selection          . chibi-face-subtle)
     (completions-common-part      . chibi-face-faded)
     (completions-first-difference . chibi-face-default)
     ;; Font lock
     (font-lock-comment-face       . chibi-face-faded)
     (font-lock-doc-face           . chibi-face-faded)
     (font-lock-string-face        . chibi-face-popout)
     (font-lock-constant-face      . chibi-face-salient)
     (font-lock-warning-face       . chibi-face-popout)
     (font-lock-function-name-face . chibi-face-strong)
     (font-lock-variable-name-face . chibi-face-strong)
     (font-lock-builtin-face       . chibi-face-salient)
     (font-lock-type-face          . chibi-face-salient)
     (font-lock-keyword-face       . chibi-face-salient))
    (info
     (info-menu-header             . chibi-face-strong)
     (info-header-node             . chibi-face-default)
     (info-index-match             . chibi-face-salient)
     (Info-quoted                  . chibi-face-faded)
     (info-title-1                 . chibi-face-strong)
     (info-title-2                 . chibi-face-strong)
     (info-title-3                 . chibi-face-strong)
     (info-title-4                 . chibi-face-strong))
    (bookmark
     (bookmark-menu-bookmark       . chibi-face-salient))
    (message
     (message-cited-text           . chibi-face-faded)
     (message-cited-text-1         . chibi-face-faded)
     (message-cited-text-2         . chibi-face-faded)
     (message-cited-text-3         . chibi-face-faded)
     (message-cited-text-4         . chibi-face-faded)
     (message-header-cc            . chibi-face-default)
     (message-header-name          . chibi-face-strong)
     (message-header-newsgroups    . chibi-face-default)
     (message-header-other         . chibi-face-default)
     (message-header-subject       . chibi-face-salient)
     (message-header-to            . chibi-face-salient)
     (message-header-xheader       . chibi-face-default)
     (message-mml                  . chibi-face-popout)
     (message-separator            . chibi-face-faded))
    (outline
     (outline-1                    . chibi-face-strong)
     (outline-2                    . chibi-face-strong)
     (outline-3                    . chibi-face-strong)
     (outline-4                    . chibi-face-strong)
     (outline-5                    . chibi-face-strong)
     (outline-6                    . chibi-face-strong)
     (outline-7                    . chibi-face-strong)
     (outline-8                    . chibi-face-strong))
    (cus-edit
     (widget-field                 . chibi-face-subtle)
     (widget-button                . chibi-face-strong)
     (widget-single-line-field     . chibi-face-subtle)
     (custom-group-subtitle        . chibi-face-strong)
     (custom-group-tag             . chibi-face-strong)
     (custom-group-tag-1           . chibi-face-strong)
     (custom-comment               . chibi-face-faded)
     (custom-comment-tag           . chibi-face-faded)
     (custom-changed               . chibi-face-salient)
     (custom-modified              . chibi-face-salient)
     (custom-face-tag              . chibi-face-strong)
     (custom-variable-tag          . chibi-face-strong)
     (custom-invalid               . chibi-face-popout)
     (custom-visibility            . chibi-face-salient)
     (custom-state                 . chibi-face-salient)
     (custom-link                  . chibi-face-salient))
    (package
     (package-description          . chibi-face-default)
     (package-help-section-name    . chibi-face-default)
     (package-name                 . chibi-face-salient)
     (package-status-avail-obso    . chibi-face-faded)
     (package-status-available     . chibi-face-default)
     (package-status-built-in      . chibi-face-salient)
     (package-status-dependency    . chibi-face-salient)
     (package-status-disabled      . chibi-face-faded)
     (package-status-external      . chibi-face-default)
     (package-status-held          . chibi-face-default)
     (package-status-incompat      . chibi-face-faded)
     (package-status-installed     . chibi-face-salient)
     (package-status-new           . chibi-face-default)
     (package-status-unsigned      . chibi-face-default))
    (flyspell
     (flyspell-duplicate           . chibi-face-popout)
     (flyspell-incorrect           . chibi-face-popout))
    (diff-mode
     (diff-header                  . chibi-face-faded)
     (diff-file-header             . chibi-face-strong)
     (diff-context                 . chibi-face-default)
     (diff-removed                 . chibi-face-faded)
     (diff-changed                 . chibi-face-popout)
     (diff-added                   . chibi-face-salient)
     (diff-refine-added            . (chibi-face-salient chibi-face-strong))
     (diff-refine-changed          . chibi-face-popout)
     (diff-refine-removed          . chibi-face-faded))
    (term
     (term-bold                    . chibi-face-strong))
    (calendar
     (calendar-today               . chibi-face-strong))
    (org-agenda
     (org-agenda-calendar-event    . chibi-face-default)
     (org-agenda-calendar-sexp     . chibi-face-salient)
     (org-agenda-clocking          . chibi-face-faded)
     (org-agenda-column-dateline   . chibi-face-faded)
     (org-agenda-current-time      . chibi-face-strong)
     (org-agenda-date              . chibi-face-salient)
     (org-agenda-date-today        . (chibi-face-salient chibi-face-strong))
     (org-agenda-date-weekend      . chibi-face-faded)
     (org-agenda-diary             . chibi-face-faded)
     (org-agenda-dimmed-todo-face  . chibi-face-faded)
     (org-agenda-done              . chibi-face-faded)
     (org-agenda-filter-category   . chibi-face-faded)
     (org-agenda-filter-effort     . chibi-face-faded)
     (org-agenda-filter-regexp     . chibi-face-faded)
     (org-agenda-filter-tags       . chibi-face-faded)
     (org-agenda-restriction-lock  . chibi-face-faded)
     (org-agenda-structure         . chibi-face-strong))
    (org
     (org-archived                 . chibi-face-faded)
     (org-block                    . hl-line)
     (org-block-begin-line         . chibi-face-faded)
     (org-block-end-line           . chibi-face-faded)
     (org-checkbox                 . chibi-face-faded)
     (org-checkbox-statistics-done . chibi-face-faded)
     (org-checkbox-statistics-todo . chibi-face-faded)
     (org-clock-overlay            . chibi-face-faded)
     (org-code                     . chibi-face-faded)
     (org-column                   . chibi-face-faded)
     (org-column-title             . chibi-face-faded)
     (org-date                     . chibi-face-faded)
     (org-date-selected            . chibi-face-faded)
     (org-default                  . chibi-face-faded)
     (org-document-info            . chibi-face-faded)
     (org-document-info-keyword    . chibi-face-faded)
     (org-document-title           . chibi-face-faded)
     (org-done                     . chibi-face-default)
     (org-drawer                   . chibi-face-faded)
     (org-ellipsis                 . chibi-face-faded)
     (org-footnote                 . chibi-face-faded)
     (org-formula                  . chibi-face-faded)
     (org-headline-done            . chibi-face-faded)
     (org-latex-and-related        . chibi-face-faded)
     (org-level-1                  . chibi-face-strong)
     (org-level-2                  . chibi-face-strong)
     (org-level-3                  . chibi-face-strong)
     (org-level-4                  . chibi-face-strong)
     (org-level-5                  . chibi-face-strong)
     (org-level-6                  . chibi-face-strong)
     (org-level-7                  . chibi-face-strong)
     (org-level-8                  . chibi-face-strong)
     (org-link                     . chibi-face-salient)
     (org-list-dt                  . chibi-face-faded)
     (org-macro                    . chibi-face-faded)
     (org-meta-line                . chibi-face-faded)
     (org-mode-line-clock          . chibi-face-faded)
     (org-mode-line-clock-overrun  . chibi-face-faded)
     (org-priority                 . chibi-face-faded)
     (org-property-value           . chibi-face-faded)
     (org-quote                    . chibi-face-faded)
     (org-scheduled                . chibi-face-faded)
     (org-scheduled-previously     . chibi-face-faded)
     (org-scheduled-today          . (chibi-face-salient chibi-face-strong))
     (org-sexp-date                . chibi-face-faded)
     (org-special-keyword          . chibi-face-faded)
     (org-table                    . chibi-face-faded)
     (org-tag                      . chibi-face-popout)
     (org-tag-group                . chibi-face-faded)
     (org-target                   . chibi-face-faded)
     (org-time-grid                . chibi-face-faded)
     (org-todo                     . chibi-face-salient)
     (org-upcoming-deadline        . chibi-face-default)
     (org-verbatim                 . chibi-face-popout)
     (org-verse                    . chibi-face-faded)
     (org-warning                  . chibi-face-popout))
    (markdown-mode
     (markdown-blockquote-face        . chibi-face-default)
     (markdown-bold-face              . chibi-face-strong)
     (markdown-code-face              . chibi-face-default)
     (markdown-comment-face           . chibi-face-faded)
     (markdown-footnote-marker-face   . chibi-face-default)
     (markdown-footnote-text-face     . chibi-face-default)
     (markdown-gfm-checkbox-face      . chibi-face-default)
     (markdown-header-delimiter-face  . chibi-face-faded)
     (markdown-header-face            . chibi-face-strong)
     (markdown-header-face-1          . chibi-face-strong)
     (markdown-header-face-2          . chibi-face-strong)
     (markdown-header-face-3          . chibi-face-strong)
     (markdown-header-face-4          . chibi-face-strong)
     (markdown-header-face-5          . chibi-face-strong)
     (markdown-header-face-6          . chibi-face-strong)
     (markdown-header-rule-face       . chibi-face-default)
     (markdown-highlight-face         . chibi-face-default)
     (markdown-hr-face                . chibi-face-default)
     (markdown-html-attr-name-face    . chibi-face-default)
     (markdown-html-attr-value-face   . chibi-face-default)
     (markdown-html-entity-face       . chibi-face-default)
     (markdown-html-tag-delimiter-face . chibi-face-default)
     (markdown-html-tag-name-face     . chibi-face-default)
     (markdown-inline-code-face       . chibi-face-popout)
     (markdown-italic-face            . chibi-face-faded)
     (markdown-language-info-face     . chibi-face-default)
     (markdown-language-keyword-face  . chibi-face-default)
     (markdown-line-break-face        . chibi-face-default)
     (markdown-link-face              . chibi-face-salient)
     (markdown-link-title-face        . chibi-face-default)
     (markdown-list-face              . chibi-face-faded)
     (markdown-markup-face            . chibi-face-faded)
     (markdown-math-face              . chibi-face-default)
     (markdown-metadata-key-face      . chibi-face-faded)
     (markdown-metadata-value-face    . chibi-face-faded)
     (markdown-missing-link-face      . chibi-face-default)
     (markdown-plain-url-face         . chibi-face-default)
     (markdown-pre-face               . chibi-face-default)
     (markdown-reference-face         . chibi-face-salient)
     (markdown-strike-through-face    . chibi-face-faded)
     (markdown-table-face             . chibi-face-default)
     (markdown-url-face               . chibi-face-salient)))
  "Alist of (FEATURE (FACE . STYLE) ...).
Each FACE is reset and made to inherit STYLE, when FEATURE is
loaded (immediately if FEATURE is nil).")

;; faceの継承だけでは済まない設定
(defun chibi-theme--basics ()
  "Set the attributes of the basic faces that are not inherited."
  (set-foreground-color chibi-color-foreground)
  (set-background-color chibi-color-background)
  (set-face-attribute 'default nil
                      :foreground chibi-color-foreground
                      :background chibi-color-background
                      :weight 'light
                      :family (face-attribute 'chibi-face-default :family)
                      :height (face-attribute 'chibi-face-default :height))
  (if chibi-font-family-proportional
      ;; mixed-pitchのために、継承ではなく値を設定する
      (set-face-attribute 'variable-pitch nil
                          :foreground chibi-color-foreground
                          :background chibi-color-background
                          :family (face-attribute 'chibi-face-variable-pitch :family)
                          :height (face-attribute 'chibi-face-variable-pitch :height))
    (chibi-theme--set-face 'variable-pitch 'chibi-face-default))
  (set-face-attribute 'cursor nil :background chibi-color-foreground)
  (set-face-attribute 'window-divider nil :foreground chibi-color-background)
  (set-face-attribute 'window-divider-first-pixel nil
                      :foreground chibi-color-background)
  (set-face-attribute 'window-divider-last-pixel nil
                      :foreground chibi-color-background)
  (set-face-foreground 'vertical-border chibi-color-subtle)
  (set-face-attribute 'fringe nil
                      :foreground chibi-color-subtle
                      :background chibi-color-background)
  (set-face-attribute 'tooltip nil :height 0.85))

(defun chibi-theme--font-lock ()
  "Set the syntax colors of the current palette, or reset them."
  (let ((faces (delete-dups
                (mapcan (lambda (palette)
                          (mapcar #'car (plist-get (cdr palette) :font-lock)))
                        chibi-theme-palettes))))
    (dolist (face faces)
      (when (facep face)
        (set-face-attribute face nil
                            :foreground (or (alist-get face chibi-theme-font-lock-colors)
                                            'unspecified))))))

(defun chibi-theme--mode-line ()
  "Set the mode line, the header line and the internal border.
The mode line is only a thin line that separates the windows."
  (let ((graphic (display-graphic-p)))
    (dolist (face '(mode-line mode-line-inactive))
      (set-face-attribute face nil
                          :height 0.1
                          :foreground (if graphic chibi-color-background
                                        chibi-color-foreground)
                          :background chibi-color-background
                          :underline (if graphic
                                         (or chibi-color-border chibi-color-subtle)
                                       t)
                          :overline nil
                          :box nil))
    (set-face-attribute 'mode-line-inactive nil :inherit nil))
  (set-face-attribute 'header-line nil
                      :weight 'light
                      :foreground chibi-color-foreground
                      :background chibi-color-background
                      :overline nil
                      :underline nil
                      :box (chibi-faces--box chibi-color-background)
                      :inherit nil)
  (set-face-attribute 'internal-border nil :background chibi-color-background))

(defvar-local chibi-theme--minibuffer-cookie nil
  "Cookie of the face remapping in the minibuffer and the echo area.")

(defun chibi-theme--minibuffer ()
  "Show the text of the minibuffer and the echo area with `chibi-face-faded'."
  (dolist (buffer '(" *Minibuf-0*" " *Echo Area 0*"
                    " *Minibuf-1*" " *Echo Area 1*"))
    (when (get-buffer buffer)
      (with-current-buffer buffer
        (unless chibi-theme--minibuffer-cookie
          (setq chibi-theme--minibuffer-cookie
                (face-remap-add-relative 'default 'chibi-face-faded)))))))

(defun chibi-theme--hl-line ()
  "Set the background of `hl-line'."
  (set-face-attribute 'hl-line nil :background chibi-color-highlight))

(defun chibi-theme--buttons ()
  "Set the faces of the customize buttons."
  (set-face-attribute 'custom-button nil
                      :foreground chibi-color-faded
                      :background chibi-color-background
                      :box (chibi-faces--box chibi-color-faded))
  (set-face-attribute 'custom-button-mouse nil
                      :foreground chibi-color-faded
                      :background chibi-color-subtle
                      :box (chibi-faces--box chibi-color-faded))
  (set-face-attribute 'custom-button-pressed nil
                      :foreground chibi-color-background
                      :background chibi-color-salient
                      :inherit 'chibi-face-salient
                      :box (chibi-faces--box chibi-color-salient)
                      :inverse-video nil))

(defun chibi-theme--diff ()
  "Strike through the refined removed text."
  (set-face-attribute 'diff-refine-removed nil :strike-through t))

(defun chibi-theme--org ()
  "Extend the background of the org blocks to the window edge."
  (dolist (face '(org-block org-block-begin-line org-block-end-line))
    (set-face-attribute face nil :extend t)))

(defun chibi-theme--term ()
  "Set the term colors from chibi and Material design."
  (set-face-attribute 'term-color-black nil
                      :foreground chibi-color-foreground
                      :background chibi-color-foreground)
  (set-face-attribute 'term-color-white nil
                      :foreground chibi-color-background
                      :background chibi-color-background)
  (pcase-dolist (`(,face ,fg ,bg)
                 '((term-color-blue    "#42A5F5" "#BBDEFB")   ; blue L400/L100
                   (term-color-cyan    "#26C6DA" "#B2EBF2")   ; cyan
                   (term-color-green   "#66BB6A" "#C8E6C9")   ; green
                   (term-color-magenta "#AB47BC" "#E1BEE7")   ; purple
                   (term-color-red     "#EF5350" "#FFCDD2")   ; red
                   (term-color-yellow  "#FFEE58" "#FFF9C4"))) ; yellow
    (set-face-attribute face nil :foreground fg :background bg)))

(defconst chibi-theme-functions
  '((nil       chibi-theme--basics chibi-theme--font-lock
               chibi-theme--mode-line chibi-theme--minibuffer)
    (hl-line   chibi-theme--hl-line)
    (cus-edit  chibi-theme--buttons)
    (diff-mode chibi-theme--diff)
    (org       chibi-theme--org)
    (term      chibi-theme--term))
  "Alist of (FEATURE FUNCTION ...).
Each FUNCTION is called after the faces of `chibi-theme-faces',
when FEATURE is loaded (immediately if FEATURE is nil).")

(defun chibi-theme--apply (feature)
  "Set the faces that belong to FEATURE."
  (pcase-dolist (`(,face . ,style) (alist-get feature chibi-theme-faces))
    (chibi-theme--set-face face style))
  (mapc #'funcall (alist-get feature chibi-theme-functions)))

(defvar chibi-theme--pending nil
  "Features whose faces are set when they are loaded.")

(defun chibi-theme ()
  "Derive many, many faces from the core chibi faces."
  (dolist (feature (delete-dups (append (mapcar #'car chibi-theme-faces)
                                        (mapcar #'car chibi-theme-functions))))
    (cond ((or (null feature) (featurep feature))
           (chibi-theme--apply feature))
          ((not (memq feature chibi-theme--pending))
           ;; 読み込まれたときに、その時点の配色で設定する
           (push feature chibi-theme--pending)
           (with-eval-after-load feature
             (setq chibi-theme--pending (delq feature chibi-theme--pending))
             (chibi-theme--apply feature)))))
  (run-hooks 'chibi-theme-hook))

(defun chibi-refresh-theme ()
  "Apply the `chibi-color-*' values to the chibi faces and the other faces."
  (interactive)
  (chibi-faces)
  (chibi-theme))

(defun chibi-toggle-theme ()
  "Toggle between the light palette and the dark one used last."
  (interactive)
  (chibi-theme-set (if (eq frame-background-mode 'dark)
                      'light
                    chibi-theme--last-dark))
  (chibi-refresh-theme))

(provide 'chibi-theme)
;;; chibi-theme.el ends here
