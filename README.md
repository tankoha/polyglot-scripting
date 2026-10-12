# polyglot-scripting

bash / Babashka / instantfpc のスクリプティング方針を、各環境に配布するための Claude Code プラグイン。

`.claude/CLAUDE.md` を各リポジトリにワンライナーで注入する運用を置き換える。

## なぜ3層に分けるのか

元の運用は、性質の違う3種類の情報を1つの常時ロードされるファイルに混ぜていた。

| 情報の性質 | 必要なロードタイミング | 必要な効き方 |
|---|---|---|
| Python/Node 禁止、`set -euo pipefail` 必須 | 判断の**前** | **決定論的**（散文では守られない） |
| 言語の選択規則 | 判断の**前** | 文脈として常時 |
| テンプレート、名前空間一覧 | 書く**直前**だけ | 参照できれば良い |

3つ目を常時ロードするのは無駄で、1つ目を散文で書くのは効かない。よって分ける。

```
強制     hooks/guard-adhoc-script.clj  PreToolUse(Write|Edit)   作業領域への .py/.js 作成をブロック
         hooks/guard-interpreter.clj   PreToolUse(Bash)         python -c / node -e をブロック
         hooks/lint-script.clj         PostToolUse(Write|Edit)  未許可 require をブロック、品質警告
判断規則  hooks/session-context.clj     SessionStart             選択規則を文脈に注入（約400トークン）
参照資料  skills/polyglot-scripting/    オンデマンド              テンプレート、名前空間一覧
```

強制層の本命は **Write 層**であって Bash 層ではない。Claude のアドホックスクリプティングは
`python -c` ではなく「scratchpad に `.py` を書いて実行する」形で現れる。実行時のコマンド
`python3 primes.py` は正規のプロジェクトスクリプト実行と区別がつかないため、Bash 層では
原理的に閉じられない。ファイルを作らせない方が確実。

**プラグインは CLAUDE.md を配布できない**（公式仕様）。判断規則層が SessionStart フックの
`additionalContext` になっているのはそのため。副次的に、バージョンを固定値で書く代わりに
その環境の実測値を注入できるようになっている。`instantfpc` が無い環境では「未検出」と
報告するので、使えない経路を提案しなくなる。

## 構成

```
polyglot-scripting/
├── .claude-plugin/
│   ├── plugin.json
│   └── marketplace.json                  リポジトリ自体を marketplace として登録する用
├── .github/workflows/release.yml         v* タグで Releases に配布物を添付
├── bootstrap.sh                          冪等なブートストラップ (Debian/Ubuntu)
├── data/babashka-namespaces.edn          ← 許可リストの正本
├── hooks/
│   ├── hooks.json
│   ├── guard-adhoc-script.clj            PreToolUse(Write|Edit)  ← 本命
│   ├── guard-interpreter.clj             PreToolUse(Bash)
│   ├── lint-script.clj                   PostToolUse(Write|Edit)
│   └── session-context.clj               SessionStart
├── scripts/
│   ├── gen-reference.clj                 edn → references/babashka.md 再生成
│   └── package.sh                        .plugin と tar.gz を dist/ に作る
└── skills/
    ├── comment-style/SKILL.md            ドキュメントコメントの構造規約
    └── polyglot-scripting/
        ├── SKILL.md
        └── references/
            ├── babashka.md               ← 自動生成。直接編集しない
            └── instantfpc.md
```

`data/babashka-namespaces.edn` が単一の情報源になっている。ここを直せば、
フック（強制）と参照資料の両方に反映される。参照資料側の再生成:

```bash
bb scripts/gen-reference.clj
```

フックスクリプト自身も Babashka で書いてある。`jq` への依存を持たずに済み、
方針自体のドッグフーディングにもなる。

## 導入

経路は3つある。**どの経路でも、ポリシーが効くには `bb` が PATH にあることが前提**
（[前提](#前提) を参照）。プラグインとして入れる2経路はツールを導入しない。

| 経路 | 向いている環境 | ツール導入 |
|---|---|---|
| [bootstrap.sh](#bootstrapsh) | Debian / Ubuntu で全部まとめて入れたい | する |
| [marketplace](#marketplace) | Claude Code CLI でプラグインだけ入れたい | しない |
| [.plugin ファイル](#plugin-ファイル) | デスクトップ版でアップロードしたい、オフラインで配りたい | しない |

### bootstrap.sh

[Releases](https://github.com/tankoha/polyglot-scripting/releases) から
`polyglot-scripting-<version>.tar.gz` を取得して:

```bash
tar xzf polyglot-scripting-*.tar.gz && ./polyglot-scripting/bootstrap.sh
```

`bootstrap.sh` は冪等で、以下を行う（Debian / Ubuntu）:

1. `fp-compiler` `fp-utils` `shellcheck` `jq` を apt で導入（`instantfpc` は `fp-utils` 収録）
2. babashka を GitHub リリースから `/usr/local/bin` へ導入
3. このディレクトリを `~/.claude/skills/polyglot-scripting/` へ配置
4. ツールの所在と SessionStart フックの動作を検証

`~/.claude/skills/` 配下に置かれたものは **`polyglot-scripting@skills-dir` として自動ロード**される。
marketplace 登録も `claude plugin install` も不要。起動中のセッションには `/reload-plugins` で反映。

メタパッケージ `fpc` ではなく `fp-compiler` + `fp-utils` を使っているのは、
前者が gtk2 / multimedia / fp-ide / fp-docs まで引いて 194 パッケージになるため
（実測: Ubuntu 24.04 LTS で 194 対 6）。

### marketplace

このリポジトリ自体が marketplace になっている（`.claude-plugin/marketplace.json`）。
Claude Code 内で:

```
/plugin marketplace add tankoha/polyglot-scripting
/plugin install polyglot-scripting@polyglot-scripting
```

シェルからなら `claude plugin marketplace add` / `claude plugin install` で同じことができる。
更新は `plugin.json` の `version` を上げて push するだけで各環境に届く。

bootstrap.sh で入れた環境に重ねて入れると、marketplace 版が優先され `@skills-dir` 版はロードされない
（同名衝突。`claude plugin list` に理由が出る）。ツールの導入だけ bootstrap.sh に任せ、
プラグインの更新は marketplace で受ける、という併用もできる。

### .plugin ファイル

[Releases](https://github.com/tankoha/polyglot-scripting/releases) の
`polyglot-scripting-<version>.plugin` は、プラグイン本体だけを zip にしたもの
（アーカイブ直下に `.claude-plugin/plugin.json`）。デスクトップ版のプラグイン
アップロードに渡す。アップロード画面が `.zip` しか受け付けない版では、拡張子を
`.zip` に変えれば通る。

### 開発中に試す

配置せずに試すなら `--plugin-dir` が使える:

```bash
claude --plugin-dir ./polyglot-scripting
claude plugin validate ./polyglot-scripting
```

### リリース

`plugin.json` の `version` を上げてコミットし、同じ番号のタグを push する:

```bash
git tag v0.3.0 && git push origin v0.3.0
```

GitHub Actions が `scripts/package.sh` で `.plugin` と `tar.gz` を作り、Releases に添付する。
タグと `version` が食い違っていると失敗する。手元で配布物だけ作るなら `scripts/package.sh`
（`dist/` に出力。コミット済みの内容だけが入る）。

## 前提

`bb` が PATH にあること。無い場合、フックは非ブロッキングエラーになり**素通りする**
（フェイルオープン）。bb が無い環境ではそもそもこのポリシーが成立しないため、
セッションを壊すより素通りさせる方が正しい失敗の仕方だと判断している。

`shellcheck` と `rawpaco` は任意。あれば PostToolUse で自動的に呼ばれる。

## 動作確認済みの判定

`guard-adhoc-script.clj` — PreToolUse(Write|Edit):

| ブロックする | 通す |
|---|---|
| scratchpad の `.py` `.js` `.mjs` `.ts` | scratchpad の `.bb` `.pas` `.md` |
| `/tmp` `/var/tmp` 直下の同拡張子 | プロジェクト内の `.py` `.ts` |
| | `/tmp/repo/src/main.py`（clone したツリー） |
| | venv 内の `.py` |
| | 内容に `policy:allow` を含むもの |

`guard-interpreter.clj` — PreToolUse(Bash):

| ブロックする | 通す |
|---|---|
| `python3 -c "..."` | `pytest tests/` |
| `node -e "..."` | `npm test` |
| `python3 <<'EOF'` | `node dist/server.js` |
| `cat x \| python -c "..."` | `python manage.py migrate` |
| `python /tmp/scratch.py` | `python3 -m venv /tmp/venv` |
| `cd <scratchpad> && python3 primes.py` | `python3 -m pip install --cache-dir /tmp/c x` |
| `cd /tmp/x && python3 ./primes.py` | `node build.js --out /tmp/x` |
| | `pip` `ansible` `aws` `pytest` `black` `ruff` `uv` |
| | `/tmp/venv/bin/python app.py` |

`lint-script.clj` — PostToolUse(Write|Edit):

| ブロックする | 通す |
|---|---|
| `.bb` で `clj-http.client` を require | `.bb` で `babashka.fs` を require |
| | `.clj`（bb shebang 無し = JVM プロジェクト） |

実機（Ubuntu Server, Claude Code v2.1.278）で、`python3 -c "print(1)"` が
ブロックされ Claude が `echo 1` に切り替えることを確認済み。

## 設計上のトレードオフ

**脱出ハッチについて。** `guard-interpreter.clj` は、コマンド末尾に `# policy:allow` が
あれば素通しする。プロジェクト本来のツールチェーンを誤検知した際に詰まないための措置だが、
裏を返せば Claude が常にこれを付けて回避できてしまう。完全に塞ぐなら該当行を削除するか、
`permissions.deny` に移す。そこは運用の好みの問題。

**検出範囲を狭くしてある。** 捕まえるのは「その場限りのスクリプティング」の形だけで、
プロジェクト本来の python/node 実行は通す。ここを広く取ると Python リポジトリで
Claude Code が使い物にならなくなる。`sh -c 'python -c ...'` のような入れ子は抜ける。

**Python エコシステムの正当な利用は塞がない。** ブロック対象は「Claude がその場で書いた
使い捨てスクリプト」だけで、Python 製ツールの実行や Python プロジェクトの開発は通す。
`pip` `ansible` `aws` `pytest` `black` `ruff` `uv`、`python -m venv`、`python -m pip`、
`python -m http.server`、`python setup.py`、venv 内の python、プロジェクト内の `.py` 編集
はいずれも通過する（実測済み）。

判定の境界は2つだけ:

- **Bash 層** — 一時領域上の `.py` / `.js` をインタプリタに渡しているか、一時領域に `cd`
  してから起動しているか。`-m` でモジュールを起動する形や、一時領域を単なる出力先・
  キャッシュ先として渡す形は通す。
- **Write 層** — scratchpad 配下、または `/tmp` `/var/tmp` の**直下**のファイル。
  `/tmp/repo/src/main.py` のようなツリーは clone してきたプロジェクトの可能性があるため通す。

この緩和の代償として、`mkdir /tmp/x && (write /tmp/x/a.py)` は Write 層をすり抜ける。
ただし実行しようとした時点で Bash 層の `cd /tmp/...` 判定に掛かる。

**プロジェクト直下に `.py` を書かれると抜ける。** `/home/user/proj/scratch.py` は正規の
Python プロジェクトのソースと区別がつかないため通す。閉じるなら「そのプロジェクトに
既存の `.py` が無ければアドホック」という判定を足すことになるが、誤検知とのトレードオフ。

**ブロックするのは未許可 require だけ。** `set -euo pipefail` 欠落は警告に留めてある。
他人が書いた既存スクリプトを編集した場合に誤発火しうるため。厳しくするなら
`lint-script.clj` の該当箇所を `advise!` から `block!` に変える。

**PreToolUse は Bash 呼び出しのたびに走る。** bb の起動コストが毎回乗る。
実測値は **31 ms/呼び出し**（Linux x86_64, bb 1.13.222, 20回平均）。
体感できる水準ではないはずだが、遅い環境で気になる場合は `hooks.json` の `if` フィールドで
`"if": "Bash(python*)"` のように絞り込む余地がある。
