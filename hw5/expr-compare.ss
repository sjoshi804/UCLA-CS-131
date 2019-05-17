;If outermost function the same, then recurse, else output if % x y
(define (expr-compare x y)
  (if (equal? x y) x 
    (if (not (and (pair? x) (pair? y))) `(if % ,x ,y)
      (cons (expr-compare (car x) (car y)) (expr-compare (cdr x) (cdr y)) )
    )
  )
)

;`((if % ,(car x) ,(car y)) ,(expr-compare (cdr x) (cdr y)))))

;Schemish Pseudocode TODO: Unification of variables a!b
;if (equal? x y) x 
;else if (equal? (car x) (car y)) recurse with (expr-compare (cdr x) (cdr y))
;else if (equal? (cdr x) (cdr y)) recurse with (expr-comare (car x) (car y))
;else `(if % x y)