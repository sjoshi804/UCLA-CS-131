(* Check if a set A is a subset of B, by checking if each element of A is in B and the recursive
step reducing set A by calling the function with modifified  A without said element if it is found
else returns false *)
let rec subset a b = match a with   
  [] -> true (* Base case - empty set is a subset of all sets *)
  | head::tail -> if List.exists (fun x -> x = head) b then subset tail b else false

(* Mathematically A = B if A is a subset of B and B is a subset of A, and hence this is implemented using the subset function*)
let equal_sets a b = subset a b && subset b a

(* A list is constructed by recursively adding each element of a to b *)
(* is it better to check if an element exists and add only if it doesn't or add regardless *)
let rec set_union a b = match a with 
  [] -> b
  | head::tail -> if List.exists (fun x -> x = head) b then set_union tail b else set_union tail (b@[head])

(* Uses List.mem to filter set B *)
let set_intersection a b = List.filter (fun x -> List.mem x a) b

(* Uses an inversion of List.mem to filter set A - order matters here *)
let rec set_diff a b = List.filter (fun x -> not (List.mem x b))a

(* If f(x) = x then fixed point is found, else recurse using f(x) - any random value can be used f x is a convenient random value available 
that is sure not to be equal to any of the values tried earlier - because of it is, it is the fixed point or there is no fixed point *)
let rec computed_fixed_point eq f x = if eq (f x) x then x else computed_fixed_point eq f (f x)

type ('nonterminal, 'terminal) symbol =
  | N of 'nonterminal
  | T of 'terminal

let filter_reachable g = 
  let symbol = fst g in 
  let rules = snd g in
  let rec helper validRules = 
    let revisedRules = List.filter(
      fun currentTuple -> 
      if List.mem currentTuple validRules then true 
      else
      List.exists (
      fun vrTuple -> 
        List.exists (
          function
          | T _ -> false 
          | N item -> item = (fst currentTuple)) (snd vrTuple)) validRules
          ) rules in
    if validRules = revisedRules
    then validRules
    else helper revisedRules in 
  (symbol, helper (List.filter (fun x -> fst x = symbol) rules))