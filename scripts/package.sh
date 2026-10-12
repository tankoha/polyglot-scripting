#!/usr/bin/env bash
# 配布物を dist/ に作る。git archive を使うので、コミット済みの内容だけが入る。
#
#   scripts/package.sh [ref]     ref 省略時は HEAD
#
# 作るもの:
#   polyglot-scripting-<ver>.plugin   プラグイン本体のみ (zip)。デスクトップ版のアップロード用
#   polyglot-scripting-<ver>.tar.gz   bootstrap.sh 込みの全体。ツールごと入れたい環境向け
#
# ref がタグ (v*) のときは、タグと plugin.json の version の一致を検査する。

set -euo pipefail

NAME="polyglot-scripting"
REF="${1:-HEAD}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

VERSION="$(git show "${REF}:.claude-plugin/plugin.json" | jq -r .version)"
if [ -z "$VERSION" ] || [ "$VERSION" = "null" ]; then
  echo "plugin.json に version がありません" >&2
  exit 1
fi

case "$REF" in
  v*)
    if [ "$REF" != "v${VERSION}" ]; then
      echo "タグ ${REF} と plugin.json の version ${VERSION} が一致しません" >&2
      exit 1
    fi
    ;;
esac

mkdir -p dist
PLUGIN="dist/${NAME}-${VERSION}.plugin"
TARBALL="dist/${NAME}-${VERSION}.tar.gz"

# .plugin: アーカイブ直下に .claude-plugin/plugin.json が来る形。
# marketplace.json はリポジトリを marketplace として登録するためのもので、プラグインには不要
git archive --format=zip -o "$PLUGIN" "$REF" -- \
  .claude-plugin/plugin.json hooks skills data README.md

# tar.gz: 従来どおり polyglot-scripting/ 配下に全体を入れる
git archive --format=tar.gz --prefix="${NAME}/" -o "$TARBALL" "$REF"

ls -l "$PLUGIN" "$TARBALL"
