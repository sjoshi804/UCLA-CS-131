(* Check if a set A is a subset of B, by checking if each element of A is in B and the recursive
step reducing set A by calling the function with modifified  A without said element if it is found
else returns false *)
let rec subset a b = match a with   
  [] -> true (* Base case - empty set is a subset of all sets *)
  | head::tail -> if List.mem head b then subset tail b else false

(* Mathematically A = B if A is a subset of B and B is a subset of A, and hence this is implemented using the subset function*)
let equal_sets a b = subset a b && subset b a

(* A list is constructed by recursively adding each element of a to b *)
(* is it better to check if an element exists and add only if it doesn't or add regardless -*)
let rec set_union a b = match a with 
  [] -> b
  | head::tail -> if List.mem head b then set_union tail b else set_union tail ([head] @ b)

(* Uses List.mem to filter set B *)
let set_intersection a b = List.filter (fun x -> List.mem x a) b

(* Uses an inversion of List.mem to filter set A - order matters here *)
let set_diff a b = List.filter (fun x -> not (List.mem x b)) a

(* If f(x) = x then fixed point is found, else recurse using f(x) - any random value can be used f x is a convenient random value available 
that is sure not to be equal to any of the values tried earlier - because of it is, it is the fixed point or there is no fixed point *)
let rec computed_fixed_point eq f x = if eq (f x) x then x else computed_fixed_point eq f (f x)

type ('nonterminal, 'terminal) symbol =
  | N of 'nonterminal
  | T of 'terminal
(* Filter list of rules of grammar recursively by checking which rules can be reached from rules already reached - the first argument is 
the set of all rules that have the starting symbol as the non-terminal symbol leading out *)
let filter_reachable g = 
  let symbol = fst g in 
  let rules = snd g in
  let rec helper validRules = 
    let revisedRules = List.filter(
      fun currentTuple -> 
      if List.mem currentTuple validRules then true (* If current rule is already in valid rules then it stays valid so return true*)
      else (* Else check if there is an 'edge' from a traversed 'node' i.e. rule to the current 'node' i.e. rule *)
      List.exists (
      fun vrTuple -> 
        List.exists (
          function
          | T _ -> false (* If symbol is terminal it is irrelevant *)
          | N item -> item = (fst currentTuple)) (snd vrTuple)) validRules (* Checks if rule's non-terminal occurs in the list corresponding to valid rule*)
          ) rules in
    if validRules = revisedRules (* Stop recursing when validRules doesn't change for a whole function call *)
    then validRules
    else helper revisedRules in 
  (symbol, helper (List.filter (fun x -> fst x = symbol) rules)) (* Constructs the tuple for the grammar from reachable rules and the starting symbol. Also filters down list of rules to only those starting 
  with the starting symbol *)
