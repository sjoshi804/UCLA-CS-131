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
| Leaf a -> T a
| Node (a, _) -> N a

let rec extract_rule = function 
| [] ->[]
| hd::tail -> [extract_symbol hd] @ extract_rule tail 

let rec only_new_rules current_rule = function
| [] -> []
| hd::tail -> if hd = current_rule then only_new_rules current_rule tail else hd::tail

let rec try_next_rule func current_rule = function 
| [] -> None
| [a; b] -> if current_rule = a then func b else None
| _ -> None

let get2nd = function 
| [a; b] -> b

(* Actual make_matcher creates the actual matcher function that takes a fragment and 
an acceptor and returns a tuple containing Some parse tree or None and Some suffix string or None*)
let actual_make_matcher = function
| (start_symbol, rules) -> 
  let rec symbol_matcher remainder = function
  | T terminal_symbol -> if remainder = [] then None else 
    if List.hd remainder = terminal_symbol then Some (Leaf (terminal_symbol)) else None
  | N non_terminal_symbol -> let temp = (any_valid (rules_matcher remainder) (rules non_terminal_symbol)) in 
  if temp = None then None else Some (Node (non_terminal_symbol, (unwrap_list temp)))
  and
  rules_matcher remainder = function
  | [] -> None
  | hd::tail -> let children = all_valid remainder symbol_matcher (hd::tail) 
  in 
  if List.exists(fun x -> x = None) children then None else Some (List.map (fun x -> unwrap_tree x) (children))
  in
let actual_matcher acceptor fragment = 
  let rec next_tree suffix = function 
  | Leaf a -> (None, a::suffix)
  | Node (internal_node, children) -> let temp = (any_valid (rules_matcher suffix) (List.tl (rules internal_node))) in 
  if temp = None then (None, suffix) else (Some (Node (internal_node, (unwrap_list temp))), suffix)(*
  let new_children = rules_matcher suffix (get2nd (rules internal_node)) in
   if unwrap_list new_children = children then (None, []) else *)(*
  let new_rules_children = rules_matcher suffix [(*try_next_rule (rules_matcher suffix) (extract_rule children) (rules internal_node)*) in
    if new_rules_children = None then (None, suffix) else (Some(Node(internal_node, children)), suffix)*)
  (*let child_output = (next_tree_from_children suffix (List.rev children)) in
  let new_children = fst child_output in
  let new_suffix = snd child_output in 
  if new_children = None
  then 
    let new_rules_children = try_next_rule (rules_matcher suffix) (extract_rule children) (rules internal_node) in
    if new_rules_children = None then (None, new_suffix) else (Some(Node(internal_node, (unwrap_list new_rules_children))), new_suffix)
  else (Some(Node(internal_node, List.rev (unwrap_list new_children))), new_suffix) *)
  and 
  next_tree_from_children suffix = function 
  | [] -> (None, suffix)
  | [hd] -> let next_tree_head = next_tree suffix hd in 
    if fst next_tree_head = None then (None, snd next_tree_head) else (Some [unwrap_tree(fst next_tree_head)], suffix)
  | hd::tail -> let next_tree_head = next_tree suffix hd in 
    if fst next_tree_head = None then 
      let rec_call = next_tree_from_children (snd next_tree_head) tail in 
      if fst rec_call = None then (None, (snd rec_call)) else let new_tail = unwrap_list (fst rec_call) in (Some (hd::new_tail), suffix)
    else (Some ((unwrap_tree (fst next_tree_head))::tail), suffix)
  in 
  let rec try_acceptor parse_tree = 
    let prefix = (parse_tree_leaves (unwrap_tree parse_tree)) in
    let suffix = (revised_remainder fragment prefix) in
    let output = acceptor suffix in 
    if output = None then 
      let n_tree = fst (next_tree fragment (unwrap_tree parse_tree)) in 
      if n_tree = None then None 
      else Some (n_tree, output)
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
fun acceptor fragment -> let ans = ((actual_make_matcher grammar) acceptor fragment) in 
if ans = None then None
else snd (unwrap_tuple ans)

(* Returns a function with a wrapper around the actual_matcher that has an accept_empty acceptor and returns the parse tree instead*)
let make_parser grammar = 
  let accept_empty = function
  | [] -> Some []
  | _ -> None in 
  fun fragment -> let ans = ((actual_make_matcher grammar) accept_empty fragment) in 
  if ans = None then None
  else fst (unwrap_tuple ans)

  let accept_all string = Some string
let accept_empty_suffix = function
   | _::_ -> None
   | x -> Some x

(* An example grammar for a small subset of Awk.
   This grammar is not the same as Homework 1; it is
   instead the same as the grammar under
   "Theoretical background" above.  *)

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

let test0 =
  ((make_matcher awkish_grammar) accept_all ["ouch"] = None)

let test1 =
  ((make_matcher awkish_grammar accept_all ["9"])
   = Some [])

let test2 =
  ((make_matcher awkish_grammar accept_all ["9"; "+"; "$"; "1"; "+"])
   = Some ["+"])

let test3 =
  ((make_matcher awkish_grammar accept_empty_suffix ["9"; "+"; "$"; "1"; "+"])
   = None)

(* This one might take a bit longer.... *)
let test4 =
 ((make_matcher awkish_grammar accept_all
     ["("; "$"; "8"; ")"; "-"; "$"; "++"; "$"; "--"; "$"; "9"; "+";
      "("; "$"; "++"; "$"; "2"; "+"; "("; "8"; ")"; "-"; "9"; ")";
      "-"; "("; "$"; "$"; "$"; "$"; "$"; "++"; "$"; "$"; "5"; "++";
      "++"; "--"; ")"; "-"; "++"; "$"; "$"; "("; "$"; "8"; "++"; ")";
      "++"; "+"; "0"])
  = Some [])

let test5 =
  (parse_tree_leaves (Node ("+", [Leaf 3; Node ("*", [Leaf 4; Leaf 5])]))
   = [3; 4; 5])

let small_awk_frag = ["$"; "1"; "++"; "-"; "2"]

let test6 =
  ((make_parser awkish_grammar small_awk_frag)
   = Some (Node (Expr,
		 [Node (Term,
			[Node (Lvalue,
			       [Leaf "$";
				Node (Expr,
				      [Node (Term,
					     [Node (Num,
						    [Leaf "1"])])])]);
			 Node (Incrop, [Leaf "++"])]);
		  Node (Binop,
			[Leaf "-"]);
		  Node (Expr,
			[Node (Term,
			       [Node (Num,
				      [Leaf "2"])])])])))
let test7 =
  match make_parser awkish_grammar small_awk_frag with
    | Some tree -> parse_tree_leaves tree = small_awk_frag
    | _ -> false


let test_grammar = [Expr, [T 0];Expr, [T 0; T 1]]
let gram = convert_grammar (Expr, test_grammar)
let p = make_parser gram