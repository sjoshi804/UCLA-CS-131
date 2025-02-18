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
| hd::tail -> if fragment = [] then failwith "empty fragment" else revised_remainder (List.tl fragment) tail

let unwrap_tree = function 
| None -> failwith "Empty"
| Some x -> x;;

let unwrap_list = function
| None -> []
| Some x -> x

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

let rec new_rules current_rule = function 
  | [] -> []
  | hd::tail -> if hd = current_rule then List.filter (fun x -> x != hd)
 tail else new_rules current_rule tail

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
  | hd::tail -> all_valid remainder [] (hd::tail) 
  and
  next_tree suffix = function 
  | Leaf a -> (None, a::suffix)
  | Node (internal_node, children) -> 
  let new_tuple = next_children [] suffix (List.rev children) in 
  let new_suffix = snd new_tuple in 
  let new_children = fst new_tuple in 
  if new_children = None 
  then 
    let temp = (any_valid (rules_matcher new_suffix) (new_rules (extract_rule children) (rules internal_node))) in 
    if temp = None 
      then (None, new_suffix)
    else 
      let my_tree = Node (internal_node, (unwrap_list temp)) in 
      let prefix = (parse_tree_leaves my_tree) in 
      let revised_suffix = revised_remainder new_suffix prefix in
      (Some(my_tree), revised_suffix)
  else (Some(Node(internal_node, List.rev (unwrap_list new_children))), new_suffix)
  and 
  next_children redo suffix = function 
  | [] -> (None, suffix)
  | hd::tail -> let next_tuple_hd = next_tree suffix hd in
  let next_tree = fst next_tuple_hd in 
  let new_suffix = snd next_tuple_hd in
  if next_tree = None 
    then next_children ((extract_symbol hd)::redo) new_suffix tail
  else 
  let left = (unwrap_tree next_tree)::tail in 
  if redo = [] 
    then (Some (left), new_suffix)
 else 
    let right = rules_matcher new_suffix redo in 
    if right = None 
      then next_children ((extract_symbol hd)::redo) new_suffix tail
    else 
    let prefixes = List.map (fun x -> parse_tree_leaves x) (unwrap_list right) in 
    let revised_suffix = revised_remainder new_suffix (List.flatten prefixes) in
    (Some ((List.rev (unwrap_list right)) @ left), revised_suffix) 
  and
all_valid remainder checked = function
| [] -> Some (List.rev checked)
| hd::tail -> 
let tree = symbol_matcher remainder hd in 
if tree = None 
then 
  let parent_suffix_list = List.map (fun x -> parse_tree_leaves x) checked in
  let parent_suffix = remainder @ (List.flatten parent_suffix_list) in
  let new_tuple = next_children [] parent_suffix checked in
  let new_list_of_trees = fst new_tuple in 
  if new_list_of_trees = None then None
  else let new_suffix = snd new_tuple in
  all_valid new_suffix (unwrap_list new_list_of_trees) ([hd]@tail)
else let unwrapped_tree = unwrap_tree tree in 
all_valid (revised_remainder remainder (parse_tree_leaves unwrapped_tree)) ([(unwrapped_tree)]@checked) tail 

 in
let actual_matcher acceptor fragment = 
  let rec try_acceptor parse_tree = 
    let prefix = (parse_tree_leaves (unwrap_tree parse_tree)) in
    if fragment = [] then None else
    let suffix = (revised_remainder fragment prefix) in
    let output = acceptor suffix in 
    if output = None then 
      let n_tree = fst (next_tree suffix (unwrap_tree parse_tree)) in 
      if n_tree = None then None 
      else try_acceptor n_tree
    else  Some (parse_tree, output)
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
