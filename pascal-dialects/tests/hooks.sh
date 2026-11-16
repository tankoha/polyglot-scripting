#!/usr/bin/env bash
# shellcheck disable=SC2016  # {$mode} などは Pascal の文字列で、展開しない
# pascal-guard.clj を合成ペイロードで試す。状態は使い捨てのディレクトリに置く。
#   tests/hooks.sh
set -euo pipefail
here=$(cd "$(dirname "$0")/.." && pwd)
hook=$here/hooks/pascal-guard.clj
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
export CLAUDE_PLUGIN_DATA=$work/state
fail=0

# payload <tool> <file_path> <content> [skill]: Claude Code のフック入力を JSON で出す
payload() {
  bb -e '(let [[t f c] *command-line-args*]
           (println (cheshire.core/generate-string
                     {:session_id "s1" :tool_name t
                      :tool_input (if (= t "Skill") {:skill f} {:file_path f :content c :new_string c})})))' "$@"
}

# expect <説明> <guard|verify> <deny|block|pass> <tool> <file_path> [content]
expect() {
  local desc=$1 cmd=$2 want=$3 got out
  shift 3
  out=$(payload "$@" | bb "$hook" "$cmd")
  case $out in
    *'"deny"'*) got=deny ;;
    *'"block"'*) got=block ;;
    '') got=pass ;;
    *) got="?($out)" ;;
  esac
  if [ "$got" = "$want" ]; then echo "OK  $desc"; else echo "NG  $desc: want=$want got=$got"; fail=1; fi
}

mkdir -p "$work/inc" "$work/dproj" "$work/plain"
printf '{$mode objfpc}{$H+}\n' > "$work/inc/proj.inc"
touch "$work/dproj/App.dproj"
good='{$mode objfpc}{$H+}
program p; begin writeln(1) end.'
bad='{$mode objfpc}{$H+}
program p; begin writeln(1 end.'

expect "方言なしは止める"                guard deny  Write "$work/plain/a.pas" 'program p; begin end.'
expect "objfpc はスキル前なら止める"      guard deny  Write "$work/plain/a.pas" "$good"
expect "instantfpc スクリプトは通す"      guard pass  Write "$work/plain/s.pas" '#!/usr/bin/env instantfpc
program s; begin end.'
expect "Pascal 以外は通す"               guard pass  Write "$work/plain/a.txt" 'x'
expect "Skill の記録"                    guard pass  Skill "pascal-dialects:pascal-fpc-objfpc"
expect "objfpc はスキル後なら通す"        guard pass  Write "$work/plain/a.pas" "$good"
expect "{\$I} の mode を拾う"            guard pass  Write "$work/inc/u.pas" '{$I proj.inc}
unit u; interface implementation end.'
expect "unleashed は別スキルが要る"       guard deny  Write "$work/plain/b.pas" '{$mode unleashed}
program b; begin end.'
expect ".dproj 配下は Delphi"            guard deny  Write "$work/dproj/u.pas" 'unit u; interface implementation end.'
expect "namespace は Oxygene"            guard deny  Write "$work/plain/o.pas" 'namespace Foo;
end.'

printf '%s\n' "$good" > "$work/plain/ok.pas"
printf '%s\n' "$bad" > "$work/plain/ng.pas"
printf 'unit d; interface implementation end.\n' > "$work/dproj/d.pas"
printf '{$mode objfpc}\nprogram m; uses NoSuchUnit; begin end.\n' > "$work/plain/missing.pas"
expect "verify: 通るソースは何も言わない"   verify pass  Write "$work/plain/ok.pas" ''
expect "verify: エラーを返す"              verify block Write "$work/plain/ng.pas" ''
expect "verify: Delphi はコンパイルしない"  verify pass  Write "$work/dproj/d.pas" ''
expect "verify: ユニット不明だけなら黙る"   verify pass  Write "$work/plain/missing.pas" ''

exit $fail
