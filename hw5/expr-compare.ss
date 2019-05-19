#| Generic helper functions |#
;xor boolean function
(define (xor a b)
 (not (boolean=? a b)))

;To check if two expressions have equal number of elements/parameters
(define (equal-length? a b)
  (if (and (pair? a) (pair? b)) (equal-length? (cdr a) (cdr b)) (and (not (pair? a)) (not (pair? b))) ))


#| Helper functions for combining symbols|#
;Combine two symbols X Y into X!Y
(define (combine-symbol x y)
  (string->symbol (string-append (symbol->string x) "!" (symbol->string y))))

;Takes two function names and unifies them, if not lambda funcs then just returns NULL but if lambda func unifies appropriately
(define (unify-func-name car-x car-y)
  (if (equal? car-x car-y) 
    (if (equal? car-x 'lambda) 'lambda (if (equal? car-x 'λ) 'λ 'NULL)) 
    (if (or (and (equal? car-x 'lambda) (equal? car-y 'λ)) (and (equal? car-y 'lambda) (equal? car-x 'λ))) 'λ 'NULL)
  )
)

#| Dictionary Interface |#
;Given a term and a dictionary returns the translated version of the term and if it's not in the dictionary return term
(define (get-binding term dict)
  (if (not (pair? dict)) term
    (if (not (pair? (car dict))) (if (equal? (car dict) term) (cdr dict) term)
      (let ([bound-term (get-binding term (car dict))]) 
      (
        if (equal? bound-term term) (get-binding term (cdr dict)) bound-term
      ))))
)

;Given a term and a dictionary, return a new dictionary without that term's translation (if it exists) else return original dictionary
(define (del-binding term dict)
  (if (not (pair? dict)) dict
    (if (not (pair? (car dict))) (if (equal? (car dict) term) '() (del-binding term (cdr dict)) )
      (cons (del-binding term (car dict)) (del-binding term (cdr dict)))
    )
  )
)
;I think this isn't working because i'm still checking like a link list not a real tree and seems to work cause i'm cutting off the offending branch ...

;Takes a list of parameters for a sub lambda and deletes those bindings for those parameters
(define (revise-dict parameters dict)
  (if (not (pair? parameters)) 
    (del-binding parameters dict) 
    (del-binding (cdr parameters) (del-binding (car parameters) dict)))
)

;Takes the parameters of two lambda functions and returns pair of dictionaries (dict-x dict-y) that help unify common parameters //Do nothing if param-x and param-y are equal or if not equal length
(define (cons-dict param-x param-y dict-x dict-y) 
  (if (not (equal-length? param-x param-y)) (cons '() '()) ;not cons-ing with dict-x y as this is an edge case
    (if (pair? param-x) 
    (let ([car-x (car param-x)] [car-y (car param-y)] [cdr-x (cdr param-x)] [cdr-y (cdr param-y)])
      (if (equal? car-x car-y) (cons-dict cdr-x cdr-y dict-x dict-y)
        (cons-dict cdr-x cdr-y (cons (cons car-x (combine-symbol car-x car-y)) dict-x) 
          (cons (cons car-y (combine-symbol car-x car-y)) dict-y))))
      (if (equal? param-x param-y) (cons dict-x dict-y) 
        (cons 
          (cons (cons param-x (combine-symbol param-x param-y)) dict-x) 
          (cons (cons param-y (combine-symbol param-x param-y)) dict-y)))
  ))
)

; Takes an expression and applies the dictionary's translations to it 
; If a lambda func appears, calls del-translation on its 
(define (apply-dict exp dict)
  (if (not (pair? exp)) (get-binding exp dict)
    (if (or (equal? (car exp) 'λ) (equal? (car exp) 'lambda))  
      (cons (car exp) (apply-dict (cdr exp) (revise-dict (cadr exp) dict)))
      (cons (apply-dict (car exp) dict) (apply-dict (cdr exp) dict))
  ))
)

#| Main Unification function |#
;Takes x and y and returns the unified versions of x and y
(define (unify x y) 
(if (not(and (pair? x) (pair? y))) (cons x y)
(let ([car-exp (unify-func-name (car x) (car y))])
  (if (equal? car-exp 'NULL) (cons x y) 
  (let ([param-x (car (cdr x))] [param-y (car (cdr y))])
  (let ([dicts (cons-dict param-x param-y '() '())]) (let ([dict-x (car dicts)] [dict-y (cdr dicts)])
  (
    cons (cons car-exp (apply-dict (cdr x) dict-x)) (cons car-exp (apply-dict (cdr y) dict-y))
  )))))
)))

#| Main function of program |#
;combines two expressions into a single one that executes as x if % and y if not %
(define (expr-compare x y)
  (if (or (and x (not y))) '% (if (or (and y (not x))) '(not %)
  (let ([unified-x-y (unify x y)]) (let ([unified-x (car unified-x-y)] [unified-y (cdr unified-x-y)])
  (if (equal? unified-x unified-y) unified-x 
    (if (or (not (and (pair? unified-x) (pair? unified-y))) (not (equal-length? unified-x unified-y)) (xor (equal? (car unified-x) 'if) (equal? (car unified-y) 'if)) (equal? (car unified-x) 'quote) (equal? (car unified-y) 'quote) )
      `(if % ,unified-x ,unified-y)
      (cons (expr-compare (car unified-x) (car unified-y)) (expr-compare (cdr unified-x) (cdr unified-y)) )
    
  ))))))
)

(define (test-expr-compare x y)
  (and 
    (equal? (eval `(let ([% #t]) ,(expr-compare x y)))  (eval x))
    (equal? (eval `(let ([% #f]) ,(expr-compare x y))) (eval y))
  )
)



