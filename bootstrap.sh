#!/usr/bin/env bash
# polyglot-scripting — Debian / Ubuntu 向けブートストラップ
#
#   tar xzf polyglot-scripting.tar.gz && ./polyglot-scripting/bootstrap.sh
#   PASCAL_DIALECTS=1 を付けると、別プラグイン pascal-dialects も入れる
#
# 冪等。何度走らせても同じ状態に収束する。
# 入っているものは飛ばし、足りないものだけ入れる。

set -euo pipefail

PLUGIN_NAME="polyglot-scripting"
SRC_DIR="$(cd "$(dirname "$0")" && pwd)"
DEST_DIR="${HOME}/.claude/skills/${PLUGIN_NAME}"
BB_DIR="${BB_DIR:-/usr/local/bin}"

# apt パッケージ:
#   fp-compiler + fp-utils = 6 パッケージ (instantfpc はここ)
#   メタパッケージ fpc だと gtk2 や multimedia まで来て 194 パッケージになる
APT_PKGS="fp-compiler fp-utils shellcheck jq curl ca-certificates"

log()  { printf '\033[1m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[33m[warn]\033[0m %s\n' "$*" >&2; }
have() { command -v "$1" >/dev/null 2>&1; }

sudo_if_needed() {
  if [ "$(id -u)" -eq 0 ]; then "$@"; else sudo "$@"; fi
}

# --- 1. apt -----------------------------------------------------------------
install_apt() {
  local missing=""
  for p in $APT_PKGS; do
    dpkg-query -W -f='${Status}' "$p" 2>/dev/null | grep -q "^install ok installed$" || missing="$missing $p"
  done

  if [ -z "$missing" ]; then
    log "apt パッケージ: すべて導入済み"
    return 0
  fi

  log "apt パッケージを導入:$missing"
  sudo_if_needed apt-get update -qq
  # shellcheck disable=SC2086
  sudo_if_needed env DEBIAN_FRONTEND=noninteractive apt-get install -y -qq $missing
}

# --- 2. babashka ------------------------------------------------------------
install_babashka() {
  if have bb; then
    log "babashka: 導入済み ($(bb --version))"
    return 0
  fi
  log "babashka を導入"
  curl -fsSL https://raw.githubusercontent.com/babashka/babashka/master/install \
    | sudo_if_needed bash -s -- --dir "$BB_DIR"
}

# --- 3. プラグイン ----------------------------------------------------------
# ~/.claude/skills/ 配下に置くと <name>@skills-dir として自動ロードされる。
# marketplace 登録も claude plugin install も不要。
install_plugin() {
  if [ "$SRC_DIR" = "$DEST_DIR" ]; then
    log "プラグイン: 既に配置先で実行中"
    return 0
  fi

  log "プラグインを配置: $DEST_DIR"
  mkdir -p "$(dirname "$DEST_DIR")"
  rm -rf "${DEST_DIR}.new"
  cp -r "$SRC_DIR" "${DEST_DIR}.new"
  rm -rf "${DEST_DIR}.old"
  [ -d "$DEST_DIR" ] && mv "$DEST_DIR" "${DEST_DIR}.old"
  mv "${DEST_DIR}.new" "$DEST_DIR"
  rm -rf "${DEST_DIR}.old"
}

# --- 3b. pascal-dialects (任意) -------------------------------------------
# 同じリポジトリの別プラグイン。PASCAL_DIALECTS=1 のときだけ、
# ~/.claude/skills/pascal-dialects にシンボリックリンクを張って pascal-dialects@skills-dir にする。
install_pascal_dialects() {
  [ "${PASCAL_DIALECTS:-0}" = 1 ] || return 0
  log "pascal-dialects を配置: ${HOME}/.claude/skills/pascal-dialects"
  ln -sfn "${DEST_DIR}/pascal-dialects" "${HOME}/.claude/skills/pascal-dialects"
}

# --- 4. 検証 ----------------------------------------------------------------
verify() {
  local rc=0
  log "検証"

  for t in bb instantfpc fpc; do
    if have "$t"; then
      printf '  %-11s %s\n' "$t" "$(command -v "$t")"
    else
      warn "$t が見つかりません"
      rc=1
    fi
  done

  for f in .claude-plugin/plugin.json hooks/hooks.json data/babashka-namespaces.edn; do
    if [ -f "${DEST_DIR}/${f}" ]; then
      printf '  %-11s %s\n' "ok" "$f"
    else
      warn "配置漏れ: $f"
      rc=1
    fi
  done

  if have bb; then
    printf '\n'
    if printf '%s' '{"hook_event_name":"SessionStart"}' \
         | CLAUDE_PLUGIN_ROOT="$DEST_DIR" bb "${DEST_DIR}/hooks/session-context.clj" \
         >/dev/null 2>&1
    then
      log "SessionStart フック: 動作確認 OK"
    else
      warn "SessionStart フックが動きませんでした"
      rc=1
    fi
  fi

  return "$rc"
}

main() {
  if ! have apt-get; then
    warn "apt-get がありません。Debian / Ubuntu 以外では手動で導入してください:"
    warn "  Free Pascal (instantfpc), shellcheck, jq, babashka"
  else
    install_apt
  fi
  install_babashka
  install_plugin
  install_pascal_dialects
  verify

  cat <<'MSG'

--------------------------------------------------------------------
完了。次のセッションから polyglot-scripting@skills-dir として
自動ロードされます。確認は claude 起動後に:

  /plugin        導入済みプラグイン一覧
  /context       Memory files と Custom agents の読み込み状況

既に claude が起動中なら /reload-plugins で反映されます。
--------------------------------------------------------------------
MSG
}

main "$@"
