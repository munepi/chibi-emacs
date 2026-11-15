> [!NOTE]
> このリポジトリは、[rougier/nano-emacs](https://github.com/rougier/nano-emacs)をもとにした、munepiによる個人的なN Λ N O Emacsの改変版です。
> 日本語環境で常用できることと、Emacs 31（Mac port）で動くことを目的にしています。upstreamへのPRは予定していません。
> 改変はブランチ`munepi/japanese`にあります。
>
> This is a personal, Japanese-oriented modification of N Λ N O Emacs
> by munepi, and is not intended to be merged upstream.

# GNU Emacs / N Λ N O（日本語環境向けの改変版）

![](images/nano-emacs-light.png)
![](images/nano-emacs-dark.png)

upstreamのnano-emacsは、`nano.el`を読み込むとEmacsの設定がまとめて変わる「設定ファイル集」でした。
この改変版は、自分のinit.elから部品として使うためのpackageにしています。

- どのモジュールも、`require`しただけでは設定を変えません。見た目を変えるのは、下の`nano-*-setup`、`nano-theme-set`、`nano-modeline-mode`を呼んだときだけです。
- キー割り当てやmodifier、言語環境などの好みの設定はしません。init.elで決めてください。
- CJKフォントの割り当て（`nano-font-family-cjk`、`nano-font-cjk-rescale`）
- 日本語のバッファ名でもheader-lineの幅が崩れないようにする（`string-width`）
- VS Code Dark Modern配色（構文色はDark+）のテーマ`vscmacs`
- Emacs 29以降が対象です。Emacs 31（Mac port）で使っています。

## モジュール

| モジュール | 内容 |
|---|---|
| `nano-base-colors` | 9つの基本色（`nano-color-*`） |
| `nano-faces` | 基本のface（`nano-face-*`）、フォント、CJKフォントの割り当て |
| `nano-theme` | 配色（`nano-theme-palettes`）と、Emacsや各packageのfaceの割り当て |
| `nano-layout` | フレームの余白、window divider、折り返しの記号 |
| `nano-modeline` | モードごとのheader line（`nano-modeline-mode`） |
| `nano-splash` | 起動時のsplash screen |
| `nano-help` | quick help（`nano-quick-help`）とhelp画面（`nano-help`） |
| `nano-command` | header lineで入力する小さなprompt（`nano-command-x`、`nano-command-shell`） |

`nano-theme-dark`、`nano-theme-light`、`nano-theme-vscmacs`は、以前の設定との互換のためだけに残しています。配色は`nano-theme.el`の`nano-theme-palettes`にあります。

## インストール

ローカルのcheckoutを使う場合：

```elisp
(add-to-list 'load-path "~/work/emacs/nano-emacs")
```

package-vcで入れる場合：

```elisp
(package-vc-install
 '(nano :url "https://github.com/munepi/nano-emacs-ja"
        :branch "munepi/japanese"))
```

## 使い方

```elisp
;; フォント
(setq nano-font-family-monospaced "PlemolJP35 Console NFJ"
      nano-font-family-cjk        "PlemolJP35 Console NFJ"
      nano-font-cjk-rescale       1.0
      nano-font-size              20)

(require 'nano-layout)
(require 'nano-theme)
(require 'nano-modeline)
(require 'nano-splash)
(require 'nano-help)
(require 'nano-command)

;; フレームの余白など。default-frame-alistにまだない値だけを足す
(nano-layout-setup)
;; 配色：light、dark（Nord）、vscmacs（VS Code Dark Modern）
(nano-theme-set 'vscmacs)
(nano-refresh-theme)
;; header line
(nano-modeline-mode 1)
;; splash screen（-no-splashなどがコマンドラインにあれば出さない）
(setq nano-splash-timeout 30)
(nano-splash-setup)

;; キーは好みで
(global-set-key (kbd "M-s-x") #'nano-command-x)
(global-set-key (kbd "M-s-s") #'nano-command-shell)
```

- `M-x nano-toggle-theme`で、lightと、直前に使っていたdark系（darkかvscmacs）を切り替えます。
- `M-x nano-theme-set`で、配色を選んで切り替えます。
- 配色を足すときは、`nano-theme-palettes`に要素を加えます。9色（`:foreground`、`:background`、`:highlight`、`:critical`、`:salient`、`:strong`、`:popout`、`:subtle`、`:faded`）と`:mode`（`light`か`dark`）のほかに、header lineの背景（`:header-background`）、ウィンドウの区切り線（`:border`）、構文色（`:font-lock`）を指定できます。

## 出典とライセンス

N Λ N O Emacsは、Nicolas P. Rougierによるものです。設計の考え方は、論文"[On the design of text Editors](https://arxiv.org/abs/2008.06030)"にあります。
lightの配色は[Material colors](https://material.io/)、darkの配色は[Nord colors](https://www.nordtheme.com/)によります。

ライセンスはGPL-3.0以降です（[LICENSE.txt](LICENSE.txt)）。
