;;; Sly
;;; Copyright (C) 2013, 2014 David Thompson <dthompson2@worcester.edu>
;;;
;;; This program is free software: you can redistribute it and/or
;;; modify it under the terms of the GNU General Public License as
;;; published by the Free Software Foundation, either version 3 of the
;;; License, or (at your option) any later version.
;;;
;;; This program is distributed in the hope that it will be useful,
;;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;;; General Public License for more details.
;;;
;;; You should have received a copy of the GNU General Public License
;;; along with this program.  If not, see
;;; <http://www.gnu.org/licenses/>.

;;; Commentary:
;;
;; Deferred procedure scheduling.
;;
;;; Code:

(define-module (sly agenda)
  #:use-module (ice-9 q)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-9)
  #:use-module (srfi srfi-26)
  #:use-module (sly coroutine)
  #:export (make-agenda
            agenda?
            agenda-time
            current-agenda
            with-agenda
            tick-agenda!
            clear-agenda!
            schedule
            schedule-interval
            schedule-each
            wait))

;; This code is a modified version of the agenda implementation in
;; SICP. Thank you, SICP!

;;;
;;; Time segment
;;;

(define-record-type <time-segment>
  (%make-time-segment time queue)
  time-segment?
  (time segment-time)
  (queue segment-queue))

(define (make-time-segment time . callbacks)
  "Create a new time segment at TIME and enqueues everything in the
list CALLBACKS."
  (let ((segment (%make-time-segment time (make-q))))
    ;; Enqueue all callbacks
    (for-each (cut segment-enq segment <>) callbacks)
    segment))

(define (segment-enq segment callback)
  "Add the CALLBACK procedure to SEGMENT's queue."
  (enq! (segment-queue segment) callback))

;;;
;;; Agenda
;;;

(define-record-type <agenda>
  (%make-agenda time segments)
  agenda?
  (time %agenda-time set-agenda-time!)
  (segments agenda-segments set-agenda-segments!))

(define (make-agenda)
  "Create a new, empty agenda."
  (%make-agenda 0 '()))

(define (agenda-empty? agenda)
  "Return #t if AGENDA has no scheduled procedures."
  (null? (agenda-segments agenda)))

(define (first-segment agenda)
  "Return the first time segment in AGENDA."
  (car (agenda-segments agenda)))

(define (rest-segments agenda)
  "Return everything but the first segment in AGENDA."
  (cdr (agenda-segments agenda)))

(define (agenda-add-segment agenda time callback)
  "Add a new time segment to the beginning of AGENDA at the given TIME
and enqueue CALLBACK."
  (set-agenda-segments! agenda
                        (cons (make-time-segment time callback)
                              (agenda-segments agenda))))

(define (insert-segment segments time callback)
  "Insert a new time segment after the first segment in SEGMENTS."
  (set-cdr! segments
            (cons (make-time-segment time callback)
                  (cdr segments))))

(define (first-agenda-item agenda)
  "Return the first time segment queue in AGENDA."
  (if (agenda-empty? agenda)
      (error "Agenda is empty")
      (segment-queue (first-segment agenda))))

(define (agenda-time-delay agenda dt)
  "Return the sum of the time delta, DT, and the current time of AGENDA."
  (+ (%agenda-time agenda) (inexact->exact (round dt))))

(define (flush-queue! q)
  "Dequeue and execute every member of Q."
  (unless (q-empty? q)
    ((deq! q)) ;; Execute scheduled procedure
    (flush-queue! q)))

(define (%tick-agenda! agenda)
  "Move AGENDA forward in time and run scheduled procedures."
  (set-agenda-time! agenda (1+ (%agenda-time agenda)))
  (let next-segment ()
    (unless (agenda-empty? agenda)
      (let ((segment (first-segment agenda)))
        ;; Process time segment if it is scheduled before or at the
        ;; current agenda time.
        (when (>= (%agenda-time agenda) (segment-time segment))
          (flush-queue! (segment-queue segment))
          (set-agenda-segments! agenda (rest-segments agenda))
          (next-segment))))))

(define (%clear-agenda! agenda)
  "Remove all scheduled procedures from AGENDA."
  (set-agenda-segments! agenda '()))

(define (%schedule agenda thunk delay)
  "Schedule THUNK to be run after DELAY ticks of AGENDA."
  (let ((time (agenda-time-delay agenda delay)))
    (define (belongs-before? segments)
      (or (null? segments)
          (< time (segment-time (car segments)))))

    (define (add-to-segments segments)
      ;; Add to existing time segment if the times match
      (if (= (segment-time (car segments)) time)
          (segment-enq (car segments) thunk)
          ;; Continue searching
          (if (belongs-before? (cdr segments))
              ;; Create new time segment and insert it where it belongs
              (insert-segment segments time thunk)
              ;; Continue searching
              (add-to-segments (cdr segments)))))

    (if (belongs-before? (agenda-segments agenda))
        (agenda-add-segment agenda time thunk)
        (add-to-segments (agenda-segments agenda)))))

(define current-agenda
  (make-parameter (make-agenda)
                  (lambda (val)
                    (if (agenda? val)
                        val
                        (error "Must be an agenda")))))

(define-syntax-rule (with-agenda agenda body ...)
  (parameterize ((current-agenda agenda))
    body ...))

(define (agenda-time)
  "Return the time of the current agenda."
  (%agenda-time (current-agenda)))

(define (tick-agenda!)
  "Increment time for the current agenda and run scheduled
procedures."
  (%tick-agenda! (current-agenda)))

(define (clear-agenda!)
  "Remove all scheduled procedures from the current agenda."
  (%clear-agenda! (current-agenda)))

(define* (schedule thunk #:optional (delay 1))
  "Schedule THUNK to be applied after DELAY ticks of the current
agenda, or 1 tick if DELAY is not specified."
  (%schedule (current-agenda) thunk delay))

(define (schedule-interval thunk interval)
  "Schedule THUNK to be applied every INTERVAL ticks of the current
agenda."
  (coroutine
   (while #t
     (wait interval)
     (thunk))))

(define (schedule-each thunk)
  "Schedule THUNK to be applied upon every tick of the current
agenda."
  (schedule-interval thunk 1))

(define (wait delay)
  "Abort coroutine and schedule the continuation to be run after DELAY
ticks of the current agenda."
  (yield (cut schedule <> delay)))
