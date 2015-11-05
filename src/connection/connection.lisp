(in-package :cl-bunny)

(defvar *connection*)

(defparameter *connection-type* 'librabbitmq-connection)

(defclass connection ()
  ((spec :initarg :spec :reader connection-spec)
   (channel-id-allocator :type channel-id-allocator
                         :initform (new-channel-id-allocator +max-channels+)
                         :reader connection-channel-id-allocator)

   (channels :type hash-table
             :initform (make-hash-table :synchronized t)
             :reader connection-channels)

   (pool :initform nil :accessor connection-pool)

   (event-base :initform (make-instance 'iolib:event-base) :reader connection-event-base :initarg :event-base)
   (control-fd :initform (eventfd:eventfd.new 0))
   (control-mailbox :initform (make-queue) :reader connection-control-mailbox)
   (execute-in-connection-lambda :initform nil :reader connection-lambda)
   (connection-thread :reader connection-thread)))

(defun connection-alive-p (connection)
  (and connection
       (slot-boundp connection 'connection-thread)
       (bt:thread-alive-p (connection-thread connection))))

(defun check-connection-alive (connection)
  (when (connection-alive-p connection)
    connection))

(defun run-new-connection (spec)
  (connection.open (connection.new spec)))

(defun setup-execute-in-connection-lambda (connection)
  (with-slots (control-fd control-mailbox execute-in-connection-lambda) connection
    (setf execute-in-connection-lambda
          (lambda (thunk)
            (enqueue thunk control-mailbox)
            (log:debug "Notifying connection thread")
            (eventfd.notify-1 control-fd)))))

(defmacro execute-in-connection-thread ((&optional (connection '*connection*)) &body body)
  `(funcall (connection-lambda ,connection)
            (lambda () ,@body)))

(defmacro execute-in-connection-thread-sync ((&optional (connection '*connection*)) &body body)
  (with-gensyms (lock condition return connection% error)
    `(let ((,lock (bt:make-lock))
           (,condition (bt:make-condition-variable))
           (,return nil)
           (,connection% ,connection)
           (,error))
       (if (connection-alive-p ,connection%)
           (bt:with-lock-held (,lock)
             (funcall (connection-lambda ,connection%)
                      (lambda (&aux (*connection* ,connection%))
                        (bt:with-lock-held (,lock)
                          (handler-case
                              (setf ,return
                                    (multiple-value-list
                                     (unwind-protect
                                          (progn
                                            ,@body)
                                       (bt:condition-notify ,condition))))
                            (cl-rabbit::rabbitmq-server-error (e)
                              (log:error "Server error: ~a" e)
                              (setf ,error e))))))
             (bt:condition-wait ,condition ,lock)
             (if ,error
                 (error ,error)
                 (values-list ,return)))
           (error 'connection-closed-error :connection ,connection%)))))

(defun connection.close (&optional (connection *connection*))
  (when (connection-alive-p connection)
    (execute-in-connection-thread (connection)
      (error 'stop-connection))
    (bt:join-thread (connection-thread connection)))
  (when (connection-pool connection)
    (remove-connection-from-pool connection)))


(defgeneric connection.send (connection channel method))
