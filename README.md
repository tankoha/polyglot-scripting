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
├── .claude-plugin/plugin.json
├── bootstrap.sh                          冪等なブートストラップ (Debian/Ubuntu)
├── data/babashka-namespaces.edn          ← 許可リストの正本
├── hooks/
│   ├── hooks.json
│   ├── guard-adhoc-script.clj            PreToolUse(Write|Edit)  ← 本命
│   ├── guard-interpreter.clj             PreToolUse(Bash)
│   ├── lint-script.clj                   PostToolUse(Write|Edit)
│   └── session-context.clj               SessionStart
├── scripts/gen-reference.clj             edn → references/babashka.md 再生成
└── skills/polyglot-scripting/
    ├── SKILL.md
    └── references/
        ├── babashka.md                   ← 自動生成。直接編集しない
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

```bash
tar xzf polyglot-scripting.tar.gz && ./polyglot-scripting/bootstrap.sh
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

開発中に配置せず試すなら `--plugin-dir` が使える:

```bash
claude --plugin-dir ./polyglot-scripting
claude plugin validate ./polyglot-scripting
```

複数環境に配るなら git リポジトリにして marketplace 経由にする。以後の更新が一箇所で済む。

```json
{
  "name": "personal-marketplace",
  "plugins": [
    {
      "name": "polyglot-scripting",
      "source": { "type": "github", "owner": "YOUR_NAME", "repo": "polyglot-scripting" }
    }
  ]
}
```

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
