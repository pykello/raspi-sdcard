#lang racket

(define (main)
  (define qemu-output
    (run-qemu #:kernel kernel-path
              #:sdcard sdcard-image-path))
  (test "Check SDHC Version" (λ ()
                               (string-contains? qemu-output
                                                 "vendor 0x24, sdversion 0x1, slot_status 0x0")))
  (test "Read Bytes" (λ ()
                       (equal? (find-byte-sequence qemu-output)
                               (read-file-bytes sdcard-image-path 512))))
  (exit 0))

(define (test name f)
  (display (string-append name " ... "))
  (if (f)
      (displayln "Passed")
      (displayln "Failed")))

(define (read-file-bytes path len)
  (define f (open-input-file path))
  (bytes->list (read-bytes len f)))
  
(define (find-byte-sequence s)
  (define lines (string-split s "\n"))
  (match (findf (λ (line) (string-prefix? line "BYTES: ")) lines)
    [#f '()]
    [s (define hex-list (cdr (string-split s)))
       (map hex->byte hex-list)]))

(define (hex->byte h)
  (define (hex-digits->byte lst)
    (cond
      [(null? lst) 0]
      [else (+ (* 16 (hex-digits->byte (cdr lst)))
               (hex-char->int (car lst)))]))

  (define (hex-char->int c)
    (cond ((char<=? #\0 c #\9) (- (char->integer c) (char->integer #\0)))
          ((char<=? #\a c #\f) (+ 10 (- (char->integer c) (char->integer #\a))))
          ((char<=? #\A c #\F) (+ 10 (- (char->integer c) (char->integer #\A))))))

  (hex-digits->byte (reverse (string->list (string-trim h "0x")))))

(define (run-qemu #:kernel kernel #:sdcard sdcard)
  (match-define (list stdout stdin pid stderr ctl)
    (process* "/usr/bin/qemu-system-arm" "-M" "raspi2" "-m" "512M" "-nographic"
              "-sd" sdcard
              "-kernel" kernel))
  (cond
    [(eq? (ctl 'status) 'done-error) (error (read-string 4096 stderr))]
    [else (define output2 (read-until stdout "Bye!" 2000))
          (exit-qemu stdin)
          (ctl 'wait)
          output2]))

;; writes the qemu exit sequence to stdin and closes it
(define (exit-qemu stdin)
  (write-byte 1 stdin)
  (write-byte 120 stdin)
  (close-output-port stdin))

(define (read-until port exit-seq timeout)
  (define bs (make-bytes 65536))
  (define expire (+ (current-inexact-milliseconds) timeout))
  (define (aux idx)
    (define end-pos (min (+ idx 128) (bytes-length bs)))
    (cond
      [(> (current-inexact-milliseconds) expire) (void)]
      [else (define len (read-bytes-avail! bs port idx end-pos))
            (cond
              [(string-contains? (bytes->string/latin-1 bs) exit-seq) (void)]
              [else (sleep 0.01)
                    (aux (+ idx len))])]))
  (aux 0)
  (bytes->string/latin-1 bs))

(define tests-directory
  (path-only (path->complete-path (find-system-path 'run-file))))

(define sdcard-image-path
  (path->string (build-path tests-directory "sdcard.img")))

(define kernel-path
  (path->string
   (simplify-path
    (build-path tests-directory 'up "raspi2-qemu.img"))))

(main)
