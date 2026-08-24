#lang racket

(define (cuenta-atras n)
  (if (= n 0)
      '()
      (cons n (cuenta-atras (- n 1)))))

; Pruebas
(cuenta-atras 5) ; Debería imprimir '(5 4 3 2 1)
(cuenta-atras 1) ; Debería imprimir '(1)
(cuenta-atras 0) ; Debería imprimir '()
