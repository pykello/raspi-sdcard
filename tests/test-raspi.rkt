#lang racket

(require libserialport
         "utils.rkt")

(define (main)
  (define-values (in out)
    (open-serial-port "/dev/ttyUSB0" #:baudrate 115200))
  (define raspi-output (read-until in "Bye!" 60000))
  (displayln raspi-output)
  (test "Check SDHC Version" (λ ()
                               (string-contains? raspi-output
                                                 "vendor 0x99, sdversion 0x2, slot_status 0x0")))
  (test "Read Bytes" (λ ()
                       (equal? (find-byte-sequence raspi-output)                
                               (read-file-bytes sdcard-image-path 512))))
  (exit 0))

(main)
