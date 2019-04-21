
type ('nonterminal, 'terminal) parse_tree =
  | Node of 'nonterminal * ('nonterminal, 'terminal) parse_tree list
  | Leaf of 'terminal
 
type ('nonterminal, 'terminal) symbol =
 | N of 'nonterminal
 | T of 'terminal
   
(*helper function to convert grammar*)
let rec convert nonterm_symbol list_rules created_list =
  match list_rules with
  [] -> created_list
  | head::rst -> if (fst head) = nonterm_symbol then (convert nonterm_symbol rst ((snd head)::created_list)) else (convert nonterm_symbol rst created_list) 

(*convert grammar from old to new -> basically write a function as second part of tuple*)
let convert_grammar graml = 
  (fst graml, function x -> (convert x (snd graml) []));;

(*parse tree by splitting it into two functions - one handles the Node/Leafs other handles the lists within the right part of node*)
let rec parse_tree_leaves tree = 
let rec parse_tree_leaves_helper2 tree return_list = 
  match tree with 
  | Node (_, rest ) -> parse_tree_leaves_helper rest return_list
  | Leaf terminal_symbol -> terminal_symbol::return_list

and parse_tree_leaves_helper tree return_list = 
  match tree with 
  | [] -> return_list
  | head::rst -> parse_tree_leaves_helper2 head return_list @ parse_tree_leaves_helper rst return_list

in match tree with (tree_inside) -> parse_tree_leaves_helper2 tree [];;

(*function that makes matcher, make matcher takes in grammar and then returns a function that takes in acceptor, frag and returns and option *)
let rec make_matcher_help root grammar_rules = 
  let rec make_append_matcher grammar_rules top rule_options = 
    match rule_options with 
    | [] -> (fun acceptor frag -> None) (*no more rules and acceptor hasn't accepted any of the previous ones so return None*)
    | hd::rst -> 
      (fun acceptor frag ->
        let match_single = match_rules_sublist grammar_rules hd
        in match match_single acceptor frag with
          | None -> make_append_matcher grammar_rules top rst acceptor frag
          | Some x -> match_single acceptor frag
      )

  and match_rules_sublist grammar_rules rules_sublist = 
    match rules_sublist with 
    | [] -> (fun acceptor frag -> acceptor frag) (*no more rules to try out return what acceptor returns*)
    | hd::rst -> 
      (match hd with 
      | T a -> (
                fun acceptor frag -> 
                match frag with 
                | [] -> None
                | firstfrag::rstfrag -> 
                      if firstfrag = a then match_rules_sublist grammar_rules rst acceptor rstfrag
                      else None
               )

      | N a -> (
                fun acceptor frag -> 
                let match_non_term = make_matcher_help a grammar_rules
                in match_non_term (match_rules_sublist grammar_rules rst acceptor) frag (*matcher (formed by make matcher and grammar) and acceptor makes new acceptor*)
              )
      )
  in make_append_matcher grammar_rules root (grammar_rules root) (*grammar_rules is the funcion that takes in expression and return list of rules*)


let make_matcher gram = 
  make_matcher_help (fst gram) (snd gram) 

(*derived from make matcher function, except also including a list of the derivation which is returned by the acceptor in the main make parser function*)
let rec make_parser_help root grammar_rules acceptor d = 
  let rec make_append_parser grammar_rules top rule_options acceptor d = 
    match rule_options with 
    | [] -> (fun frag -> None) (*no more rules and acceptor hasn't accepted any of the previous ones so return None*)
    | hd::rst -> 
      (fun frag ->
        let parse_single = parse_rules_sublist grammar_rules hd
        in match parse_single acceptor d frag with
          | None -> make_append_parser grammar_rules top rst acceptor d frag
          | Some _ -> parse_single acceptor (d@[(top, hd)]) frag
      )

  and parse_rules_sublist grammar_rules rules_sublist acceptor d = 
    match rules_sublist with 
    | [] -> (fun frag -> acceptor d frag) (*no more rules to try out return what acceptor returns*)
    | hd::rst -> 
      (match hd with 
      | T a -> (
                fun frag -> 
                match frag with 
                | [] -> None
                | firstfrag::rstfrag -> 
                      if firstfrag = a then parse_rules_sublist grammar_rules rst acceptor d rstfrag
                      else None
               )

      | N a -> (
                fun frag -> 
                let match_non_term = make_parser_help a grammar_rules
                in match_non_term (parse_rules_sublist grammar_rules rst acceptor) d frag (*matcher (formed by make matcher and grammar) and acceptor makes new acceptor*)
              )
      )
  in make_append_parser grammar_rules root (grammar_rules root) acceptor d (*grammar_rules is the funcion that takes in expression and return list of rules*)

(*make the parse tree with the derivation which is a list of tuples, important part is keeping track of remaining tuples that haven't been used to make a tree yet*)
let rec make_parse_tree list_tuples = 
  let rec make_tree remaining_tuples list_terms = (*makes tree from list of terms in rhs *)
    match list_terms with 
    | [] -> remaining_tuples, []
    | N head::rst -> 
    (
      let get_head_tree = make_parse_tree remaining_tuples
      in 
      let get_rest_tree = make_tree (fst get_head_tree) rst 
      in 
      (fst get_rest_tree, (snd get_head_tree) :: (snd get_rest_tree))
    )
    | T head::rst -> 
    (
      let get_rest_tree = make_tree remaining_tuples rst
      in 
      (fst get_rest_tree, (Leaf head) :: (snd get_rest_tree))
    )
  in 
  match list_tuples with 
  | hd::rst -> let result = make_tree rst (snd hd) in (fst result, Node (fst hd, snd result)) (*fst result is list of remaining tuples,fst head is starting,snd result is list which corresponds to parse tree*)




(*main make parser function, first uses the first function to get the derivation if one exists, and if it exists make a parse tree out of it and return Some(tree)*)
let make_parser gram = 
  let accept_empty_suffix_d derivation = function
  | [] -> Some (derivation)
  | _ -> None
  in
  (fun frag -> 
  let list_parse = make_parser_help (fst gram) (snd gram) accept_empty_suffix_d []
  in  match list_parse frag with
  | Some a -> let tree = make_parse_tree a in Some (snd tree)
  | None -> None
  )

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
    [N Lvalue; N Incrop];

      [N Incrop; N Lvalue];
        
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

