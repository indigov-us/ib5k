(ns indigov.core
  (:require [indigov [handler :refer [app]] [global :as g] [cwc-to-email :as cwc]]
            [clojure.tools.nrepl.server :as nrepl]
            [cider.nrepl :refer (cider-nrepl-handler)]
            [refactor-nrepl.middleware]
            [clojure.tools.namespace.repl :as tn]
            [mount.core :as mount :refer [defstate]]
            [ring.adapter.jetty :refer [run-jetty]])
  (:gen-class))

(defstate ^{:on-reload :noop} rest-server
  :start (do
           (println "Start REST on port 3003")
           (run-jetty app {:port 3003 :join? false}))
  :stop (do
          (println "Stopping REST server ... - " rest-server)
          (try
            (.stop rest-server)
            (catch Exception e (println (str e))))
          true))

(defstate ^{:on-reload :noop}
  nrepl-server
  :start (do
           (println "Starting NREPL on 8998")
           (nrepl/start-server :port 8998 :bind "0.0.0.0" :handler (apply nrepl/default-handler (map resolve (conj  cider.nrepl/cider-middleware 'refactor-nrepl.middleware/wrap-refactor)))))
  :stop (nrepl/stop-server nrepl-server))

(defstate ^{:on-reload :noop}
  ldap-connection
  :start (g/do-connect)
  :stop (fn [] true))

(defn go []
  (mount/start-without #'indigov.core/nrepl-server #'indigov.core/ldap-connection)
  :ready)

(defn reload []
  (mount/stop-except #'indigov.core/nrepl-server #'indigov.core/ldap-connection)
  (mount/start))

(defn reset []
  (mount/stop-except #'indigov.core/nrepl-server #'indigov.core/ldap-connection)
  (tn/refresh :after 'indigov.core/go))

(defn -main
  [& args]
  (mount/start))
