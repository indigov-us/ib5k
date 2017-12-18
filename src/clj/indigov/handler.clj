(ns indigov.handler
  (:require
   [clojure.core.async :as async]
   [clojure.java.io :as io]
   [ring.middleware.reload :refer [wrap-reload]]
   [ring.middleware resource params keyword-params nested-params multipart-params cookies session flash stacktrace]
   [ring.middleware.session cookie]
   [ring.util.response :refer [response redirect content-type]]
   [compojure.core :refer [GET PUT POST DELETE ANY defroutes]]
   [compojure.response :refer [render]]
   [compojure.route :as route]
   [cheshire.core :as cc]
   [ring.middleware.session.cookie :refer [cookie-store]]
   [hiccup.core :refer [html]]
   [hiccup.page :refer [include-js include-css html5]]
   [hiccup.element :refer [javascript-tag]]
   [buddy.auth :refer [authenticated? throw-unauthorized]]
   [buddy.auth.middleware :refer [wrap-authentication wrap-authorization]]
   [buddy.auth.backends.token :refer [token-backend]]
   [buddy.auth.backends.session :refer [session-backend]]
   [buddy.auth.accessrules :refer [wrap-access-rules]]
   [buddy.sign.jwt :as jwt]
   [buddy.hashers :as hs]
   [taoensso.timbre :as timbre
    :refer (trace debug info warn error fatal spy with-log-level)]
   [mount.core :refer [defstate]]
   [indigov.global :as g]
   [clj-time [core :as time] [format :as time-format] [coerce :as time-coerce]]
   [ring.logger.timbre :as logger.timbre]
   [clj-ldap.client :as ldap])
  (:import
   [java.io.FileInputStream])
  )

(defn login-authenticate
  "Check request username and password against authdata
  username and passwords.
  On successful authentication, set appropriate user
  into the session and redirect to the value of
  (:next (:query-params request)). On failed
  authentication, renders the login page."
  [request]
  (let [username (get-in request [:edn-params :username])
        password (get-in request [:edn-params :password])
        session (:session request)
        [found-password uid] ["pass" "user"]]
    (if (and found-password (hs/check password found-password))
      (let [next-url (get-in request [:query-params :next] "/")
            updated-session (assoc session :identity uid)]
        (-> (redirect next-url)
            (assoc :cookies {:indigov_uid {:value uid
                                                :max-age 172800}})
            (assoc :session updated-session)))
      (buddy.auth.accessrules/error "Please login (Err: 1)"))))


(defn home
  [request]
  {:status 200
   :cookies {:indigov_uid (if (:identity request)
                            {:value (:identity request)
                             :max-age 172800}
                            {:value false
                             :max-age 172800})}
   :body (html5
          {:lang "en"}
          [:head
           [:base {:href "/"}]
           [:meta {:charset "utf-8"}]
           [:meta {:http-equiv "X-UA-Compatible"
                   :content "IE=edge"}]
           [:meta {:name "viewport"
                   :content "width=device-width, initial-scale=1"}]]
          [:body
           [:div#app]])})

(defn logout
  [request]
  (-> (redirect "/login")
      (assoc :cookies {:indigov_uid false})
      (assoc :session {})))

(defroutes app-routes
  (GET "/" [] home)
  (POST "/login" [] login-authenticate)
  (GET "/logout" [] logout)
  (compojure.route/not-found home))

(defn authenticated-access
  [request]
  (if (:identity request)
    true
    (buddy.auth.accessrules/error "Please login (Err: 1)")))

(defn any-access
  [request]
  true)

(def rules [{:pattern #"^/logout$"
             :handler any-access}
            {:pattern #"^/login$"
             :handler any-access}
            {:pattern #"^/$"
             :handler any-access}
            {:pattern #"^/.*"
             :handler authenticated-access
             }])

(def auth-backend (session-backend))

(def o-app

  (as-> app-routes $
    (wrap-access-rules $ {:rules rules :on-error (fn [r v]
                                                   (redirect "/"))})
    (wrap-authentication $ auth-backend)
    (wrap-authorization $ auth-backend)
    (ring.middleware.keyword-params/wrap-keyword-params $)
    (ring.middleware.params/wrap-params $)
    (ring.middleware.session/wrap-session $ {:store (cookie-store {:key "IA%3eNSuSWEEa%*z"})})
    (ring.middleware.stacktrace/wrap-stacktrace-log $)
    (ring.middleware.resource/wrap-resource $ "public")
    #_(logger.timbre/wrap-with-body-logger $)
    #_(logger.timbre/wrap-with-logger $)))

(def app (wrap-reload #'o-app))

(comment
  (let [conn (ldap/get-connection @g/ldap)
        user-dn "cn=read-only-admin,dc=example,dc=com"
        user-password "password"]
    (try
      (when (ldap/bind? conn user-dn user-password)
        (println (ldap/get conn user-dn))
        (println "Token: " (jwt/sign {:iat (.toDate (time/now))
                                      :jti (str (.toDate (time/now)) "_")
                                      :email "email@from_ldap"
                                      :name  "name from ldap"}
                                     "Our shared secret"
                                     {:alg :hs256})))
      (finally (ldap/release-connection @g/ldap conn))))
  )
