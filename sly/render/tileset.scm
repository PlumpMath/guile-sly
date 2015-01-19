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
;; Tilesets encapsulate a group of uniformly sized texture regions
;; that come from a single texture.
;;
;;; Code:

(define-module (sly render tileset)
  #:use-module (srfi srfi-9)
  #:use-module (srfi srfi-42)
  #:use-module (sly render texture)
  #:export (<tileset>
            make-tileset
            load-tileset
            tileset?
            tileset-tiles
            tileset-width
            tileset-height
            tileset-margin
            tileset-spacing
            tileset-ref))

(define-record-type <tileset>
  (%make-tileset tiles width height margin spacing)
  tileset?
  (tiles tileset-tiles)
  (width tileset-width)
  (height tileset-height)
  (margin tileset-margin)
  (spacing tileset-spacing))

(define (split-texture texture width height margin spacing)
  "Split TEXTURE into a vector of texture regions of WIDTH x HEIGHT
size. SPACING refers to the number of pixels separating each
tile. MARGIN refers to the number of pixels on the top and left of
TEXTURE before the first tile begins."
  (define (build-tile tx ty)
    (let* ((x (+ (* tx (+ width spacing)) margin))
           (y (+ (* ty (+ height spacing)) margin)))
      (make-texture-region texture x y width height)))

  (let* ((tw (texture-width texture))
         (th (texture-height texture))
         (rows (/ (- tw margin) (+ width spacing)))
         (columns (/ (- th margin) (+ height spacing))))
    (vector-ec (: y rows) (: x columns) (build-tile x y))))

(define* (make-tileset texture width height
                       #:optional #:key (margin 0) (spacing 0))
  "Return a new tileset that is built by splitting TEXTURE into
tiles."
  (let ((tiles (split-texture texture
                              width
                              height
                              margin
                              spacing)))
    (%make-tileset tiles width height margin spacing)))

(define* (load-tileset filename width height
                       #:optional #:key (margin 0) (spacing 0))
  "Return a new tileset that is built by loading the texture at
FILENAME and splitting the texture into tiles."
  (let* ((tiles (split-texture (load-texture filename)
                               width
                               height
                               margin
                               spacing)))
    (%make-tileset tiles width height margin spacing)))

(define (tileset-ref tileset i)
  "Return the tile texture of TILESET at index I."
  (vector-ref (tileset-tiles tileset) i))
