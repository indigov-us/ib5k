(ns indigov.cwc-to-email
  (:require [indigov [global :as g]]
            [clojure.tools.nrepl.server :as nrepl]
            [cider.nrepl :refer (cider-nrepl-handler)]
            [refactor-nrepl.middleware]
            [clojure.tools.namespace.repl :as tn]
            [mount.core :as mount :refer [defstate]]
            [http.async.client :as http]
            [cheshire.core :as cc]
            [postal.core :as pc]
            [ring.adapter.jetty :refer [run-jetty]]))



(defn get-emails-from-cwc
  [office]
  (with-open [client (http/create-client)]
    (let [response (http/GET client
                             (str (get-in g/offices [office :cwc :host] "/v2/" office "queue.json?limit=10000000"))
                             :headers {:HTTP_X_APIKEY (get-in g/offices [office :cwc :key])})]
      (-> response
        http/await
        http/string
        (cc/parse-string true)))))

(defn mark-mail-as-delivered
  [office email]
  (with-open [client (http/create-client)]
    (let [response (http/POST client
                             (str (get-in g/offices [office :cwc :host] "/v2/" office "mark_as_delivered"))
                             :headers {:HTTP_X_APIKEY (get-in g/offices [office :cwc :key])}
                             :body (str
                                    "<xml><MarkAsDelivered><Messages><Message><DeliveryId>"
                                    (get-in email [:CWC :Delivery :DeliveryId])
                                    "</DeliveryId><DeliveryAgent>"
                                    (get-in email [:CWC :Delivery :DeliveryAgent])
                                    "</DeliveryAgent></Message></Messages></MarkAsDelivered></xml>"))]
      (-> response
        http/await
        http/string
        (cc/parse-string true)))))

(defn check-and-forward-cwc-queue
  [office]
  (let [emails (:messages (get-emails-from-cwc office))]
    (doseq [email emails]
      (pc/send-message {:from (get-in g/offices [office :cwc :from_email])
                        :to (get-in g/offices [office :cwc :zd_email])
                        :subject "cwc_email_json"
                        :body (cc/generate-string email)})
      (mark-mail-as-delivered office email))))


(comment
 (defn server
   []
   (loop []
       (doseq [[office _] g/offices]
         (check-and-forward-cwc-queue office))
     (Thread/sleep 60000)
     (recur)))
)
