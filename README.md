> [!NOTE]
> chibi Emacsは、[N Λ N O Emacs](https://github.com/rougier/nano-emacs)をもとにした、munepiによる個人的なpackageです。
> 日本語環境で常用できることと、Emacs 31（Mac port）で動くことを目的にしています。
> 元はnano-emacsのfork（nano-emacs-ja）でしたが、だいぶ書き換えたので名前を変えました。upstreamへのPRは予定していません。
>
> chibi Emacs is a personal, Japanese-friendly derivative of N Λ N O Emacs
> by munepi, and is not intended to be merged upstream.

# chibi Emacs

upstreamのnano-emacsは、`nano.el`を読み込むとEmacsの設定がまとめて変わる「設定ファイル集」でした。
chibi Emacsは、自分のinit.elから部品として使うためのpackageにしています。

- どのモジュールも、`require`しただけでは設定を変えません。見た目を変えるのは、下の`chibi-*-setup`、`chibi-theme-set`、`chibi-modeline-mode`を呼んだときだけです。
- キー割り当てやmodifier、言語環境などの好みの設定はしません。init.elで決めてください。
- CJKフォントの割り当て（`chibi-font-family-cjk`、`chibi-font-cjk-rescale`）
- 日本語のバッファ名でもheader-lineの幅が崩れないようにする（`string-width`）
- VS Code Dark Modern配色（構文色はDark+）のテーマ`vscmacs`
- Emacs 29以降が対象です。Emacs 31（Mac port）で使っています。

## モジュール

| モジュール | 内容 |
|---|---|
| `chibi-base-colors` | 9つの基本色（`chibi-color-*`） |
| `chibi-faces` | 基本のface（`chibi-face-*`）、フォント、CJKフォントの割り当て |
| `chibi-theme` | 配色（`chibi-theme-palettes`）と、Emacsや各packageのfaceの割り当て |
| `chibi-layout` | フレームの余白、window divider、折り返しの記号 |
| `chibi-modeline` | モードごとのheader line（`chibi-modeline-mode`） |
| `chibi-splash` | 起動時のsplash screen |
| `chibi-help` | quick help（`chibi-quick-help`）とhelp画面（`chibi-help`） |
| `chibi-command` | header lineで入力する小さなprompt（`chibi-command-x`、`chibi-command-shell`） |

## インストール

ローカルのcheckoutを使う場合：

```elisp
(add-to-list 'load-path "~/work/emacs/chibi-emacs")
```

package-vcで入れる場合：

```elisp
(package-vc-install
 '(chibi :url "https://github.com/munepi/chibi-emacs"
         :branch "main"))
```

## 使い方

```elisp
;; フォント
(setq chibi-font-family-monospaced "PlemolJP35 Console NFJ"
      chibi-font-family-cjk        "PlemolJP35 Console NFJ"
      chibi-font-cjk-rescale       1.0
      chibi-font-size              20)

(require 'chibi-layout)
(require 'chibi-theme)
(require 'chibi-modeline)
(require 'chibi-splash)
(require 'chibi-help)
(require 'chibi-command)

;; フレームの余白など。default-frame-alistにまだない値だけを足す
(chibi-layout-setup)
;; 配色：light、dark（Nord）、vscmacs（VS Code Dark Modern）
(chibi-theme-set 'vscmacs)
(chibi-refresh-theme)
;; header line
(chibi-modeline-mode 1)
;; splash screen（-no-splashなどがコマンドラインにあれば出さない）
(setq chibi-splash-timeout 30)
(chibi-splash-setup)

;; キーは好みで
(global-set-key (kbd "M-s-x") #'chibi-command-x)
(global-set-key (kbd "M-s-s") #'chibi-command-shell)
```

- `M-x chibi-toggle-theme`で、lightと、直前に使っていたdark系（darkかvscmacs）を切り替えます。
- `M-x chibi-theme-set`で、配色を選んで切り替えます。
- 配色を足すときは、`chibi-theme-palettes`に要素を加えます。9色（`:foreground`、`:background`、`:highlight`、`:critical`、`:salient`、`:strong`、`:popout`、`:subtle`、`:faded`）と`:mode`（`light`か`dark`）のほかに、header lineの背景（`:header-background`）、ウィンドウの区切り線（`:border`）、構文色（`:font-lock`）を指定できます。

## 出典とライセンス

chibi Emacsは、Nicolas P. RougierによるN Λ N O Emacsをもとにしています。N Λ N O Emacsの設計の考え方は、論文"[On the design of text Editors](https://arxiv.org/abs/2008.06030)"にあります。
lightの配色は[Material colors](https://material.io/)、darkの配色は[Nord colors](https://www.nordtheme.com/)によります。

ライセンスはGPL-3.0以降です（[LICENSE.txt](LICENSE.txt)）。
