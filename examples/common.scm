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

(use-modules (sly)
             (sly fps))

(sly-init)

(add-hook! key-press-hook (lambda (key unicode)
                            (when (eq? key 'escape)
                              (stop-game-loop))))

(add-hook! window-close-hook stop-game-loop)

(schedule-interval
 (lambda ()
   (format #t "FPS: ~d\n" (signal-ref fps)))
 60)

(start-sly-repl)
