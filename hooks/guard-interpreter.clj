#!/usr/bin/env bb
;; PreToolUse(Bash) — アドホックな Python / Node.js 実行をブロックする。
;;
;; 設計方針:
;;   捕まえるのは「その場限りのスクリプティング」の形だけ。
;;   プロジェクト本来のツールチェーン（pytest / npm test / node dist/server.js /
;;   python manage.py migrate 等）は通す。ここを広く取るとPythonリポジトリで
;;   Claude Code が使い物にならなくなるため、意図的に狭くしてある。
;;
;; 終了コード:
;;   2 = ブロック（permissionDecisionReason が Claude に渡り、自己修正を促す）
;;   0 = 判断なし（通常の権限フローへ）
;;   その他 = 非ブロッキングエラー。bb が無い環境ではここに落ちて素通りする
;;            （フェイルオープン。bb が無い＝そもそもこのポリシーが成立しない環境）

(require '[cheshire.core :as json]
         '[clojure.string :as str])

;; ---------------------------------------------------------------------------
;; 検出パターン: [正規表現 説明]
;; (?m) は ^ を行頭にも効かせるため（複合コマンド対策）
;; ---------------------------------------------------------------------------
(def patterns
  [[#"(?m)(?:^|[;&|]\s*|\$\(\s*)(?:python3?|node|deno|bun)\s+(?:-[A-Za-z]+\s+)*-(?:c|e)\b"
    "インタプリタへのインラインコード指定 (-c / -e)"]

   [#"(?m)(?:^|[;&|]\s*)(?:python3?|node|deno|bun)\b[^|;&\n]*<<[-~]?\s*['\"]?\w+"
    "インタプリタへのヒアドキュメント入力"]

   [#"(?m)(?:^|[;&|]\s*)(?:python3?|node)\s+(?:/tmp/|/var/tmp/)\S+"
    "一時ディレクトリ上の使い捨てスクリプトの実行"]])

;; `cd /tmp/.../scratchpad && python3 primes.py` のように、cd してから相対パスで
;; 叩かれる形は上のパターンで捕まらない。インタプリタ起動と一時領域への言及が
;; 同じコマンドに同居していたら、使い捨てスクリプトの実行とみなす。
;;
;; ただしこれは保険であって、本命の防御は PreToolUse(Write|Edit) 側にある。
;; cwd が既に scratchpad の状態で `python3 primes.py` だけ叩かれると、
;; コマンド文字列からは正規のプロジェクト実行と区別がつかない。
;; ファイルを作らせない方が確実。guard-adhoc-script.clj を参照。
;; 「一時領域への言及があれば一律ブロック」にすると、Python エコシステムの
;; 正当な利用を巻き込む。実測した誤検知:
;;   python3 -m venv /tmp/venv
;;   python3 -m pip install --cache-dir /tmp/c requests
;;   node build.js --out /tmp/x
;; よって「一時領域上のスクリプトファイルを渡している」か「一時領域に cd して
;; から起動している」に限定する。-m でモジュールを起動する形や、一時領域を
;; 単なる出力先・キャッシュ先として渡す形は通す。
(def interpreter-invocation
  #"(?m)(?:^|[;&|]\s*)(?:python3?|node|deno|bun)\s")

(def interpreter-script-in-tmp
  #"(?m)(?:^|[;&|]\s*)(?:python3?|node|deno|bun)\s+[^;&|\n]*(?:/tmp/|/var/tmp/)\S*\.(?:py|js|mjs|cjs|ts)\b")

(def cd-into-ephemeral
  #"(?m)\bcd\s+[\"']?(?:/tmp/|/var/tmp/)")

(defn ephemeral-workspace-run?
  [cmd scratchpad-dir]
  (and (re-find interpreter-invocation cmd)
       (or (re-find interpreter-script-in-tmp cmd)
           (re-find cd-into-ephemeral cmd)
           (and (not (str/blank? (or scratchpad-dir "")))
                (str/includes? cmd scratchpad-dir)))))

;; コマンド末尾に ' # policy:allow' を付けると素通しする脱出ハッチ。
;; 完全に塞ぎたい場合はこの行を消すか、settings の permissions.deny に移すこと
;; （README の「脱出ハッチについて」を参照）。
(def escape-hatch #"#\s*policy:allow")

(def reason-body
  (str "アドホックなスクリプトは Python / Node.js ではなく "
       "Babashka (bb) か instantfpc で書いてください。\n"
       "  - JSON/YAML/HTTP/テキストパイプライン処理 -> bb\n"
       "  - 性能重視・低レイヤ・バイナリ/ファイル操作 -> instantfpc\n"
       "  - 1行で済むテキスト処理なら、そもそも grep/sed/awk で十分なはずです\n"
       "詳細は polyglot-scripting スキルを参照。\n"
       "プロジェクト本来のツールチェーン実行でどうしても必要な場合のみ、"
       "コマンド末尾に ' # policy:allow' を付けて再実行してください。"))

(defn deny! [why]
  (println
   (json/generate-string
    {:hookSpecificOutput
     {:hookEventName "PreToolUse"
      :permissionDecision "deny"
      :permissionDecisionReason
      (str "スクリプティングポリシー違反: " why "\n\n" reason-body)}}))
  (System/exit 2))

(defn -main []
  (let [input      (json/parse-string (slurp *in*) true)
        cmd        (or (get-in input [:tool_input :command]) "")
        scratchpad (:scratchpad_dir input)]
    (when-not (str/blank? cmd)
      (when-not (re-find escape-hatch cmd)
        (when-let [why (some (fn [[re why]] (when (re-find re cmd) why)) patterns)]
          (deny! why))
        (when (ephemeral-workspace-run? cmd scratchpad)
          (deny! "一時作業領域での使い捨てスクリプトの実行"))))
    (System/exit 0)))

(-main)
