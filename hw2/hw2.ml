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
let listHelper func = function 
| [] -> None
| hd::tail -> if func hd = None then listHelper func tail else func hd

(* Runs acceptor function on tail if returns none then returns none else returns Some (Lead hd remainder) *)
let run_acceptor acceptor = function 
| [] -> None
| hd::tail -> if acceptor tail = None then None else Some (Leaf hd)

(* Helper function to check if parse tree is complete *)
let is_complete parse_tree = true;

(* Actual make_matcher creates the actual matcher function that takes a fragment and an acceptor and returns a tuple containing Some parse tree or None and Some suffix string or None*)
let actual_make_matcher = function
| (startSymbol, rules) -> 
  let rec symbol_matcher remainder parse_tree acceptor = function
  | T terminal_symbol -> 
    if List.hd remainder = terminal_symbol then 
      if is_complete parse_tree then run_acceptor acceptor remainder else Some (Leaf terminal_symbol)
    else None
  | N non_terminal_symbol -> listHelper (rules_matcher remainder parse_tree acceptor) (rules non_terminal_symbol)
  and
  rules_matcher remainder p_tree acceptor = function 
  | [] -> None
  | hd::tail -> let children = List.map (fun x -> symbol_matcher remainder p_tree acceptor x) hd::tail in if valid children then Some (children) else None  
  in 
  let actual_matcher fragment acceptor = 
    let tree symbol_matcher fragment None acceptor in
    if tree = None then None
    else let prefix = parse_tree_leaves tree in acceptor (List.filter (fun x -> not (List.mem x prefix)) fragment)

(* Returns a function with a wrapper around the actual_matcher that returns what the acceptor returns*)
let make_matcher grammar = 
fun fragment acceptor -> snd ((actual_make_matcher grammar) fragment acceptor)

(* Returns a function with a wrapper around the actual_matcher that has an accept_empty acceptor and returns the parse tree instead*)
let make_parser grammar = 
  let accept_empty = function
  | "" -> Some ""
  | _ -> None in 
  fun fragment -> fst ((actual_make_matcher grammar) fragment accept_empty)
  