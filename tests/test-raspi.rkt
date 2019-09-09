#lang racket

(require libserialport
         "utils.rkt")

(define (main)
  (define-values (in out)
    (open-serial-port "/dev/ttyUSB0" #:baudrate 115200))
  (define raspi-output (read-until in "Bye!" 60000))
  (test "Check SDHC Version" (λ ()
                               (string-contains? raspi-output
                                                 "vendor 0x99, sdversion 0x2, slot_status 0x0")))
  (exit 0))

(main)
