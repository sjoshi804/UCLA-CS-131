(*Convert hw1 grammar to hw2 grammar 
A grammar in hw1 was a tuple of a non-terminal and list of tuples of (non terminals and a list of non terminals and terminals) 
A grammar in hw 2 is a tuple of a non-terminal - the starting sumbol and a function that matches non-terminals to a list of possible symbols (symbols captured in lists) it can be used to represent
*)
(* Helper function that concatenates the symbols corresponding to a certain production*)
let rec concatenateSnds = function
  | [] -> []
  | head::tail -> snd head::concatenateSnds tail

(* Function that reduces multiple rules with same L.H.S. to one rule *)
let rec mergeRules = function 
  | [] -> []
  | head::tail -> let fullList = head::tail in [((fst head), concatenateSnds (List.filter(fun x -> fst x = fst head) fullList))] @ mergeRules (List.filter(fun x -> not (fst x = fst head)) tail)

(* helper function that flips arguments List.assoc - converting from association list to a function *)
let reverseAssociate list key = List.assoc key list

(* Function that applies the flipped List.assoc on a list where each L.H.S. appears only one and all the lists it used to match to are now elements in a superlist, returns a starting symbol
i.e. grammar in hw2 - by taking as input grammar of hw1 *)
let convert_grammar = function
  | (startingSymbol, rules) -> (startingSymbol, reverseAssociate (mergeRules rules))

type ('nonterminal, 'terminal) symbol =
    | N of 'nonterminal
    | T of 'terminal

type ('nonterminal, 'terminal) parse_tree =
  | Node of 'nonterminal * ('nonterminal, 'terminal) parse_tree list
  | Leaf of 'terminal

(* Preorder traversal of parse tree to get leaves from left to right, do not add element if it is a non-terminal *)
let rec parse_tree_leaves = function
| Leaf symbol -> [symbol]
| Node (_, children) -> parseChildren children
and
parseChildren = function
| [] -> []
| Leaf symbol::tail -> [symbol] @ parseChildren tail
| symbol::tail -> (parse_tree_leaves symbol) @ (parseChildren tail)

(* List helper function that applies function to first element and if it returns none then recurses on tail else returns *)
let rec any_valid func = function 
| [] -> None
| hd::tail -> let ans = func hd in if ans = None then any_valid func tail else ans

(* Deletes all elements that of second list that are at start of first list *)
let rec revised_remainder fragment = function 
| [] -> fragment
| hd::tail -> revised_remainder (List.tl fragment) tail

let unwrap_tree = function 
| None -> failwith "Empty"
| Some x -> x;;

let unwrap_list = function
| None -> []
| Some x -> x

(* Checks if all symbols within a certain rule returned Some Node/Leaf *)
let rec all_valid remainder func = function
| [] -> []
| hd::tail -> let tree = func remainder hd in if tree = None then [tree]
 else [tree] @ all_valid (revised_remainder remainder (parse_tree_leaves(unwrap_tree(tree)))) func tail

let extract_symbol = function
| Leaf a -> a
| Node (a, _) -> a

let rec extract_rule = function 
| [] ->[]
| hd::tail -> [extract_symbol hd] @ extract_rule tail 

let rec first_new_rule current_rule = function
| [] -> None
| hd::tail -> if hd != current_rule then Some (hd) else first_new_rule current_rule tail 

let rec try_next_rule func current_rule = function 
| [] -> None
| hd::tail -> 
if hd = current_rule then 
  let next = first_new_rule current_rule tail in 
  if next = None then None else func (unwrap_list next)
else try_next_rule func current_rule tail  

(* Actual make_matcher creates the actual matcher function that takes a fragment and 
an acceptor and returns a tuple containing Some parse tree or None and Some suffix string or None*)
let actual_make_matcher = function
| (start_symbol, rules) -> 
  let rec symbol_matcher remainder = function
  | T terminal_symbol -> if remainder = [] then None else 
    if List.hd remainder = terminal_symbol then Some (Leaf (T terminal_symbol)) else None
  | N non_terminal_symbol -> let temp = (any_valid (rules_matcher remainder) (rules non_terminal_symbol)) in if temp = None then None else Some (Node (N non_terminal_symbol, unwrap_list temp))
  and
  rules_matcher remainder = function
  | [] -> None
  | hd::tail -> let children = all_valid remainder symbol_matcher (hd::tail) 
  in 
  if List.exists(fun x -> x = None) children then None else Some (List.map (fun x -> unwrap_tree x) (children))
  in
let actual_matcher fragment acceptor = 
  let rec next_tree = function 
  | Leaf _ -> None
  | Node (T _, _) -> failwith "invalid node"
  | Node (N internal_node, children) -> 
  let new_node = any_valid next_tree (List.rev children)
  in 
  if new_node = None
  then
  let new_children = try_next_rule (rules_matcher fragment) (extract_rule children) (rules internal_node) 
    in if new_children = None then None else Some (Node (N internal_node, (unwrap_list new_children)))
  else Some (Node (N internal_node, 
    List.map (fun x -> 
    if (extract_symbol (unwrap_tree new_node)) = (extract_symbol x) 
      then unwrap_tree new_node 
    else x) children)) 
  (* 
    Try from right most child to left most recursively if there is a next_tree
    if there is replace that that child's tree with an unwrapped version of the tree that was returned
    if not try your own next rules recursively and if this doesn't work either return none

    try next_rule must assume the rule and then try to parse for every one hence it should be passed the function rules_matcher actually
    and hence needs to know remainder too
    pass fragment to this too and before recursing everytime calculate remainder - PENDING!!!!!!!!
  *)
  in 
  let rec try_acceptor parse_tree = 
    let output = acceptor (revised_remainder fragment (parse_tree_leaves (unwrap_tree parse_tree))) in 
    if output = None then 
      let n_tree = next_tree (unwrap_tree parse_tree) in 
      if n_tree = None then None 
      else try_acceptor n_tree
    else Some (parse_tree, output)
  in 
  let start_tree = symbol_matcher fragment (N start_symbol)  in 
  if start_tree = None then None else try_acceptor start_tree
in actual_matcher

let unwrap_tuple = function 
| None -> failwith "Empty"
| Some x -> x

(* Returns a function with a wrapper around the actual_matcher that returns what the acceptor returns*)
let make_matcher grammar = 
fun fragment acceptor -> let ans = ((actual_make_matcher grammar) fragment acceptor) in 
if ans = None then None
else snd (unwrap_tuple ans)

(* Returns a function with a wrapper around the actual_matcher that has an accept_empty acceptor and returns the parse tree instead*)
let make_parser grammar = 
  let accept_empty = function
  | [] -> Some []
  | _ -> None in 
  fun fragment -> let ans = ((actual_make_matcher grammar) fragment accept_empty) in 
  if ans = None then None
  else fst (unwrap_tuple ans)
  
  type awksub_nonterminals =
    | Expr | Term | Lvalue | Incrop | Binop | Num
  
  let awkish_grammar =
    (Expr,
     function
       | Expr ->
           [[N Term; N Binop; N Expr];
            [N Term]]
       | Term ->
     [[N Num];
      [N Lvalue];
      [N Incrop; N Lvalue];
      [N Lvalue; N Incrop];
      [T"("; N Expr; T")"]]
       | Lvalue ->
     [[T"$"; N Expr]]
       | Incrop ->
     [[T"++"];
      [T"--"]]
       | Binop ->
     [[T"+"];
      [T"-"]]
       | Num ->
     [[T"0"]; [T"1"]; [T"2"]; [T"3"]; [T"4"];
      [T"5"]; [T"6"]; [T"7"]; [T"8"]; [T"9"]])

let awk_parser = make_parser awkish_grammar