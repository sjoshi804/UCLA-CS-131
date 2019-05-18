#| 
  TODO: Unification of variables a!b and lambda special case 
  FIXME: Calling the unify x y at the right time
|#

;xor boolean function
(define (xor a b)
 (not (boolean=? a b)))

;to check if two expressions have equal number of elements/parameters
(define (equal_length? a b)
  (if (and (pair? a) (pair? b)) (equal_length? (cdr a) (cdr b)) (and (not (pair? a)) (not (pair? b))) ))

(define (unify_func_name car_x car_y)
  (if (equal? car_x car_y) 
    (if (equal? car_x 'lambda) 'lambda (if (equal? car_x 'λ) 'λ 'NULL)) 
    (if (or (and((equal? car_x 'lambda) (equal? car_y 'λ))) (and((equal? car_y 'lambda) (equal? car_x 'λ)))) 'λ 'NULL)   
  )
)

(define (unify x y)
(let ([car_exp (unify_func_name (car x) (car y))])
(
  (if (equal? car_exp 'NULL) (cons x y) 
  (let ([param_x (car (cdr x))] [param_y (car (cdr y))])
  ((let ([dicts (cons_dict param_x param_y)]) (let ([dict_x (car dicts)] [dict_y (cdr dicts)])
  (
    cons (apply_dict dict_x (cons car_exp (cdr x))) (apply_dict dict_y (cons car_exp (cdr y)))

  ))))))
)
)

;Unifies variables according to rules first, then attempts to 
(define (expr-compare x y)
  (if (or (and x (not y))) '% (if (or (and y (not x))) '(not %) 
  (if (equal? x y) x 
    (if (or (not (and (pair? x) (pair? y))) (not (equal_length? x y)) (xor (equal? (car x) 'if) (equal? (car y) 'if)) (equal? (car x) 'quote) (equal? (car y) 'quote) )
      `(if % ,x ,y)
      (cons (expr-compare (car x) (car y)) (expr-compare (cdr x) (cdr y)) )
    )
  )))
)

