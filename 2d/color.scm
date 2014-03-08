;;; guile-2d
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
;; Color.
;;
;;; Code:

(define-module (2d color)
  #:use-module (figl gl)
  #:use-module (srfi srfi-9)
  #:use-module (srfi srfi-1)
  #:export (<color>
            make-color
            color?
            color-r
            color-g
            color-b
            color-a
            use-color
            rgba
            rgb
            white
            black
            red
            green
            blue
            magenta))

(define-record-type <color>
  (make-color r g b a)
  color?
  (r color-r)
  (g color-g)
  (b color-b)
  (a color-a))

(define (use-color color)
  "Set the current OpenGL color state to the contents of COLOR."
  (gl-color (color-r color)
            (color-g color)
            (color-b color)
            (color-a color)))

(define (color-component color-code offset)
  "Return the value of an 8-bit color channel in the range [0,1] for
the integer COLOR-CODE, given an OFFSET in bits."
  (let ((mask (ash #xff offset)))
    (/ (ash (logand mask color-code)
            (- offset))
       255.0)))

(define (rgba color-code)
  "Translate an RGBA format string COLOR-CODE into a color object.
For example: #xffffffff will return a color with RGBA values 1, 1, 1,
1."
  (make-color (color-component color-code 24)
              (color-component color-code 16)
              (color-component color-code 8)
              (color-component color-code 0)))

(define (rgb color-code)
  "Translate an RGB format string COLOR-CODE into a color object.
For example: #xffffff will return a color with RGBA values 1, 1, 1,
1."
  (make-color (color-component color-code 16)
              (color-component color-code 8)
              (color-component color-code 0)
              1))

;; Pre-defined colors.
(define white (rgb #xffffff))
(define black (rgb #x000000))
(define red (rgb #xff0000))
(define green (rgb #x00ff00))
(define blue (rgb #x0000ff))
(define magenta (rgb #xff00ff))
