#!/usr/bin/env bb
;; SessionStart — 判断規則を毎セッションの文脈に注入する。
;;
;; なぜフックで注入するのか:
;;   プラグインは CLAUDE.md を配布できない（公式仕様）。一方この「言語の選択規則」は、
;;   Claude が「Python を使おう」と判断する *前* に効いている必要があり、
;;   オンデマンドで読まれるスキルでは間に合わない。よって SessionStart の
;;   additionalContext が唯一の正しい経路になる。
;;
;; 副次的な利点:
;;   バージョンを本文に固定値で書く代わりに、その環境の実測値を注入できる。
;;   ばらまいた先で「babashka v1.13.219 を想定」が嘘になる問題が消える。
;;   instantfpc が無い環境ではその旨を伝えるので、使えない経路を提案しなくなる。
;;
;; 分量は意図的に短くしてある。CLAUDE.md と同じく毎セッション課金される領域なので、
;; 参照資料（テンプレート、名前空間一覧）はここに置かずスキル側に置くこと。

(require '[cheshire.core :as json]
         '[clojure.string :as str]
         '[babashka.fs :as fs]
         '[babashka.process :refer [shell]])

(defn probe
  "cmd を実行して1行目を返す。無ければ nil。"
  [cmd & args]
  (when (fs/which cmd)
    (try
      (let [{:keys [out err exit]} (apply shell {:out :string :err :string :continue true} cmd args)
            text (str/trim (str out err))]
        (when (and (zero? exit) (not (str/blank? text)))
          (first (str/split-lines text))))
      (catch Exception _ nil))))

(defn tool-line [label cmd version]
  (if version
    (format "- %s: %s (%s)" label version (str (fs/which cmd)))
    (format "- %s: **未検出** — この環境ではこの経路を提案しないこと" label)))

(def rules
  ["# スクリプティング方針"
   ""
   "1. 1行で完結するテキスト処理・パイプラインは、無理に言語化せず bash / grep / sed / awk を使う。"
   "   複数行スクリプトとして書く場合は先頭に `set -euo pipefail` を置く。"
   "   ksh や POSIX sh で実行される可能性を意識し、Bash 専用構文 (`[[`, `<()` 等) に過度に依存しない。"
   "2. 複雑なロジックや構造化データ処理が必要な場合のみ Babashka または instantfpc を使う。"
   "   **Python と Node.js は使用しない**（アドホック実行は PreToolUse フックでブロックされる）。"
   "3. 使い分け:"
   "   - Babashka (Clojure): JSON/YAML 処理、HTTP 通信、一般的なテキストパイプライン処理"
   "   - instantfpc (Free Pascal): 性能重視の処理、低レイヤ操作、バイナリ/ファイル操作"
   "4. テンプレート、利用可能な組み込み名前空間の一覧、記述ルールの詳細は"
   "   **polyglot-scripting スキル**にある。bb / instantfpc のコードを書く前に読むこと。"])

(defn -main []
  (let [bb   (probe "bb" "--version")
        ifpc (or (probe "instantfpc" "--version") (probe "instantfpc" "-h"))
        fpc  (probe "fpc" "-iV")
        ctx  (str/join
              "\n"
              (concat rules
                      [""
                       "## この環境で実際に検出されたツール"
                       (tool-line "babashka" "bb" bb)
                       (tool-line "instantfpc" "instantfpc" ifpc)]
                      (when fpc [(format "- fpc: %s" fpc)])))]
    (println (json/generate-string
              {:hookSpecificOutput
               {:hookEventName "SessionStart"
                :additionalContext ctx}}))
    (System/exit 0)))

(-main)
