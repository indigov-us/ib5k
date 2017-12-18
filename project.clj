(defproject indigov "0.1.0-SNAPSHOT"
  :dependencies [[org.clojure/clojure "1.9.0"]
                 [org.clojure/tools.nrepl "0.2.12"]
                 [org.clojure/core.async "0.3.443"]
                 [mount "0.1.11"]
                 [buddy/buddy-core "1.2.0"]
                 [buddy/buddy-auth "1.4.1"]
                 [buddy/buddy-hashers "1.2.0"]
                 [compojure "1.6.0" :exclusions [ring/ring-core]]
                 [ring "1.6.1"]
                 [ring/ring-core "1.6.1"]
                 [prone "1.1.4"]
                 [cheshire "5.7.1"]
                 [com.taoensso/timbre "4.10.0"]
                 [matchbox "0.0.9"]

                 ;; [org.clojure/java.jdbc "0.6.1"]
                 ;; [org.postgresql/postgresql "9.3-1102-jdbc41"]

                 [me.raynes/conch "0.8.0"]

                 [clj-time "0.13.0"]
                 [crypto-password "0.2.0"]
                 [crypto-random "1.2.0"]
                 [org.clojure/data.csv "0.1.3"]
                 [ring-logger-timbre "0.7.5"]
                 [http.async.client "1.2.0"]
                 [com.draines/postal "2.0.2"]
                 [cider/cider-nrepl "0.15.1"]
                 [refactor-nrepl "2.3.1"]

                 [org.clojars.pntblnk/clj-ldap "0.0.15"]]

  :min-lein-version "2.5.3"

  :source-paths ["src/clj"]
  :main indigov.core
  :uberjar-name "indigov.jar"

  :clean-targets ^{:protect false} ["resources/public/js/compiled" "target"
                                    "test/js"
                                    "resources/public/css"]
  :profiles
  {:dev
   {:source-paths ["src/clj/" "migrations/"]
    :dependencies []
    :plugins      [[lein-doo "0.1.8" :exclusions [org.clojure/clojure]]
                   [cider/cider-nrepl "0.15.1"]]
    }})
