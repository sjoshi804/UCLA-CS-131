% Defining the valid syntax for the counts data structure - depicting the visible counts for the edges
counts( [], [], [], []).
counts([_ | Top], [_ | Bottom], [_ | Left], [_ | Right]):- 
    counts(Top, Bottom, Left, Right). 

%Analog of List.hd from Ocaml
hd( [X | _], X).

%Analog of List.tl from Ocaml
tl( [_ | X], X).

%Permutation
perm( 0, []).
perm( N, Row):-
    findall(X, between(1, N, X), Possible_Row),
    permutation(Possible_Row, Row).

%Check length of all rows
length_r([], _).
length_r([Row | Rest], N):-
    length(Row, N),
    length_r(Rest, N).

%Transpose a board
transpose([[] | _], []).
transpose(Board, [Col | Rest_Of_Cols]):-
    maplist(hd, Board, Col),
    maplist(tl, Board, Rest_Of_Rows),
    transpose(Rest_Of_Rows, Rest_Of_Cols).

%Checks if counts is valid
valid_counts(N, counts(Top, Bottom, Left, Right)):-
    maplist(between(1, N), Top),
    maplist(between(1, N), Bottom),
    maplist(between(1, N), Left),
    maplist(between(1, N), Right).

count_visible(_, [], 0).

count_visible( Max_Yet, [Hd | Tl], Count):-
    Max_Yet > Hd,
    count_visible( Max_Yet, Tl, Count).

count_visible( Max_Yet, [Hd | Tl], Count):-
    Max_Yet < Hd,
    count_visible(Hd, Tl, Count_minus_one),
    Count is (Count_minus_one + 1).

%Check visibility
visibility( Board, Counts):-
    maplist(count_visible(0), Board, Counts).

%Plain tower - solves without finite domain solver
plain_tower( 0, [], counts([], [], [], [])).
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


all_unique([]).
all_unique([Hd | Tl]):-
    \+ (member(Hd, Tl)), 
    all_unique(Tl).

valid_board( N, Accumulator, [], [], []):-
    length(Accumulator, N).

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

ambiguous( N, C, T1, T2):-
    plain_tower(N, C, T1),
    plain_tower(N, C, T2),
    \+ (T1, T2).