type test_nonterminals =
  | Phrase | Noun | Verb | Subject | Adj

let test_rules =
  [
  Phrase, [N Subject; N Verb];
  Subject, [N Noun];
  Subject, [N Adj; N Subject];
  Verb, [T "eat"];
  Verb, [T "bark"];
  Noun, [T "Dogs"];
  Noun, [T "Cats"];
  Adj, [T "Smart"];
  Adj, [T "Cute"];
  Adj, [T "Cool"]
  ]

let new_grammar = convert_grammar (Phrase, test_rules)
let test_fragment = ["Smart"; "Cool"; "Dogs"; "bark"]
let matcher_test = ((make_matcher new_grammar accept_empty_suffix test_fragment) =  Some [])
let parser_fragment = ["Cool"; "Smart"; "Cute"; "Cool"; "Dogs"; "eat"]
let parse_tree = unwrap_tree (make_parser new_grammar parser_fragment)
let parser_test = ((parse_tree_leaves parse_tree) = parser_fragment)
