#!/usr/bin/env bash
# スキルの few-shot 例と落とし穴の例を、実際のコンパイラで検証する。
#   examples/*.pas|*.dpr : コンパイルが通り、実行結果が同名の .expected と一致すること
#   pitfalls/*.pas|*.dpr : コンパイルが失敗し、エラーに "expect-error:" で書いた文字列が含まれること
# 使い方: check-examples.sh [スキル名...]   (省略時は全スキル)
#
# 方言ごとの検証方法
#   pascal-fpc-objfpc / pascal-fpc-delphi : 標準 FPC 3.2.2
#   pascal-unleashed                      : Unleashed Pascal の fpc
#   pascal-delphi  : 本物の Delphi はこの環境にないので、Unleashed の fpc (3.3.1 ベース) で近似検証する。
#                    -Mdelphiunicode に inline var・無名メソッドの modeswitch を足し、
#                    名前空間付きのユニット名 (System.SysUtils など) は FPC の名前に置き換えた写しをコンパイルする。
#   pascal-oxygene : コンパイラがないので検証しない (例は未検証と明記している)
set -euo pipefail
here=$(cd "$(dirname "$0")/.." && pwd)
fpc_stock=${FPC_STOCK:-/usr/bin/fpc}
fpc_unleashed=${FPC_UNLEASHED:-$HOME/unleashed/fpc/bin/fpc}
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

# Delphi の名前空間付きユニット名を FPC のユニット名にした写しを作る
delphi_copy() {
  sed -E -e 's/\bSystem\.(SysUtils|Classes|Math|StrUtils|DateUtils|Types|Variants|TypInfo|Rtti)\b/\1/g' \
         -e 's/\bSystem\.Generics\.(Collections|Defaults)\b/Generics.\1/g' "$1" > "$2"
}

# compile <skill> <src> <outdir>: コンパイルし、ログを <outdir>/compile.log に書く
compile() {
  local skill=$1 src=$2 out=$3
  case $skill in
    pascal-unleashed)
      "$fpc_unleashed" -vew -l- -FE"$out" -FU"$out" "$src" ;;
    pascal-delphi)
      local copy
      copy=$out/$(basename "$src")
      delphi_copy "$src" "$copy"
      "$fpc_unleashed" -Mdelphiunicode -Manonymousfunctions -Mfunctionreferences -Minlinevars \
        -vew -l- -FE"$out" -FU"$out" "$copy" ;;
    *)
      "$fpc_stock" -vew -l- -FE"$out" -FU"$out" "$src" ;;
  esac > "$out/compile.log" 2>&1
}

fail=0
skills=${*:-$(cd "$here/skills" && ls)}
for skill in $skills; do
  dir=$here/skills/$skill
  if [ "$skill" = pascal-oxygene ]; then
    echo "SKIP $skill: コンパイラがないため検証しない"
    continue
  fi
  for src in "$dir"/examples/*.pas "$dir"/examples/*.dpr; do
    [ -e "$src" ] || continue
    base=$(basename "$src")
    name=${base%.*}
    out=$work/$skill-$name
    mkdir -p "$out"
    if ! compile "$skill" "$src" "$out"; then
      echo "NG  $skill/examples/$name: コンパイル失敗"
      sed 's/^/      /' "$out/compile.log" | tail -5
      fail=1
      continue
    fi
    if ! (cd "$out" && "./$name") > "$out/run.txt" 2>&1; then
      echo "NG  $skill/examples/$name: 実行時エラー"
      fail=1
      continue
    fi
    if ! diff -u "${src%.*}.expected" "$out/run.txt" > "$out/diff.txt"; then
      echo "NG  $skill/examples/$name: 出力が期待と違う"
      sed 's/^/      /' "$out/diff.txt"
      fail=1
      continue
    fi
    echo "OK  $skill/examples/$name"
  done
  for src in "$dir"/pitfalls/*.pas "$dir"/pitfalls/*.dpr; do
    [ -e "$src" ] || continue
    base=$(basename "$src")
    name=${base%.*}
    out=$work/$skill-pit-$name
    mkdir -p "$out"
    want=$(sed -n 's/.*expect-error: *\(.*[^ ]\) *}.*/\1/p' "$src" | head -1)
    if compile "$skill" "$src" "$out"; then
      echo "NG  $skill/pitfalls/$name: コンパイルが通ってしまった (誤りの例のはず)"
      fail=1
    elif [ -n "$want" ] && ! grep -qF -- "$want" "$out/compile.log"; then
      echo "NG  $skill/pitfalls/$name: 想定のエラー「$want」が出ない"
      sed 's/^/      /' "$out/compile.log" | grep -iE 'error|fatal' | head -3
      fail=1
    else
      echo "OK  $skill/pitfalls/$name"
    fi
  done
done
exit $fail
