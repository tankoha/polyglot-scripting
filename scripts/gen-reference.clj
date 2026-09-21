#!/usr/bin/env bb
;; data/babashka-namespaces.edn から references/babashka.md の名前空間一覧を再生成する。
;;
;; 許可リストを更新したら:  bb scripts/gen-reference.clj
;; これでフック（強制）とスキル（参照）が同じ正本を見ている状態が保たれる。

(require '[clojure.edn :as edn]
         '[clojure.string :as str]
         '[babashka.fs :as fs])

(def root (fs/parent (fs/parent (fs/absolutize *file*))))
(def src  (fs/file root "data" "babashka-namespaces.edn"))
(def dest (fs/file root "skills" "polyglot-scripting" "references" "babashka.md"))

(def labels
  {:fs      "ファイル・パス操作"
   :process "プロセス・シェル・CLI"
   :http    "HTTP 通信・Web"
   :data    "データフォーマット (JSON/YAML/CSV/XML/Transit/EDN)"
   :markup  "HTML / テンプレート / Markdown"
   :core    "データ構造・操作・ユーティリティ"
   :observe "ログ・デバッグ・テスト"
   :meta    "コードパース・SCI"})

(def order [:fs :process :http :data :markup :core :observe :meta])

(def notes
  {'cheshire.core        "JSON"
   'clj-yaml.core        "YAML"
   'hiccup.core          "HTML 生成"
   'hiccup2.core         "HTML 生成"
   'selmer.parser        "Django 風テンプレートエンジン"
   'nextjournal.markdown "Markdown パース"
   'clojure.core.async   "非同期処理"
   'clojure.core.match   "パターンマッチング"
   'taoensso.timbre      "ロギング"
   'clojure.pprint       "整形出力"})

(defn render-ns [s]
  (if-let [n (notes s)] (format "`%s` (%s)" s n) (format "`%s`" s)))

(let [{:keys [groups babashka-version-verified-against]} (edn/read-string (slurp src))
      body (for [k order :when (groups k)]
             (str "### " (labels k) "\n\n"
                  (str/join "\n" (map #(str "- " (render-ns %)) (sort (groups k))))
                  "\n"))
      total (reduce + (map (comp count val) groups))]
  (fs/create-dirs (fs/parent dest))
  (spit dest
        (str "<!-- 自動生成: bb scripts/gen-reference.clj -->\n"
             "<!-- 正本は data/babashka-namespaces.edn。このファイルを直接編集しないこと -->\n\n"
             "# Babashka 組み込み名前空間\n\n"
             "追加依存なし・ワンファイルで書くこと。以下の " total " 個のみ使用可能"
             "（" babashka-version-verified-against " で確認）。\n\n"
             "ここに無い名前空間を `require` すると PostToolUse フックがブロックする。\n"
             "外部 pod や JVM 専用ライブラリが必要な場合は、勝手に `require` せず利用者に申告して確認を取る。\n\n"
             (str/join "\n" body)
             "\n## 確認方法\n\n"
             "ある名前空間がその環境で使えるかは、実際に試すのが確実:\n\n"
             "```bash\n"
             "bb -e \"(require '[babashka.fs])\" && echo ok\n"
             "```\n\n"
             "## 書き方\n\n"
             "```clojure\n"
             "#!/usr/bin/env bb\n"
             "(require '[babashka.fs :as fs]\n"
             "         '[cheshire.core :as json])\n\n"
             "(->> (fs/glob \".\" \"**/*.json\")\n"
             "     (map (comp json/parse-string slurp fs/file))\n"
             "     (run! prn))\n"
             "```\n\n"
             "- 標準入力は `*in*`、`(slurp *in*)` で読む\n"
             "- 終了コードは `(System/exit n)`\n"
             "- 引数は `*command-line-args*`。オプション解析が要るなら `babashka.cli`\n"))
  (println (format "生成: %s (%d 名前空間 / %d グループ)" (str dest) total (count groups))))
