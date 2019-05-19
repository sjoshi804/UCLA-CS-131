#| Generic helper functions |#
;xor boolean function
(define (xor a b)
 (not (boolean=? a b)))

;To check if two expressions have equal number of elements/parameters
(define (equal_length? a b)
  (if (and (pair? a) (pair? b)) (equal_length? (cdr a) (cdr b)) (and (not (pair? a)) (not (pair? b))) ))


#| Helper functions for combining symbols|#
;Combine two symbols X Y into X!Y
(define (combine_symbol x y)
  (string->symbol (string-append (symbol->string x) "!" (symbol->string y))))

;Takes two function names and unifies them, if not lambda funcs then just returns NULL but if lambda func unifies appropriately
(define (unify_func_name car_x car_y)
  (if (equal? car_x car_y) 
    (if (equal? car_x 'lambda) 'lambda (if (equal? car_x 'λ) 'λ 'NULL)) 
    (if (or (and (equal? car_x 'lambda) (equal? car_y 'λ)) (and (equal? car_y 'lambda) (equal? car_x 'λ))) 'λ 'NULL)
  )
)

#| Dictionary Interface |#
;Given a term and a dictionary returns the translated version of the term and if it's not in the dictionary return term
(define (get_binding term dict)
  (if (not (pair? dict)) term
    (if (not (pair? (car dict))) (if (equal? (car dict) term) (cdr dict) term)
      (let ([bound_term (get_binding term (car dict))]) 
      (
        if (equal? bound_term term) (get_binding term (cdr dict)) bound_term
      ))))
)

;Given a term and a dictionary, return a new dictionary without that term's translation (if it exists) else return original dictionary
(define (del_binding term dict)
  (if (not (pair? dict)) dict
    (if (not (pair? (car dict))) (if (equal? (car dict) term) '() (del_binding term (cdr dict)) )
      (cons (del_binding term (car dict)) (del_binding term (cdr dict)))
    )
  )
)
;I think this isn't working because i'm still checking like a link list not a real tree and seems to work cause i'm cutting off the offending branch ...

;Takes a list of parameters for a sub lambda and deletes those bindings for those parameters
(define (revise_dict parameters dict)
  (if (not (pair? parameters)) 
    (del_binding parameters dict) 
    (del_binding (cdr parameters) (del_binding (car parameters) dict)))
)

;Takes the parameters of two lambda functions and returns pair of dictionaries (dict_x dict_y) that help unify common parameters //Do nothing if param_x and param_y are equal or if not equal length
(define (cons_dict param_x param_y dict_x dict_y) 
  (if (not (equal_length? param_x param_y)) (cons '() '()) ;not cons-ing with dict_x y as this is an edge case
    (if (pair? param_x) 
    (let ([car_x (car param_x)] [car_y (car param_y)] [cdr_x (cdr param_x)] [cdr_y (cdr param_y)])
      (if (equal? car_x car_y) (cons_dict cdr_x cdr_y dict_x dict_y)
        (cons_dict cdr_x cdr_y (cons (cons car_x (combine_symbol car_x car_y)) dict_x) 
          (cons (cons car_y (combine_symbol car_x car_y)) dict_y))))
      (if (equal? param_x param_y) (cons dict_x dict_y) 
        (cons 
          (cons (cons param_x (combine_symbol param_x param_y)) dict_x) 
          (cons (cons param_y (combine_symbol param_x param_y)) dict_y)))
  ))
)

; Takes an expression and applies the dictionary's translations to it 
; If a lambda func appears, calls del_translation on its 
(define (apply_dict exp dict)
  (if (not (pair? exp)) (get_binding exp dict)
    (if (or (equal? (car exp) 'λ) (equal? (car exp) 'lambda))  
      (cons (car exp) (apply_dict (cdr exp) (revise_dict (cadr exp) dict)))
      (cons (apply_dict (car exp) dict) (apply_dict (cdr exp) dict))
  ))
)

#| Main Unification function |#
;Takes x and y and returns the unified versions of x and y
(define (unify x y) 
(if (not(and (pair? x) (pair? y))) (cons x y)
(let ([car_exp (unify_func_name (car x) (car y))])
  (if (equal? car_exp 'NULL) (cons x y) 
  (let ([param_x (car (cdr x))] [param_y (car (cdr y))])
  (let ([dicts (cons_dict param_x param_y '() '())]) (let ([dict_x (car dicts)] [dict_y (cdr dicts)])
  (
    cons (cons car_exp (apply_dict (cdr x) dict_x)) (cons car_exp (apply_dict (cdr y) dict_y))
  )))))
)))

#| Main function of program |#
;combines two expressions into a single one that executes as x if % and y if not %
(define (expr-compare x y)
  (if (or (and x (not y))) '% (if (or (and y (not x))) '(not %)
  (let ([unified_x_y (unify x y)]) (let ([unified_x (car unified_x_y)] [unified_y (cdr unified_x_y)])
  (if (equal? unified_x unified_y) unified_x 
    (if (or (not (and (pair? unified_x) (pair? unified_y))) (not (equal_length? unified_x unified_y)) (xor (equal? (car unified_x) 'if) (equal? (car unified_y) 'if)) (equal? (car unified_x) 'quote) (equal? (car unified_y) 'quote) )
      `(if % ,unified_x ,unified_y)
      (cons (expr-compare (car unified_x) (car unified_y)) (expr-compare (cdr unified_x) (cdr unified_y)) )
    
  ))))))
)
