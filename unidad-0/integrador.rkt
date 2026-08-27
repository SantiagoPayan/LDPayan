#lang racket

;; seccion 1:

(struct num-exp (n) #:transparent)
(struct id-exp (id) #:transparent)
(struct add-exp (izq der) #:transparent)
(struct mul-exp (izq der) #:transparent)
(struct with-exp(nombre valor cuerpo) #:transparent)


;; Funciones de ambiente dadas 
(define (asocs-vacias) '())
(define (extender asocs nombre valor)
  (cons (cons nombre valor) asocs))
(define (buscar nombre asocs)
  (cdr (assoc nombre asocs)))

;; Funcion principal de evaluacion
(define (calc e asocs)
  (match e
    ; caso 1: Si es un numero, simplemente devolvemos ese numero
    [(num-exp n) n]

    ; Caso 2: Si es una suma, evaluamos recursivamente el lado izquierdo y el derecho, y sumamos los resultados en Racket.
    [(add-exp izq der) (+ (calc izq asocs) (calc der asocs))]

    ; Caso 3: Igual que la suma, pero multiplicando
    [(mul-exp izq der) (* (calc izq asocs) (calc der asocs))]

    ; Caso 4: Si es una variable
    [(id-exp id) (buscar id asocs)]

    ; Caso 5: with
    ; 1. Evaluamos la expresión 'valor'
    ; 2. Extendemos la lista de asociacione vinculando el nombre
    ; 3. Evaluamos el cuerpo.
    [(with-exp nombre valor cuerpo)
     (let ([valor-evaluado (calc valor asocs)])
       (calc cuerpo (extender asocs nombre valor-evaluado)))]))

;; Casos de verificacion
; (a) add(3, mul(2, 4))  -> 11
(calc (add-exp (num-exp 3) (mul-exp (num-exp 2) (num-exp 4))) (asocs-vacias))

; (b) with y=add(3,4) in mul(y, y) -> Debería dar 49
(calc (with-exp 'y
        (add-exp (num-exp 3) (num-exp 4))
        (mul-exp (id-exp 'y) (id-exp 'y)))
      (asocs-vacias))

; (c) with x=add(2,3) in with y=mul(x,2) in add(x, y) -> Debería dar 15
(calc (with-exp 'x
        (add-exp (num-exp 2) (num-exp 3))
        (with-exp 'y
          (mul-exp (id-exp 'x) (num-exp 2))
          (add-exp (id-exp 'x) (id-exp 'y))))
      (asocs-vacias))

; (d) with a=5 in mul(with b=add(a,1) in b, a) -> Debería dar 30
(calc (with-exp 'a
        (num-exp 5)
        (mul-exp (with-exp 'b
                   (add-exp (id-exp 'a) (num-exp 1))
                   (id-exp 'b))
                 (id-exp 'a)))
      (asocs-vacias))

#|
Trazado de: with x=add(2,3) in with y=mul(x,2) in add(x,y)

Abreviaciones:
N2 = (num-exp 2)
N3 = (num-exp 3)
A1 = (add-exp N2 N3)
X = (id-exp x)
Y = (id-exp y)
M = (mul-exp X N2) 
A2 = (add-exp X Y)
Wy = (with-exp y M A2)

(calc (with-exp x A1 Wy) sigma0)
= (calc Wy extend(sigma0, x, (calc A1 sigma0)))
= (calc Wy extend(sigma0, x, (calc N2 sigma0) + (calc N3 sigma0)))
= (calc Wy extend(sigma0, x, 2 + 3))
= (calc Wy sigma1) con sigma1 = extend(sigmap0, x, 5)
= (calc A2 extend(sigma1, y, calc M sigma1)))
= (calc A2 extend(sigma1, y, (calc X sigma1) * (calc N2 sigma1)))
= (calc A2 extend(sigma1, y, lookup(x, sigma1) * (calc N2 sigma1)))
= (calc A2 extend(sigma1, y, 5 * 2))
= (calc A2 sigma2) con sigma2 = extend(sigma1, y, 10)
= (calc X sigma2) + (calc Y sigma2)
= lookup(x, sigma2) + lookup(y, sigma2)
= 5 + 10
= 15
|#
                            
    
    


