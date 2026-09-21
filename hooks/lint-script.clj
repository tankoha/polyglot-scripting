#!/usr/bin/env bb
;; PostToolUse(Write|Edit) — 書かれたスクリプトをポリシーに照らして検査する。
;;
;; 検査対象と重み:
;;   *.bb / shebang に bb を含む .clj   -> 未許可 require を **ブロック** (exit 2)
;;   *.sh / *.bash (shebang あり)       -> set -euo pipefail 欠落を **警告** (additionalContext)
;;                                          shellcheck があれば併せて実行
;;   *.pas / *.pp                       -> rawpaco があれば実行し、指摘を **警告**
;;
;; ブロックするのは「未許可 require」だけ。ポリシー上これだけが一意に違反と判定でき、
;; 誤検知が起きない。set -euo pipefail は他人のスクリプトを編集した場合に
;; 誤発火しうるので警告に留めてある（README「厳しさの調整」参照）。
;;
;; JVM Clojure プロジェクトを壊さないため、.clj は shebang に bb を含むものだけ見る。

(require '[cheshire.core :as json]
         '[clojure.edn :as edn]
         '[clojure.string :as str]
         '[clojure.walk :as walk]
         '[babashka.fs :as fs]
         '[babashka.process :refer [shell]]
         '[edamame.core :as e])

(def plugin-root
  (or (System/getenv "CLAUDE_PLUGIN_ROOT")
      (str (fs/parent (fs/parent (fs/absolutize *file*))))))

(defn allowed-namespaces []
  (let [f (fs/file plugin-root "data" "babashka-namespaces.edn")]
    (if (fs/exists? f)
      (let [{:keys [groups always-allowed]} (edn/read-string (slurp f))]
        (into (set always-allowed) (mapcat val) groups))
      #{})))

;; --- bb スクリプト: require の検査 -----------------------------------------

(defn ns-of [x]
  (cond
    (symbol? x)                              x
    (vector? x)                              (first x)
    (and (seq? x) (= 'quote (first x)))      (ns-of (second x))
    :else                                    nil))

(defn required-namespaces [src]
  (let [acc (atom #{})]
    (try
      (walk/postwalk
       (fn [x]
         (when (and (seq? x) (= 'require (first x)))
           (swap! acc into (keep ns-of (rest x))))
         (when (and (sequential? x) (= :require (first x)))
           (swap! acc into (keep ns-of (rest x))))
         (when (and (seq? x) (= 'babashka.pods/load-pod (first x)))
           (swap! acc conj 'babashka.pods/load-pod))
         x)
       (e/parse-string-all src {:all true}))
      (catch Exception _ nil))            ; パース不能なら検査をあきらめる（誤爆させない）
    @acc))

(defn bb-script? [path src]
  (or (str/ends-with? path ".bb")
      (and (str/ends-with? path ".clj")
           (str/includes? (or (first (str/split-lines src)) "") "bb"))))

;; --- シェルスクリプト -------------------------------------------------------

(defn shell-script? [path src]
  (or (str/ends-with? path ".sh")
      (str/ends-with? path ".bash")
      (str/starts-with? (or (first (str/split-lines src)) "") "#!/bin/sh")))

(defn strict-mode? [src]
  (some #(re-find #"set\s+-euo\s+pipefail|set\s+-eu\b" %)
        (take 15 (str/split-lines src))))

;; --- 外部ツール -------------------------------------------------------------

(defn run [& args]
  (try (apply shell {:out :string :err :string :continue true} args)
       (catch Exception _ nil)))

(defn tool-available? [t] (some? (fs/which t)))

;; --- 出力 -------------------------------------------------------------------

(defn block! [reason]
  (println (json/generate-string
            {:hookSpecificOutput
             {:hookEventName "PostToolUse"
              :permissionDecision "deny"
              :permissionDecisionReason reason}}))
  (System/exit 2))

(defn advise! [text]
  (println (json/generate-string
            {:hookSpecificOutput
             {:hookEventName "PostToolUse"
              :additionalContext text}}))
  (System/exit 0))

(defn -main []
  (let [input (json/parse-string (slurp *in*) true)
        path  (get-in input [:tool_input :file_path])]
    (when (and path (fs/exists? path))
      (let [src   (slurp path)
            notes (atom [])]

        ;; 1. bb スクリプトの require 検査（ブロック）
        (when (bb-script? path src)
          (let [allowed (allowed-namespaces)
                used    (required-namespaces src)
                bad     (remove #(contains? allowed %) used)]
            (when (seq bad)
              (block!
               (str "スクリプティングポリシー違反: 許可されていない名前空間を require しています。\n"
                    "  " (str/join ", " (sort bad)) "\n\n"
                    "babashka の組み込み名前空間のみでワンファイルとして書いてください。"
                    "許可リストは " plugin-root "/data/babashka-namespaces.edn です。\n"
                    "外部 pod や JVM 専用ライブラリが本当に必要な場合は、"
                    "勝手に require せず利用者に申告して確認を取ってください。")))))

        ;; 2. シェルスクリプトの厳格モード検査（警告）
        (when (and (shell-script? path src)
                   (> (count (str/split-lines src)) 2)
                   (not (strict-mode? src)))
          (swap! notes conj
                 (str "[" (fs/file-name path) "] 複数行のシェルスクリプトです。"
                      "先頭に `set -euo pipefail` を置いてください。"
                      "また ksh / POSIX sh で実行される可能性を考え、"
                      "`[[` や `<()` 等の Bash 専用構文への依存を確認してください。")))

        (when (and (shell-script? path src) (tool-available? "shellcheck"))
          (let [{:keys [out exit]} (or (run "shellcheck" "-f" "gcc" path) {})]
            (when (and exit (pos? exit) (not (str/blank? out)))
              (swap! notes conj (str "[shellcheck]\n" (str/trim out))))))

        ;; 3. Free Pascal 品質ゲート（警告）
        (when (and (re-find #"\.(pas|pp)$" path) (tool-available? "rawpaco"))
          (let [{:keys [out err exit]} (or (run "rawpaco" path) {})]
            (when (and exit (pos? exit))
              (swap! notes conj (str "[rawpaco]\n" (str/trim (str out err)))))))

        (when (seq @notes)
          (advise! (str/join "\n\n" @notes)))))
    (System/exit 0)))

(-main)
