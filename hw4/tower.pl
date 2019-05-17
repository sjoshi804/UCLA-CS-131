% Defining the valid syntax for the counts data structure - depicting the visible counts for the edges
counts( [], [], [], []).
counts([_ | Top], [_ | Bottom], [_ | Left], [_ | Right]):- 
    counts(Top, Bottom, Left, Right). 

%Analog of List.hd from Ocaml
hd( [X | _], X).

%Analog of List.tl from Ocaml
tl( [_ | X], X).

%Permutation, checks if Row is permutation of 1...N
%Base Case
perm( 0, []).
%between(1, N, X) -> X is a list with all elements from 1 ... N and tries to find all in Possible_Row
perm( N, Row):-
    findall(X, between(1, N, X), Possible_Row),
    permutation(Possible_Row, Row).

%Check length of all rows
length_r([], _).
length_r([Row | Rest], N):-
    length(Row, N),
    length_r(Rest, N).

%Transpose a board
%Base case
transpose([[] | _], []).

%Recurse, First extract first column, then extract remaining rows and recurse
transpose(Board, [Col | Rest_Of_Cols]):-
    maplist(hd, Board, Col),
    maplist(tl, Board, Rest_Of_Rows),
    transpose(Rest_Of_Rows, Rest_Of_Cols).

%Counts the number of towers visible in a row looking from left to right
%Base case
count_visible(_, [], 0).

%First element is not visible -> Don't increment, Don't change Max_Yet
count_visible( Max_Yet, [Hd | Tl], Count):-
    Max_Yet > Hd,
    count_visible( Max_Yet, Tl, Count).

%First element is visible -> Increment and update Max_Yet
count_visible( Max_Yet, [Hd | Tl], Count):-
    Max_Yet < Hd,
    count_visible(Hd, Tl, Count_minus_one),
    Count is (Count_minus_one + 1). 
    %Note Increment is done after recursion so that the binding given in the base case, cascades up 
    %and is used. Wouldn't work in different order, despite commutativity of and. 

%Check visibility
visibility( Board, Counts):-
    maplist(count_visible(0), Board, Counts).

%Plain tower - solves without finite domain solver
plain_tower( 0, [[]], counts([], [], [], [])).
plain_tower( N, T, C):-
    C = counts(Top, Bottom, Left, Right),
    Board = T,
    length(Top, N),
    length(Board, N),
    valid_board(N, [], Board, Left, Right),
    transpose(Board, Board_T),
    visibility(Board_T, Top),
    maplist(reverse, Board_T, Board_T_R),
    visibility(Board_T_R, Bottom).

%Checks if all elements in a list are unique
all_unique([]).
all_unique([Hd | Tl]):-
    \+ (member(Hd, Tl)), 
    all_unique(Tl).

%Generates valid boards by checking if rows are permutations and simultaneously check if the implied column has all unique and check if row is valid from LeftCount and Right Count
%Running multiple checks helps speed up considerably
%Base Case
valid_board( N, Accumulator, [], [], []):-
    length(Accumulator, N).

%Recurse
valid_board( N, Accumulator, [Row | Rest_Of_Rows], [Left_hd | Left_tl], [Right_hd | Right_tl]):-
    length(Accumulator, N_minus_Rest),
    N_minus_Rest < N,
    perm(N, Row),
    count_visible(0, Row, Left_hd), 
    reverse(Row, Reverse_Row),
    count_visible(0, Reverse_Row, Right_hd),
    transpose([Row | Accumulator], M_T),
    maplist(all_unique, M_T),
    valid_board(N, [Row | Accumulator], Rest_Of_Rows, Left_tl, Right_tl).

%No-optimization for N < 3
ambiguous( N, C, T1, T2):-
    N < 3,
    plain_tower(N, T1, C),
    plain_tower(N, T2, C),
    \+ (T1 = T2). 

%Sped-up version using random guess
ambiguous( N, C, T1, T2):-
    N >= 3,
    C = counts(_, [3| _], _, _),
    plain_tower(N, T1, C),
    plain_tower(N, T2, C),
    \+ (T1 = T2), !.     

%Brute force search all possible answers for correctness
ambiguous( N, C, T1, T2):-
    N >= 3,
    plain_tower(N, T1, C),
    plain_tower(N, T2, C),
    \+ (T1 = T2), !.   

%Solving tower - with fd solver
%Plain tower - solves without finite domain solver
tower( 0, [[]], counts([], [], [], [])).
tower( N, Board, C):-
    C = counts(Top, Bottom, Left, Right),
    %Check if all counts only have elements 1...N and have length N
    fd_valid_counts(N, C),
    %Constraints to generate a valid matrix (valid rows & valid cols)
    length(Board, N),
    maplist(fd_wrapper_domain(N), Board),
    maplist(fd_all_different, Board),
    transpose(Board, Board_T),
    maplist(fd_all_different, Board_T),
    %Constraints for visibility
    %Check Left
    fd_visibility(Board, Left),
    %Reverse and check Right
    maplist(reverse, Board, Board_R),
    fd_visibility(Board_R, Right),
    %Check Top with Transpose
    fd_visibility(Board_T, Top),
    %Reverse and check Bottom
    maplist(reverse, Board_T, Board_T_R),
    fd_visibility(Board_T_R, Bottom),
    %Label the counts first
    fd_labeling(Left),
    fd_labeling(Right),
    fd_labeling(Top),
    fd_labeling(Bottom),
    % Finally label the board.
    maplist(fd_labeling, Board).

fd_wrapper_domain( N, Element):-
    length(Element, N),
    fd_domain(Element, 1, N).

fd_valid_counts( N, counts(Top, Bottom, Left, Right)):-
    length(Top, N),
    length(Bottom, N),
    length(Left, N),
    length(Right, N),
    fd_domain(Top, 1, N),
    fd_domain(Bottom, 1, N),
    fd_domain(Left, 1, N),
    fd_domain(Right, 1, N).
    
%Counts the number of towers visible in a row looking from left to right
%Base case
fd_count_visible(_, [], 0).

%First element is not visible -> Don't increment, Don't change Max_Yet
fd_count_visible( Max_Yet, [Hd | Tl], Count):-
    Max_Yet #> Hd,
    fd_count_visible( Max_Yet, Tl, Count).

%First element is visible -> Increment and update Max_Yet
fd_count_visible( Max_Yet, [Hd | Tl], Count):-
    Max_Yet #< Hd,
    fd_count_visible(Hd, Tl, Count_minus_one),
    Count is (Count_minus_one + 1). 
    %Note Increment is done after recursion so that the binding given in the base case, cascades up 
    %and is used. Wouldn't work in different order, despite commutativity of and. 

%Check visibility
fd_visibility( Board, Counts):-
    maplist(fd_count_visible(0), Board, Counts).

%Timing functions
tower_test( Time) :-
    statistics(cpu_time,[Start|_]),
    tower(5, T, counts([2,2,3,5,1],[2,3,2,1,4],[3,1,2,3,2],[1,4,2,3,2])),
    tower(5, T, C),
    tower(N, T, C),
    statistics(cpu_time, [Stop|_]),
    Time is Stop - Start.
    
plain_tower_test( Time) :-
    statistics(cpu_time, [Start|_]),
    plain_tower(5, T, counts([2,2,3,5,1],[2,3,2,1,4],[3,1,2,3,2],[1,4,2,3,2])),
    plain_tower(5, T, C),
    plain_tower(N, T, C),
    statistics(cpu_time, [Stop|_]),
    Time is Stop - Start. 

speedup_once( Ratio) :-
    tower_test(Opt),
    plain_tower_test(Naive),
    Ratio is Naive/Opt, !.  

speedup( Ratio):-
    length(Ratio_List, 10),
    maplist(speedup_once, Ratio_List),
    sum_list(Ratio_List, Total),
    Ratio is Total / 10.