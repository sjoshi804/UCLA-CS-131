let my_subset_test0 = subset [] [1;2;] (* Empty set test *)
let my_subset_test1 = not (subset [3;1;7] [1;2;3;4]) (* Not a subset test *)
let my_subset_test2 = subset [1;2;3;] [4;2;3;1] (* Is a subset test *)
let my_subset_test3 = subset [1;2;3;] [2;3;1] (* Equal sets test *)

let my_equal_sets_test0 =  not (equal_sets [5;7] [3;1;3]) (* Unequal sets test *)
let my_equal_sets_test1 = equal_sets [1;3;1] [3;1;3] (* Equal sets test *)

let my_set_union_test0 = equal_sets (set_union [1;2;3;4] [1;2;3;4]) [1;2;3;4] (* Equal sets test *)
let my_set_union_test1 = equal_sets (set_union [9;1] [1;9;3]) [1;3;9] (* Regular test *)
let my_set_union_test2 = equal_sets (set_union [] [1]) [1] (* Empty set test *)

let my_set_intersection_test0 =
  equal_sets (set_intersection [] [9;4;5]) [] (* Empty set test *)
let my_set_intersection_test1 =
  equal_sets (set_intersection [1;2;3] [3;4;5]) [3] (* Regular test *)
let my_set_intersection_test2 =
  equal_sets (set_intersection [1;2;3] [1;2;3]) [1;2;3] (* Equal set test *)

let my_set_diff_test0 = equal_sets (set_diff [1;2;3;] [4;2;3;1]) [] (* Subset test *)
let my_set_diff_test1 = equal_sets (set_diff [3;1;7] [1;2;3;4]) [7] (* Regular test *)
let my_set_diff_test2 = equal_sets (set_diff [10;11] []) [10;11] (* Empty set test *)
let my_set_diff_test3 = equal_sets (set_diff [] [10; 11]) [] (* Empty set test 2 *)
let my_set_diff_test3 = equal_sets (set_diff [4;3;1] [4;3;1]) [4;3;1] (* Equal set test *)

let my_computed_fixed_point_test0 =
  computed_fixed_point (=) (fun x -> x / 10) 747234148 = 0 (* Converge at 0 with equality *)
let my_computed_fixed_point_test1 =
  computed_fixed_point (=) (fun x -> x *. 7.) 1000. = infinity (* Converge at infinity with equality - float comparison *)
let my_computed_fixed_point_test2 =
  computed_fixed_point (fun x y -> x < 0 && y < 0) (fun x -> x - 1) 1000 = -1 (* Converge at random value with non-equality comparison *)

type baby_nonterminals =
  | Phrase | Sound | Word | Cry | Essay
  
let baby_grammar =
  Phrase,
  [Essay, [T"This is a sample essay."; N Word; N Phrase];
  Cry, [T"Waah Waah Waah"];
  Sound, [T"khrgh"; T"aooogah!"];
  Word, [N Sound; T "Mama"; T "Papa"];
  Phrase, [N Cry];
  Phrase, [N Word; T"-"; N Sound];
  Phrase, [N Sound]]

let my_filter_reachable_test0 =
  filter_reachable baby_grammar = (Phrase,
  [Cry, [T"Waah Waah Waah"];
  Sound, [T"khrgh"; T"aooogah!"];
  Word, [N Sound; T "Mama"; T "Papa"];
  Phrase, [N Cry];
  Phrase, [N Word; T"-"; N Sound];
  Phrase, [N Sound]])

let my_filter_reachable_test1 =
  filter_reachable (Essay, snd baby_grammar) = (Essay, snd baby_grammar)

let my_filter_reachable_test2 =
  filter_reachable (Essay, List.tl (snd baby_grammar)) = (Essay, [])