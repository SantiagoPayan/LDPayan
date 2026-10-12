#lang racket

#|
   TAREA 1. Extender el lenguaje LET

   Nombre: Santiago Payan Ibarra

   Aquí va la prosa de las secciones 1, 2 y 4 de cada constructo, en el
   orden del enunciado. Solo aparecen las secciones que te toca escribir: las
   demás vienen dadas en el enunciado. La sección 3 es el código: tus struct
   en ast.rkt y tus cláusulas en interp.rkt y en desugar.rkt, en los lugares
   marcados.

   not
   ---
   4. Contraste
    not(zero?(0)): Especificación: (boolval #f). Implementación: (boolval #f).
    not(zero?(1)): Especificación: (boolval #t). Implementación: (boolval #t).
    not(not(zero?(1))) (caso de borde evaluando una negación anidada): Especificación: (boolval #f). Implementación: (boolval #f).
    Ambos resultados coinciden perfectamente; la implementación respeta fielmente las reglas de inferencia [not-v] y [not-f] devolviendo el valor booleano invertido.   

   and
   ---
   4. Contraste
   and(true, true): Especificación: (boolval #t). Implementación: (boolval #t).
   and(true, false): Especificación: (boolval #f). Implementación: (boolval #f).
   and(false, car(emptylist)) (caso de borde evaluando cortocircuito): Especificación: (boolval #f). Implementación: (boolval #f).
Ambos resultados coinciden perfectamente. Al traducirse a un if mediante azúcar sintáctica, la implementación respeta el cortocircuito, por lo que en el caso de borde la segunda expresión nunca se evalúa y no produce un error en tiempo de ejecución.   
   


   or
   --
   1. Propuesta informal
   El constructo or realiza una disyunción lógica entre dos expresiones.
Funciona mediante un mecanismo de cortocircuito: si la primera expresión resulta verdadera,
toda la disyunción es verdadera y la segunda expresión no se evalúa. Si la primera expresión es falsa, la evaluación retorna
directamente el valor booleano resultante de evaluar la segunda expresión.   

   2. Especificación formal
   Producción: Expression ::= or(Expression, Expression)

   4. Contraste
   or(true, false): Especificación: (boolval #t). Implementación: (boolval #t).
   
   or(false, false): Especificación: (boolval #f). Implementación: (boolval #f).
   
   or(true, car(emptylist)) (caso de borde evaluando cortocircuito): Especificación: (boolval #t). Implementación: (boolval #t).
   
   Ambos resultados coinciden. La implementación en núcleo respeta la regla de evaluación condicional impidiendo un error en tiempo
de ejecución al omitir la evaluación de la segunda expresión si la primera es #t.


   xor
   ---
   1. Propuesta informal
    El constructo xor representa una disyunción exclusiva lógica. Evalúa dos expresiones y retorna verdadero
estrictamente cuando exactamente una de sus dos expresiones resulta verdadera y la otra falsa. Opera como azúcar
 sintáctica, por lo que no existe en el núcleo del lenguaje, sino que se transforma utilizando un condicional if y
la negación not.
   

   2. Especificación formal
   Producción: Expression ::= xor(Expression, Expression)

   Regla de transformación: xor(e1, e2) ⇝ if e1 then not(e2) else e2
   

   4. Contraste
   xor(true, false): Especificación: (boolval #t). Implementación: (boolval #t).

   xor(true, true): Especificación: (boolval #f). Implementación: (boolval #f).

   let x = 1 in xor(zero?(x), zero?(-(x, 1))) (caso de borde evaluando un entorno extendido con operaciones aritméticas): Especificación: (boolval #t). Implementación:

   Ambos resultados coinciden. La desugarización traduce el comportamiento esperado sobre el flujo de control nativo del intérprete, apoyándose con éxito en el constructo not.   


   cond
   ----
   2. Especificación formal: solo la regla de cond end
    Un cond sin ninguna prueba verdadera carece de valor. Por ello, su forma vacía se traduce a una expresión del núcleo que provoca un fallo semántico predecible:
cond end ⇝ car(emptylist)

   4. Contraste
    cond zero?(0) ==> 1 end: Especificación: (intval 1). Implementación: (intval 1).

   let x = 3 in cond zero?(x) ==> 100 zero?(-(x,3)) ==> 200 end (caso de borde con variables): Especificación: (intval 200). Implementación: (intval 200).   

   cond false ==> 1 end (caso de borde de fallo estructurado al agotar ramas): Especificación: Error en tiempo de ejecución (car de lista vacía). Implementación: Error en tiempo de ejecución.

   Ambos resultados coinciden. La traducción recursiva mediante azúcar sintáctica construye correctamente los if anidados, y el caso base fuerza un error del núcleo esperado cuando ninguna prueba es verdadera.

   list
   
   ----
   4. Contraste
   list(): Especificación: (listval '()). Implementación: (listval '()).

   let x = 4 in list(x, -(x, 1), -(x, 3)): Especificación: (listval (list (intval 4) (intval 3) (intval 1))). Implementación: (listval (list (intval 4) (intval 3) (intval 1))).

   list(list()) (caso de borde con una lista vacía anidada dentro de otra): Especificación: (listval (list (listval '()))). Implementación: (listval (list (listval '()))).

   Ambos resultados coinciden. La regla de transformación recursiva convierte de manera adecuada cualquier cantidad de expresiones a llamadas sucesivas de cons-exp, cerrando correctamente con emptylist-exp en el caso base.   


   unpack
   ------
   2. Especificación formal
   Producción: Expression ::= unpack {Identifier}* = Expression in Expression


   4. Contraste
   let u = 7 in unpack x y = list(u, 3) in -(x, y): Especificación: (intval 4). Implementación: (intval 4).

unpack = list() in 1 (caso de borde con cero variables y lista vacía): Especificación: (intval 1). Implementación: (intval 1).

unpack x = list() in x (caso de borde por desajuste de longitud): Especificación: Error en tiempo de ejecución. Implementación: Error en tiempo de ejecución.

Ambos resultados coinciden. La implementación valida la longitud antes de vincular y propaga el error correspondiente si las cantidades no concuerdan.   

|#

(require "ast.rkt"
         "env.rkt"
         "vals.rkt")

(provide
 (contract-out
  [value-of (-> expression? env?
                expval?)]))

;; Intérprete del lenguaje LET
(define (value-of e ρ)
  (match e
    [(const-exp n)    (intval n)]
    [(var-exp x)      (apply-env ρ x)]
    [(diff-exp e1 e2)
     (define v1 (value-of e1 ρ))
     (define v2 (value-of e2 ρ))
     (intval (- (val->int v1)
                (val->int v2)))]
    [(zero?-exp e1)
     (define v1 (value-of e1 ρ))
     (boolval (zero? (val->int v1)))]
    [(if-exp e1 e2 e3)
     (define v1 (value-of e1 ρ))
     (if (val->bool v1)
         (value-of e2 ρ)
         (value-of e3 ρ))]
    [(let-exp x e1 e2)
     (define v1 (value-of e1 ρ))
     (define ρ* (extend-env x v1 ρ))
     (value-of e2 ρ*)]

    ;; La aritmética que va en el núcleo: minus, mul y quotient
    [(minus-exp e1)
     (define v1 (value-of e1 ρ))
     (intval (- (val->int v1)))]
    [(mul-exp e1 e2)
     (define v1 (value-of e1 ρ))
     (define v2 (value-of e2 ρ))
     (intval (* (val->int v1)
                (val->int v2)))]
    [(quotient-exp e1 e2)
     (define v1 (value-of e1 ρ))
     (define v2 (value-of e2 ρ))
     (intval (quotient (val->int v1)
                       (val->int v2)))]

    ;; Los booleanos que van en el núcleo: equal? y less?
    [(equal?-exp e1 e2)
     (define v1 (value-of e1 ρ))
     (define v2 (value-of e2 ρ))
     (boolval (equal? v1 v2))]
    [(less?-exp e1 e2)
     (define v1 (value-of e1 ρ))
     (define v2 (value-of e2 ρ))
     (boolval (val<? v1 v2))]

    ;; Las listas
    [(emptylist-exp)
     (listval '())]
    [(cons-exp e1 e2)
     (define v1 (value-of e1 ρ))
     (define v2 (value-of e2 ρ))
     (listval (cons v1 (val->list v2)))]
    [(car-exp e1)
     (define v1 (value-of e1 ρ))
     (car (val->list v1))]
    [(cdr-exp e1)
     (define v1 (value-of e1 ρ))
     (listval (cdr (val->list v1)))]
    [(null?-exp e1)
     (define v1 (value-of e1 ρ))
     (boolval (null? (val->list v1)))]

    ;; --- AQUÍ van tus cláusulas del núcleo: not-exp y unpack-exp ---
    [(not-exp e1)
     (define v1 (value-of e1 ρ))
     (if (val->bool v1)
         (boolval #f)
         (boolval #t))]


    [(unpack-exp xs e1 e2)
     (define v1 (value-of e1 ρ))
     (define l1 (val->list v1))
     (if (= (length xs) (length l1))
         (value-of e2 (extend-env* xs l1 ρ))
         (error 'value-of "la cantidad de variables no coincide con la lista"))]

    ;; La tarea, lo que viene hecho en el núcleo: or
    [(or-exp e1 e2)
     (define v1 (value-of e1 ρ))
     (if (val->bool v1)
         (boolval #t)
         (boolval (val->bool (value-of e2 ρ))))]))

;; Si una cláusula necesita una función auxiliar, va aquí abajo, con nombre
;; propio, y no escondida dentro de la cláusula.

;; --- AQUÍ van tus auxiliares, cada una con nombre propio ---

(define (extend-env* xs vs ρ)
  (if (null? xs)
      ρ
      (extend-env* (rest xs)
                   (rest vs)
                   (extend-env (first xs) (first vs) ρ))))

;; El orden de los valores expresados: false es menor que todo lo demás,
;; true es mayor que todo lo demás, y entre números es el < de siempre.
;; Es estricto: ningún valor es menor que sí mismo.
(define (val<? v1 v2)
  (match (list v1 v2)
    [(list (boolval #f) (boolval #f)) #f]
    [(list (boolval #f) _)            #t]
    [(list (boolval #t) _)            #f]
    [(list _            (boolval #f)) #f]
    [(list _            (boolval #t)) #t]
    [(list (intval n1)  (intval n2))  (< n1 n2)]))
