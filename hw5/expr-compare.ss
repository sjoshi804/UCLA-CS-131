;xor boolean
(define (xor a b)
 (not (boolean=? a b)))

(define (equal_length? a b)
  (if (and (pair? a) (pair? b)) (equal_length? (cdr a) (cdr b)) (and (not (pair? a)) (not (pair? b))) ))

;If outermost function the same, then recurse, else output if % x y
(define (expr-compare x y)
  (if (equal? x y) x 
    (if (or (not (and (pair? x) (pair? y))) (not (equal_length? x y)) (xor (equal? (car x) 'if) (equal? (car y) 'if)) (equal? (car x) 'quote) (equal? (car y) 'quote) )
      `(if % ,x ,y)
      (cons (expr-compare (car x) (car y)) (expr-compare (cdr x) (cdr y)) )
    )
  )
)
;if either is not a pair or only one has empty cdr -> don't recurse
;`((if % ,(car x) ,(car y)) ,(expr-compare (cdr x) (cdr y)))))
;Schemish Pseudocode TODO: Unification of variables a!b TODO: if and quote special case
;if (equal? x y) x 
;else if (equal? (car x) (car y)) recurse with (expr-compare (cdr x) (cdr y))
;else if (equal? (cdr x) (cdr y)) recurse with (expr-comare (car x) (car y))
;else `(if % x y)     
