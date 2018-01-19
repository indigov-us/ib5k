(ns indigov.email-to-zd
  (:require [indigov [global :as g]]
            [clojure.tools.nrepl.server :as nrepl]
            [cider.nrepl :refer (cider-nrepl-handler)]
            [refactor-nrepl.middleware]
            [clojure.tools.namespace.repl :as tn]
            [mount.core :as mount :refer [defstate]]
            [http.async.client :as http]
            [cheshire.core :as cc]
            [postal.core :as pc]
            [ring.adapter.jetty :refer [run-jetty]])
  (:import [javax.mail.internet InternetAddress MimeMultipart MimeMessage]
           [javax.mail Message$RecipientType Flags]))



(comment
  ;; sample email forwarder
  ;; it is likely much better if emails are retrieved with POP3, but then sent
  ;; to zendesk with API of some sorts (once the house IT enables outgoing https connections)
  (let [ses (let [p (java.util.Properties.)]
              (.put p "mail.store.protocol" "pop3")
              (.put p "mail.pop3.user" "indigov@zoho.com")
              (.put p "mail.pop3.host" "pop.zoho.com")
              (.put p "mail.pop3.port" 995)
              (.put p "mail.pop3.ssl.enable" true)
              ;;(.put p "mail.smtp.sasl.enable" true)
              (.put p "mail.smtp.host" "smtp.zoho.com")
              (.put p "mail.smtp.port" 465)
              (javax.mail.Session/getDefaultInstance p nil))
        store (.getStore ses "pop3s")
        transp (.getTransport ses "smtps")]
    (.connect transp "smtp.zoho.com" "indigov@zoho.com" "indigov_password")
    (.connect store "pop.zoho.com" "indigov@zoho.com" "indigov_password")
    (let [f (.getFolder store "INBOX")]
      (.open f javax.mail.Folder/READ_WRITE)
      (doseq [m (.getMessages f)]
        (let [fwd (MimeMessage. ses)
              mbp (javax.mail.internet.MimeBodyPart.)
              mmp (MimeMultipart.)]
          (.setRecipients fwd Message$RecipientType/TO "gyordanov@gmail.com")
          (.setSubject fwd (str "Fwd: " (.getSubject m)))
          (.setFrom fwd (InternetAddress. "indigov@zoho.com"))
          (.setContent mbp m "message/rfc822")
          (.addBodyPart mmp mbp)
          (.setContent fwd mmp)
          (.saveChanges fwd)
          (.sendMessage transp fwd (.getAllRecipients fwd))
          )
        )
      (.close f true))
    (.close transp)
    (.close store))




  )

(comment
 (defn server
   []
   (loop []
       (doseq [[office _] g/offices]
         (check-and-forward-email-queue office))
     (Thread/sleep 60000)
     (recur)))
)
