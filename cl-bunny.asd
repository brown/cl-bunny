(in-package :cl-user)

(defpackage :cl-bunny.system
  (:use :cl :asdf))

(in-package :cl-bunny.system)

(defsystem :cl-bunny
  :version "0.4.6"
  :description "Common Lisp RabbitMQ client based on IOLib"
  :maintainer "Ilya Khaprov <ilya.khaprov@publitechs.com>"
  :author "Ilya Khaprov <ilya.khaprov@publitechs.com>"
  :licence "MIT"
  :depends-on ("alexandria"
               "string-case"
               "cl-amqp"
               "iolib"
               "cl+ssl"
               "quri"
               "lparallel"
               "safe-queue"
               "eventfd"
               "cl-events"
               "blackbird"
               "log4cl"
               "trivial-backtrace")
  :components ((:module "src"
                :serial t
                :components
                ((:file "package")
                 (:module "support"
                  :serial t
                  :components
                  ((:file "pipe")
                   (:file "int-allocator")
                   (:file "channel-id-allocator")
                   (:file "promise")
                   (:file "sync-promise")
                   (:file "async-promise")
                   (:file "bunny-event")))
                 (:file "conditions")
                 (:file "properties-and-headers")
                 (:module "transport"
                  :serial t
                  :components
                  ((:file "iolib-ssl-socket")
                   (:file "iolib-transport")))
                 (:module "io"
                  :serial t
                  :components
                  ((:file "frames")
                   (:file "frame-and-payload-parser")
                   (:file "output-frame-queue")))
                 (:module "base"
                  :serial t
                  :components
                  ((:file "channel-base")
                   (:file "connection-base")
                   (:file "threaded-connection")))
                 (:module "connection"
                  :serial t
                  :components
                  ((:file "spec")
                   (:file "pool")
                   (:file "iolib-connection")
                   ;; (:file "iolib-async")
                   ;; (:file "iolib-sync")
                   (:file "iolib-threaded")))
                 (:file "channel")
                 (:file "message")
                 (:file "queue")
                 (:file "exchange")
                 (:file "consumer")
                 (:file "basic")
                 (:file "confirm")
                 (:file "tx")
                 (:file "printer")))))
