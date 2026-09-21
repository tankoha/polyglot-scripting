#!/usr/bin/env bb
;; PreToolUse(Write|Edit) — アドホックな Python / Node スクリプトの「作成」を止める。
;;
;; なぜ Bash 層ではなく Write 層なのか:
;;   Claude のアドホックスクリプティングは `python -c` ではなく、
;;   「scratchpad に .py を書いて実行する」形で現れる。実行時のコマンド
;;   `python3 primes.py` は、正規のプロジェクトスクリプト実行と区別がつかない。
;;   つまり Bash 層では原理的に閉じられない。
;;
;;   一方、ポリシー違反が実際に起きているのは *ファイルが作られた瞬間* であり、
;;   しかも「scratchpad / tmp 配下の .py」は正規のプロジェクトソースでは
;;   ありえない。ここなら誤検知ゼロで判定できる。
;;   ファイルが作れなければ実行もされないので、Bash 層の相対パス問題も消える。
;;
;; 判定範囲は意図的に scratchpad / tmp 配下に限定してある。
;; プロジェクト内の .py を編集する場合（正規の Python プロジェクト）は通す。

(require '[cheshire.core :as json]
         '[clojure.string :as str])

(def blocked-ext #{"py" "js" "mjs" "cjs" "ts"})

(def alt-ext
  {"py"  ".bb (Babashka) か .pas (instantfpc)"
   "js"  ".bb (Babashka)"
   "mjs" ".bb (Babashka)"
   "cjs" ".bb (Babashka)"
   "ts"  ".bb (Babashka)"})

(defn ext-of [path]
  (when-let [m (re-find #"\.([A-Za-z0-9]+)$" (or path ""))]
    (str/lower-case (second m))))

(defn ephemeral?
  "その場限りの作業領域か。scratchpad_dir はフック入力から渡ってくる。

   /tmp 配下は『直下のファイル』だけを対象にする。/tmp/repo/src/main.py の
   ようなツリーは、clone してきたプロジェクトである可能性があるため通す。
   （実測した誤検知。git clone x /tmp/repo してソースを触る形が塞がれていた）"
  [path scratchpad-dir]
  (let [p (or path "")]
    (or (and (not (str/blank? (or scratchpad-dir "")))
             (str/starts-with? p scratchpad-dir))
        (str/includes? p "/scratchpad/")
        (some? (re-matches #"/(?:var/)?tmp/[^/]+" p)))))

(defn deny! [ext path]
  (println
   (json/generate-string
    {:hookSpecificOutput
     {:hookEventName "PreToolUse"
      :permissionDecision "deny"
      :permissionDecisionReason
      (str "スクリプティングポリシー違反: 作業領域に ." ext
           " スクリプトを作成しようとしています。\n"
           "  " path "\n\n"
           "その場限りのスクリプトを Python / Node.js で書くことは禁止されています。\n"
           "代わりに " (get alt-ext ext ".bb (Babashka)") " で書いてください。\n"
           "  - JSON/YAML/HTTP/テキストパイプライン処理 -> .bb\n"
           "  - 性能重視・低レイヤ・バイナリ/ファイル操作 -> .pas\n"
           "  - そもそも1行で済むなら grep/sed/awk で十分なはずです\n"
           "書き方は polyglot-scripting スキルを参照。\n\n"
           "注: プロジェクト本来のソースツリー内の ." ext
           " は対象外です。ここで止まっているのは、作業用の一時領域に"
           "使い捨てスクリプトを作ろうとしたためです。")}}))
  (System/exit 2))

(defn -main []
  (let [input      (json/parse-string (slurp *in*) true)
        path       (get-in input [:tool_input :file_path])
        content    (or (get-in input [:tool_input :content]) "")
        scratchpad (:scratchpad_dir input)
        ext        (ext-of path)]
    (when (and path
               (contains? blocked-ext ext)
               (ephemeral? path scratchpad)
               (not (re-find #"policy:allow" content)))
      (deny! ext path))
    (System/exit 0)))

(-main)
