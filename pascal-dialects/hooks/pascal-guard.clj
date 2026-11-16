#!/usr/bin/env bb
;; Claude Code 用 Pascal 方言ガード。
;;
;; guard   PreToolUse(Skill|Write|Edit|MultiEdit)
;;         - Skill で読んだ pascal-* スキルをセッションごとに記録する。
;;         - Pascal ソースへの書き込みで方言を判定し、判断できなければ止める。
;;         - その方言のスキルをまだ読んでいなければ、先に読むよう止める。
;; verify  PostToolUse(Write|Edit|MultiEdit)
;;         書いたソースを方言に合うコンパイラでコンパイルし、エラーを Claude に返す。
;;         rawpaco は polyglot-scripting の lint-script.clj が走らせるので、ここでは呼ばない。
;;
;; 方言の判定 (上から順に)
;;   1. {$mode X} (ソース中か、{$I file} で取り込むファイル中)
;;   2. namespace X; → Oxygene
;;   3. .dpr / .dpk、または 4 階層上までに .dproj → Delphi (Embarcadero)
;; instantfpc のスクリプト (#! で始まる) は polyglot-scripting の管轄なので対象外。
;;
;; 例外は握りつぶして素通りさせる (fail-open)。記録は <状態ディレクトリ>/errors.log。

(require '[babashka.fs :as fs]
         '[babashka.process :as p]
         '[cheshire.core :as json]
         '[clojure.string :as str])

;; ---------------------------------------------------------------- 設定

(def state-dir
  (or (System/getenv "CLAUDE_PLUGIN_DATA")
      (str (fs/path (fs/home) ".claude" "pascal-dialects"))))

(def fpc-stock (or (System/getenv "PASCAL_FPC_STOCK") "/usr/bin/fpc"))
(def fpc-unleashed (or (System/getenv "PASCAL_FPC_UNLEASHED") (str (fs/home) "/unleashed/fpc/bin/fpc")))

(def source-exts #{"pas" "pp" "lpr" "dpr" "dpk"})

(def dialect-skill
  {"objfpc"        "pascal-fpc-objfpc"
   "delphi"        "pascal-fpc-delphi"
   "delphiunicode" "pascal-fpc-delphi"
   "unleashed"     "pascal-unleashed"
   "embarcadero"   "pascal-delphi"
   "oxygene"       "pascal-oxygene"})

(def dialect-label
  {"embarcadero" "Delphi (Embarcadero)"
   "oxygene"     "Oxygene"})

(def unverifiable
  "コンパイラで確かめられない方言。"
  #{"embarcadero" "oxygene"})

;; ---------------------------------------------------------------- 状態

(defn- append-line! [name line]
  (fs/create-dirs state-dir)
  (spit (str (fs/path state-dir name)) (str line "\n") :append true))

(defn- loaded-skills [sid]
  (let [f (str (fs/path state-dir "skills-loaded.tsv"))]
    (if (fs/exists? f)
      (->> (str/split-lines (slurp f))
           (keep #(let [[s n] (str/split % #"\t")] (when (= s sid) n)))
           set)
      #{})))

;; ---------------------------------------------------------------- 判定

(defn pascal-source? [path]
  (contains? source-exts (str/lower-case (or (fs/extension (str path)) ""))))

(defn script? [text]
  (str/starts-with? (or text "") "#!"))

(defn- mode-in [text]
  (some-> (re-find #"(?i)\{\$mode\s+([a-z]+)\s*\}" (or text "")) second str/lower-case))

(defn- included-texts
  "{$I file} / {$INCLUDE file} で取り込むファイルの中身 (ソースと同じディレクトリから解決できるもの)。"
  [path text]
  (when-let [dir (and (fs/absolute? path) (fs/parent path))]
    (for [[_ _ f] (re-seq #"(?i)\{\$(I|INCLUDE)\s+([^\s}]+)\s*\}" (or text ""))
          :let [inc (fs/path dir (str/replace f #"^'|'$" ""))]
          :when (fs/regular-file? inc)]
      (slurp (str inc)))))

(defn detect-mode [path text]
  (or (mode-in text)
      (some mode-in (included-texts path text))))

(defn- delphi-project? [path]
  (or (contains? #{"dpr" "dpk"} (str/lower-case (or (fs/extension path) "")))
      (when (fs/absolute? path)
        (loop [d (fs/parent path) n 0]
          (cond (or (nil? d) (> n 4)) false
                (seq (fs/glob d "*.dproj")) true
                :else (recur (fs/parent d) (inc n)))))))

(defn detect-dialect [path text]
  (or (detect-mode path text)
      (when (re-find #"(?im)^\s*namespace\s+[\w.]+\s*;" (or text "")) "oxygene")
      (when (delphi-project? path) "embarcadero")))

(defn- dialect-name [d] (or (dialect-label d) (str "{$mode " d "}")))

;; ---------------------------------------------------------------- guard

(defn- deny [msg]
  {:hookSpecificOutput {:hookEventName "PreToolUse"
                        :permissionDecision "deny"
                        :permissionDecisionReason (str "[pascal-dialects] " msg)}})

(defn- text-after-write
  "書き込み後の内容の近似。Write は content、Edit / MultiEdit は既存の内容に new_string を足したもの。"
  [tool path input]
  (if (= tool "Write")
    (:content input)
    (str (when (fs/exists? path) (slurp path)) "\n"
         (:new_string input) "\n"
         (str/join "\n" (map :new_string (:edits input))))))

(defn guard [{sid :session_id tool :tool_name input :tool_input}]
  (if (= tool "Skill")
    (let [n (last (str/split (str (:skill input)) #":"))]
      (when (str/starts-with? n "pascal-")
        (append-line! "skills-loaded.tsv" (str sid "\t" n)))
      nil)
    (let [path (str (:file_path input))]
      (when (pascal-source? path)
        (let [text  (text-after-write tool path input)
              mode  (detect-dialect path text)
              skill (dialect-skill mode)]
          (cond
            (script? text) nil

            (nil? mode)
            (deny (str path ": 方言が判断できません。FPC ならファイル先頭 (か {$I} で取り込むファイル) に "
                       "{$mode objfpc}{$H+} / {$mode delphi} / {$mode unleashed} のどれかを、"
                       "Oxygene なら namespace 宣言を書いてください。"
                       "Delphi (Embarcadero) のソースは .dproj のあるディレクトリに置いてください。"))

            (and skill (not (contains? (loaded-skills sid) skill)))
            (deny (str path ": " (dialect-name mode) " のコードを書く前に、スキル pascal-dialects:" skill
                       " を読んでください (方言の要点と例)。方言ごとに構文が違い、混同するとコンパイルが通りません。"))))))))

;; ---------------------------------------------------------------- verify

(defn- compile-errors
  "コンパイルエラーの行 (最大 15 行)。通ったとき、コンパイラがないとき、
  ユニットが見つからないだけのとき (プロジェクトの検索パスが分からない) は nil。"
  [path mode]
  (let [fpc (if (= mode "unleashed") fpc-unleashed fpc-stock)
        dir (str (fs/parent path))]
    (when (fs/executable? fpc)
      (let [tmp (str (fs/create-temp-dir {:prefix "pascal-verify"}))]
        (try
          (let [{:keys [exit out err]} (p/shell {:out :string :err :string :continue true :dir dir}
                                                fpc "-vew" "-l-" (str "-FE" tmp) (str "-FU" tmp)
                                                (str "-Fu" dir) (str "-Fi" dir) path)
                errs (->> (str/split-lines (str out "\n" err))
                          (filter #(re-find #"(Error|Fatal):" %))
                          (remove #(re-find #"returned an error exitcode|There were \d+ errors|Compilation aborted" %)))]
            (when (and (not (zero? exit))
                       (seq errs)
                       (not (every? #(re-find #"Can't find unit|Can not find unit" %) errs)))
              (take 15 errs)))
          (finally (fs/delete-tree tmp)))))))

(defn verify [{input :tool_input}]
  (let [path (str (:file_path input))]
    (when (and (pascal-source? path) (fs/exists? path)
               (not= "0" (System/getenv "PASCAL_DIALECTS_VERIFY")))
      (let [text (slurp path)
            mode (detect-dialect path text)]
        (when-not (or (script? text) (nil? mode) (contains? unverifiable mode))
          (when-let [errs (compile-errors path mode)]
            {:decision "block"
             :reason (str "[pascal-dialects] " path " (" (dialect-name mode) ") がコンパイルできません。直してください。"
                          "構文が分からなければ方言のスキルの examples / pitfalls を確認してください。\n  "
                          (str/join "\n  " errs))}))))))

;; ---------------------------------------------------------------- main

(defn- run-hook [f]
  (let [out (try
              (f (json/parse-string (slurp *in*) true))
              (catch Exception e
                (try (append-line! "errors.log" (str (java.time.Instant/now) "\t" (first *command-line-args*) "\t" (ex-message e)))
                     (catch Exception _ nil))
                nil))]
    (when out (println (json/generate-string out)))))

(case (first *command-line-args*)
  "guard"  (run-hook guard)
  "verify" (run-hook verify)
  (do (binding [*out* *err*] (println "usage: pascal-guard.clj <guard|verify> < payload.json"))
      (System/exit 2)))
