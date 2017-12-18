(ns indigov.global
  (:require
   ;;[datomic.api :as d :refer [db q]]
   [clojure.java.io :as io]
   [clojure.walk :as walk]
   ;;[cognitect.transit :as transit]
   ;;[ring.middleware.transit :only [wrap-transit-response wrap-transit-params]]
   [me.raynes.conch.low-level :as sh]
   [clj-ldap.client :as ldap]
   [cheshire.core :as cc])
  (:import (java.io ByteArrayOutputStream)))

(defn add-ns-to-top-level-keys
  [ns data]
  (reduce-kv (fn [acc k v] (assoc acc (keyword ns (str(name k))) v)) {} data))

(defonce conn nil)
(defonce ldap (atom nil))

(defn generate-response [data & [status ]]
  {:status (or status 200)
   :headers {"Content-Type" "application/edn"}
   :body (pr-str data)})

(defn generate-response-with-cookie [data cookie]
  {:status 200
   :headers {"Content-Type" "application/edn"}
   :cookies {:indigov_uid {:value (:email data)
                        :max-age 172800}
             :indigov_token {:value cookie
                          :max-age 17280}}
   :body (pr-str data)})

(defn json-resp-array [data]
  {:status 200#_(if (first data) 200 400)
   :headers {"Content-Type" "application/json"}
   :body (cc/generate-string data)})

(defn json-resp [data & [status]]
  {:status (or status 200)
   :headers {"Content-Type" "application/json"}
   :body (cc/generate-string data)})


(def current-env
  (keyword (get (System/getenv) "ENVIRONMENT" "default")))


(def ldap-uri {:default {:host "ldap.forumsys.com"}
               :production {:host "Servicesdc3se.us.house.gov" :ssl true}})


(defn do-connect
  []
  (swap! ldap (ldap/connect (get ldap-uri current-env)))
  true)