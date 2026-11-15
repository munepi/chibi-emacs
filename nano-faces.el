;;; nano-faces.el --- The basic faces of N Λ N O  -*- lexical-binding: t -*-

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

;; nanoの基本のface（`nano-face-default'、`-critical'、`-popout'、
;; `-strong'、`-salient'、`-faded'、`-subtle'）と、それをもとにした
;; header line、tag、`nano-command'のface、フォントの設定。
;;
;; faceの中身は、`nano-faces'を呼んだときに`nano-color-*'から決まる。
;; ふつうは`nano-refresh-theme'から呼ぶ。
;;
;; 日本語（CJK）のフォントの割り当ても、ここ（`nano-faces-setup-cjk'）
;; でする。

;;; Code:

(require 'nano-base-colors)

;;; Fonts

(defcustom nano-font-family-monospaced "Roboto Mono"
  "Font family of the default face.
Customizing this might lead to conflicts if the family does not
have sufficient bold/light etc. faces."
  :group 'nano
  :type 'string)

(defcustom nano-font-family-proportional nil
  "Font family of the variable pitch faces, or nil.
When non-nil, `variable-pitch-mode' and `mixed-pitch-mode' use it."
  :group 'nano
  :type '(choice (const :tag "Same as monospaced" nil) string))

(defcustom nano-font-family-fallback nil
  "Font family of the truncation and wrap glyphs, or nil for the default font."
  :group 'nano
  :type '(choice (const :tag "Default font" nil) string))

(defcustom nano-font-family-cjk nil
  "Font family for CJK (Japanese, Chinese) characters, or nil.
When non-nil, `nano-faces' assigns this family to the scripts and
charsets in `nano-font-cjk-targets' in the default fontset.  Since
nano sets the :family of the default face, CJK characters would
otherwise use whatever font the system picks, which usually has a
different width and height.
Example: \"PlemolJP35 Console NFJ\", \"Source Han Code JP\"."
  :group 'nano
  :type '(choice (const :tag "Do not touch the fontset" nil)
                 (string :tag "Font family")))

(defcustom nano-font-cjk-rescale 1.0
  "Rescale ratio of `nano-font-family-cjk' against the monospaced font.
Use this to make two CJK characters exactly as wide as three (or
two) ASCII characters, e.g. 1.2 for Hiragino with Roboto Mono."
  :group 'nano
  :type 'number)

(defcustom nano-font-cjk-targets
  '(japanese-jisx0208 japanese-jisx0212
    japanese-jisx0213.2004-1 japanese-jisx0213-2
    katakana-jisx0201 kana han cjk-misc)
  "Scripts and charsets that use `nano-font-family-cjk'."
  :group 'nano
  :type '(repeat symbol))

(defcustom nano-font-size 14
  "Font size of the default face in pt.
To change this after startup, call `nano-refresh-theme'."
  :group 'nano
  :type 'integer)

;;; Faces

(defface nano-face-default nil
  "Default face is used for regular information."
  :group 'nano)

(defface nano-face-variable-pitch nil
  "Default variable-pitch face is used for variable pitch mode."
  :group 'nano)

(defface nano-face-critical nil
  "Critical face is for information that requires immediate action.
It should be of high contrast when compared to other faces.  This
can be realized (for example) by setting an intense background
color, typically a shade of red.  It must be used scarcely."
  :group 'nano)

(defface nano-face-popout nil
  "Popout face is used for information that needs attention.
To achieve such effect, the hue of the face has to be
sufficiently different from other faces such that it attracts
attention through the popout effect."
  :group 'nano)

(defface nano-face-strong nil
  "Strong face is used for information of a structural nature.
It has to be the same color as the default color and only the
weight differs by one level (e.g., light/regular or
regular/bold).  It is generally used for titles, keywords,
directory, etc."
  :group 'nano)

(defface nano-face-salient nil
  "Salient face is used for information that are important.
To suggest the information is of the same nature but important,
the face uses a different hue with approximately the same
intensity as the default face.  This is typically used for links."
  :group 'nano)

(defface nano-face-faded nil
  "Faded face is for information that are less important.
It is made by using the same hue as the default but with a lesser
intensity than the default.  It can be used for comments,
secondary information and also replace italic (which is generally
abused anyway)."
  :group 'nano)

(defface nano-face-subtle nil
  "Subtle face is used to suggest a physical area on the screen.
It is important to not disturb too strongly the reading of
information and this can be made by setting a very light
background color that is barely perceptible."
  :group 'nano)

(defface nano-face-fallback nil
  "Face of the truncation and wrap glyphs."
  :group 'nano)

;; header lineとtagのface。critical、popout、salient、fadedは、
;; その色を背景にして、文字を背景色で抜く。
(defconst nano-faces--accents '(critical popout salient faded)
  "Colors used for the accented header and tag faces.")

(dolist (kind '(default strong subtle highlight separator filler
                critical popout salient faded))
  (custom-declare-face (intern (format "nano-face-header-%s" kind)) nil
                       (format "Face for the header line (%s)." kind)
                       :group 'nano))

(dolist (kind '(default strong critical popout salient faded))
  (custom-declare-face (intern (format "nano-face-tag-%s" kind)) nil
                       (format "Face for tags (%s)." kind)
                       :group 'nano))

(defface nano-face-command nil
  "Face for the whole header line of `nano-command'."
  :group 'nano)

(defface nano-face-command-prompt nil
  "Face for the prompt of `nano-command'."
  :group 'nano)

(defface nano-face-command-cursor nil
  "Face for the cursor of `nano-command'."
  :group 'nano)

;;; Functions

(defun nano-what-faces (pos)
  "Show the faces at POS."
  (interactive "d")
  (message "Faces: %s"
           (remq nil (list (get-char-property pos 'read-face-name)
                           (get-char-property pos 'face)
                           (plist-get (text-properties-at pos) 'face)))))

(defun nano-faces-setup-cjk ()
  "Assign `nano-font-family-cjk' to the CJK characters in the default fontset."
  (when (and nano-font-family-cjk (display-graphic-p))
    (let ((spec (font-spec :family nano-font-family-cjk)))
      (dolist (target nano-font-cjk-targets)
        (set-fontset-font t target spec)))
    (let ((pattern (format ".*%s.*" (regexp-quote nano-font-family-cjk))))
      (setq face-font-rescale-alist
            (cons (cons pattern nano-font-cjk-rescale)
                  (assoc-delete-all pattern face-font-rescale-alist))))))

(defun nano-faces--color (name)
  "Return the value of `nano-color-NAME'."
  (symbol-value (intern (format "nano-color-%s" name))))

(defun nano-faces--box (color)
  "Return a :box attribute of width 1 with COLOR."
  `(:line-width 1 :color ,color :style nil))

(defun nano-faces--tag-height ()
  "Return the height of the tag faces."
  (if (display-graphic-p) (round (* 0.85 10 nano-font-size)) 1))

(defun nano-faces ()
  "Derive the attributes of the nano faces from the `nano-color-*' values."
  (nano-faces-setup-cjk)
  (let ((graphic (display-graphic-p))
        (header-bg (or nano-color-header-background nano-color-subtle))
        (bg-box (nano-faces--box nano-color-background))
        (tag-height (nano-faces--tag-height)))
    ;; Core
    (set-face-attribute 'nano-face-default nil
                        :foreground nano-color-foreground
                        :background nano-color-background
                        :family nano-font-family-monospaced
                        :height (* nano-font-size 10))
    (set-face-attribute 'nano-face-variable-pitch nil
                        :foreground nano-color-foreground
                        :background nano-color-background
                        :family (or nano-font-family-proportional 'unspecified)
                        :height (* nano-font-size 10))
    (set-face-attribute 'nano-face-critical nil
                        :foreground nano-color-foreground
                        :background nano-color-critical)
    (set-face-attribute 'nano-face-popout nil :foreground nano-color-popout)
    (set-face-attribute 'nano-face-strong nil
                        :foreground nano-color-strong
                        :weight (if graphic 'medium 'bold))
    (set-face-attribute 'nano-face-salient nil
                        :foreground nano-color-salient :weight 'light)
    (set-face-attribute 'nano-face-faded nil
                        :foreground nano-color-faded :weight 'light)
    (set-face-attribute 'nano-face-subtle nil :background nano-color-subtle)
    (set-face-attribute 'nano-face-fallback nil
                        :family (or nano-font-family-fallback 'unspecified)
                        :inherit 'nano-face-faded)

    ;; Header line
    (set-face-attribute 'nano-face-header-default nil
                        :foreground nano-color-foreground
                        :background header-bg
                        :box bg-box)
    (set-face-attribute 'nano-face-header-strong nil
                        :foreground nano-color-strong
                        :background header-bg
                        :inherit 'nano-face-strong
                        :box bg-box)
    (dolist (name nano-faces--accents)
      (set-face-attribute (intern (format "nano-face-header-%s" name)) nil
                          :foreground nano-color-background
                          :background (nano-faces--color name)
                          :box bg-box))
    (set-face-attribute 'nano-face-header-highlight nil
                        :inherit 'nano-face-header-faded :box nil)
    (set-face-attribute 'nano-face-header-separator nil
                        :inherit 'nano-face-default :height 0.1)
    (set-face-attribute 'nano-face-header-filler nil
                        :inherit 'nano-face-header-default :height 0.1)

    ;; Tags
    (dolist (spec `((default ,nano-color-foreground ,nano-color-background
                             ,nano-color-foreground)
                    (strong ,nano-color-strong ,nano-color-subtle
                            ,nano-color-strong)
                    ,@(mapcar (lambda (name)
                                (let ((color (nano-faces--color name)))
                                  (list name nano-color-background color color)))
                              nano-faces--accents)))
      (pcase-let ((`(,name ,fg ,bg ,box) spec))
        (set-face-attribute (intern (format "nano-face-tag-%s" name)) nil
                            :foreground fg :background bg
                            :weight 'regular :height tag-height
                            :box (nano-faces--box box))))

    ;; nano-command
    (set-face-attribute 'nano-face-command nil
                        :foreground nano-color-foreground
                        :background nano-color-subtle
                        :box (nano-faces--box nano-color-foreground)
                        :inherit nil)
    (set-face-attribute 'nano-face-command-prompt nil
                        :inherit 'nano-face-strong
                        :foreground nano-color-background
                        :background nano-color-foreground
                        :box (nano-faces--box nano-color-foreground))
    (set-face-attribute 'nano-face-command-cursor nil
                        :foreground nano-color-background
                        :background nano-color-foreground)))

(provide 'nano-faces)
;;; nano-faces.el ends here
