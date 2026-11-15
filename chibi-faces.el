;;; chibi-faces.el --- The basic faces of chibi  -*- lexical-binding: t -*-

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

;; chibiの基本のface（`chibi-face-default'、`-critical'、`-popout'、
;; `-strong'、`-salient'、`-faded'、`-subtle'）と、それをもとにした
;; header line、tag、`chibi-command'のface、フォントの設定。
;;
;; faceの中身は、`chibi-faces'を呼んだときに`chibi-color-*'から決まる。
;; ふつうは`chibi-refresh-theme'から呼ぶ。
;;
;; 日本語（CJK）のフォントの割り当ても、ここ（`chibi-faces-setup-cjk'）
;; でする。

;;; Code:

(require 'chibi-base-colors)

;;; Fonts

(defcustom chibi-font-family-monospaced "Roboto Mono"
  "Font family of the default face.
Customizing this might lead to conflicts if the family does not
have sufficient bold/light etc. faces."
  :group 'chibi
  :type 'string)

(defcustom chibi-font-family-proportional nil
  "Font family of the variable pitch faces, or nil.
When non-nil, `variable-pitch-mode' and `mixed-pitch-mode' use it."
  :group 'chibi
  :type '(choice (const :tag "Same as monospaced" nil) string))

(defcustom chibi-font-family-fallback nil
  "Font family of the truncation and wrap glyphs, or nil for the default font."
  :group 'chibi
  :type '(choice (const :tag "Default font" nil) string))

(defcustom chibi-font-family-cjk nil
  "Font family for CJK (Japanese, Chinese) characters, or nil.
When non-nil, `chibi-faces' assigns this family to the scripts and
charsets in `chibi-font-cjk-targets' in the default fontset.  Since
chibi sets the :family of the default face, CJK characters would
otherwise use whatever font the system picks, which usually has a
different width and height.
Example: \"PlemolJP35 Console NFJ\", \"Source Han Code JP\"."
  :group 'chibi
  :type '(choice (const :tag "Do not touch the fontset" nil)
                 (string :tag "Font family")))

(defcustom chibi-font-cjk-rescale 1.0
  "Rescale ratio of `chibi-font-family-cjk' against the monospaced font.
Use this to make two CJK characters exactly as wide as three (or
two) ASCII characters, e.g. 1.2 for Hiragino with Roboto Mono."
  :group 'chibi
  :type 'number)

(defcustom chibi-font-cjk-targets
  '(japanese-jisx0208 japanese-jisx0212
    japanese-jisx0213.2004-1 japanese-jisx0213-2
    katakana-jisx0201 kana han cjk-misc)
  "Scripts and charsets that use `chibi-font-family-cjk'."
  :group 'chibi
  :type '(repeat symbol))

(defcustom chibi-font-size 14
  "Font size of the default face in pt.
To change this after startup, call `chibi-refresh-theme'."
  :group 'chibi
  :type 'integer)

;;; Faces

(defface chibi-face-default nil
  "Default face is used for regular information."
  :group 'chibi)

(defface chibi-face-variable-pitch nil
  "Default variable-pitch face is used for variable pitch mode."
  :group 'chibi)

(defface chibi-face-critical nil
  "Critical face is for information that requires immediate action.
It should be of high contrast when compared to other faces.  This
can be realized (for example) by setting an intense background
color, typically a shade of red.  It must be used scarcely."
  :group 'chibi)

(defface chibi-face-popout nil
  "Popout face is used for information that needs attention.
To achieve such effect, the hue of the face has to be
sufficiently different from other faces such that it attracts
attention through the popout effect."
  :group 'chibi)

(defface chibi-face-strong nil
  "Strong face is used for information of a structural nature.
It has to be the same color as the default color and only the
weight differs by one level (e.g., light/regular or
regular/bold).  It is generally used for titles, keywords,
directory, etc."
  :group 'chibi)

(defface chibi-face-salient nil
  "Salient face is used for information that are important.
To suggest the information is of the same nature but important,
the face uses a different hue with approximately the same
intensity as the default face.  This is typically used for links."
  :group 'chibi)

(defface chibi-face-faded nil
  "Faded face is for information that are less important.
It is made by using the same hue as the default but with a lesser
intensity than the default.  It can be used for comments,
secondary information and also replace italic (which is generally
abused anyway)."
  :group 'chibi)

(defface chibi-face-subtle nil
  "Subtle face is used to suggest a physical area on the screen.
It is important to not disturb too strongly the reading of
information and this can be made by setting a very light
background color that is barely perceptible."
  :group 'chibi)

(defface chibi-face-fallback nil
  "Face of the truncation and wrap glyphs."
  :group 'chibi)

;; header lineとtagのface。critical、popout、salient、fadedは、
;; その色を背景にして、文字を背景色で抜く。
(defconst chibi-faces--accents '(critical popout salient faded)
  "Colors used for the accented header and tag faces.")

(dolist (kind '(default strong subtle highlight separator filler
                critical popout salient faded))
  (custom-declare-face (intern (format "chibi-face-header-%s" kind)) nil
                       (format "Face for the header line (%s)." kind)
                       :group 'chibi))

(dolist (kind '(default strong critical popout salient faded))
  (custom-declare-face (intern (format "chibi-face-tag-%s" kind)) nil
                       (format "Face for tags (%s)." kind)
                       :group 'chibi))

(defface chibi-face-command nil
  "Face for the whole header line of `chibi-command'."
  :group 'chibi)

(defface chibi-face-command-prompt nil
  "Face for the prompt of `chibi-command'."
  :group 'chibi)

(defface chibi-face-command-cursor nil
  "Face for the cursor of `chibi-command'."
  :group 'chibi)

;;; Functions

(defun chibi-what-faces (pos)
  "Show the faces at POS."
  (interactive "d")
  (message "Faces: %s"
           (remq nil (list (get-char-property pos 'read-face-name)
                           (get-char-property pos 'face)
                           (plist-get (text-properties-at pos) 'face)))))

(defun chibi-faces-setup-cjk ()
  "Assign `chibi-font-family-cjk' to the CJK characters in the default fontset."
  (when (and chibi-font-family-cjk (display-graphic-p))
    (let ((spec (font-spec :family chibi-font-family-cjk)))
      (dolist (target chibi-font-cjk-targets)
        (set-fontset-font t target spec)))
    (let ((pattern (format ".*%s.*" (regexp-quote chibi-font-family-cjk))))
      (setq face-font-rescale-alist
            (cons (cons pattern chibi-font-cjk-rescale)
                  (assoc-delete-all pattern face-font-rescale-alist))))))

(defun chibi-faces--color (name)
  "Return the value of `chibi-color-NAME'."
  (symbol-value (intern (format "chibi-color-%s" name))))

(defun chibi-faces--box (color)
  "Return a :box attribute of width 1 with COLOR."
  `(:line-width 1 :color ,color :style nil))

(defun chibi-faces--tag-height ()
  "Return the height of the tag faces."
  (if (display-graphic-p) (round (* 0.85 10 chibi-font-size)) 1))

(defun chibi-faces ()
  "Derive the attributes of the chibi faces from the `chibi-color-*' values."
  (chibi-faces-setup-cjk)
  (let ((graphic (display-graphic-p))
        (header-bg (or chibi-color-header-background chibi-color-subtle))
        (bg-box (chibi-faces--box chibi-color-background))
        (tag-height (chibi-faces--tag-height)))
    ;; Core
    (set-face-attribute 'chibi-face-default nil
                        :foreground chibi-color-foreground
                        :background chibi-color-background
                        :family chibi-font-family-monospaced
                        :height (* chibi-font-size 10))
    (set-face-attribute 'chibi-face-variable-pitch nil
                        :foreground chibi-color-foreground
                        :background chibi-color-background
                        :family (or chibi-font-family-proportional 'unspecified)
                        :height (* chibi-font-size 10))
    (set-face-attribute 'chibi-face-critical nil
                        :foreground chibi-color-foreground
                        :background chibi-color-critical)
    (set-face-attribute 'chibi-face-popout nil :foreground chibi-color-popout)
    (set-face-attribute 'chibi-face-strong nil
                        :foreground chibi-color-strong
                        :weight (if graphic 'medium 'bold))
    (set-face-attribute 'chibi-face-salient nil
                        :foreground chibi-color-salient :weight 'light)
    (set-face-attribute 'chibi-face-faded nil
                        :foreground chibi-color-faded :weight 'light)
    (set-face-attribute 'chibi-face-subtle nil :background chibi-color-subtle)
    (set-face-attribute 'chibi-face-fallback nil
                        :family (or chibi-font-family-fallback 'unspecified)
                        :inherit 'chibi-face-faded)

    ;; Header line
    (set-face-attribute 'chibi-face-header-default nil
                        :foreground chibi-color-foreground
                        :background header-bg
                        :box bg-box)
    (set-face-attribute 'chibi-face-header-strong nil
                        :foreground chibi-color-strong
                        :background header-bg
                        :inherit 'chibi-face-strong
                        :box bg-box)
    (dolist (name chibi-faces--accents)
      (set-face-attribute (intern (format "chibi-face-header-%s" name)) nil
                          :foreground chibi-color-background
                          :background (chibi-faces--color name)
                          :box bg-box))
    (set-face-attribute 'chibi-face-header-highlight nil
                        :inherit 'chibi-face-header-faded :box nil)
    (set-face-attribute 'chibi-face-header-separator nil
                        :inherit 'chibi-face-default :height 0.1)
    (set-face-attribute 'chibi-face-header-filler nil
                        :inherit 'chibi-face-header-default :height 0.1)

    ;; Tags
    (dolist (spec `((default ,chibi-color-foreground ,chibi-color-background
                             ,chibi-color-foreground)
                    (strong ,chibi-color-strong ,chibi-color-subtle
                            ,chibi-color-strong)
                    ,@(mapcar (lambda (name)
                                (let ((color (chibi-faces--color name)))
                                  (list name chibi-color-background color color)))
                              chibi-faces--accents)))
      (pcase-let ((`(,name ,fg ,bg ,box) spec))
        (set-face-attribute (intern (format "chibi-face-tag-%s" name)) nil
                            :foreground fg :background bg
                            :weight 'regular :height tag-height
                            :box (chibi-faces--box box))))

    ;; chibi-command
    (set-face-attribute 'chibi-face-command nil
                        :foreground chibi-color-foreground
                        :background chibi-color-subtle
                        :box (chibi-faces--box chibi-color-foreground)
                        :inherit nil)
    (set-face-attribute 'chibi-face-command-prompt nil
                        :inherit 'chibi-face-strong
                        :foreground chibi-color-background
                        :background chibi-color-foreground
                        :box (chibi-faces--box chibi-color-foreground))
    (set-face-attribute 'chibi-face-command-cursor nil
                        :foreground chibi-color-background
                        :background chibi-color-foreground)))

(provide 'chibi-faces)
;;; chibi-faces.el ends here
