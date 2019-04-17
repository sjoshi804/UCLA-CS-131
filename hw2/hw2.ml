(* Convert hw1 grammar to hw2 grammar 
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
| hd::tail -> if func hd = None then any_valid func tail else func hd

(* Deletes all elements that of second list that are at start of first list *)
let rec revised_remainder fragment = function 
| [] -> fragment
| hd::tail -> revised_remainder (List.tl fragment) tail

let unwrap_tree = function 
| None -> Leaf ""
| Some x -> x;;

let unwrap_list = function
| None -> []
| Some x -> x

(* Checks if all symbols within a certain rule returned Some Node/Leaf *)
let rec all_valid remainder func = function
| [] -> []
| hd::tail -> let tree = func (remainder hd) in if tree = None then [tree]
 else [tree] @ all_valid (revised_remainder (remainder (parse_tree_leaves(unwrap_tree(tree))))) func tail

(* Actual make_matcher creates the actual matcher function that takes a fragment and 
an acceptor and returns a tuple containing Some parse tree or None and Some suffix string or None*)
let actual_make_matcher = function
| (start_symbol, rules) -> 
  let rec symbol_matcher remainder = function
  | T terminal_symbol -> 
    if List.hd remainder = terminal_symbol then Some (Leaf terminal_symbol) else None
  | N non_terminal_symbol -> Some (Node (non_terminal_symbol, unwrap_list(any_valid (rules_matcher remainder) (rules non_terminal_symbol))))
  and
  rules_matcher remainder = function
  | [] -> None
  | hd::tail -> let children = all_valid remainder symbol_matcher hd::tail in if List.exists(fun x -> x = None) children then None else Some (List.map (fun x -> unwrap_tree x) (children))
  in
let actual_matcher fragment acceptor = 
  let next_tree p_tree = parse_tree in 
  let try_acceptor parse_tree = 
    let output = acceptor (suffix_of (parse_tree)) in 
    if output = None then 
      let n_tree = next_tree parse_tree in 
      if n_tree = None then None 
      else try_acceptor n_tree
    else Some (parse_tree, output)
  in try_acceptor (symbol_matcher fragment start_symbol)
in actual_matcher

(* Returns a function with a wrapper around the actual_matcher that returns what the acceptor returns*)
let make_matcher grammar = 
fun fragment acceptor -> snd ((actual_make_matcher grammar) fragment acceptor)

(* Returns a function with a wrapper around the actual_matcher that has an accept_empty acceptor and returns the parse tree instead*)
let make_parser grammar = 
  let accept_empty = function
  | "" -> Some ""
  | _ -> None in 
  fun fragment -> fst ((actual_make_matcher grammar) fragment accept_empty)
  