% Defining the valid syntax for the counts data structure - depicting the visibile counts for the edges
counts([], [], [], []).
counts([_ | Top], [_ | Bottom], [_ | Left], [_ | Right]):- 
    counts(Top, Bottom, Left, Right). 

%Analog of List.hd from Ocaml
hd( [X | _], X).

%Analog of List.tl from Ocaml
tl( [_ | X], X).

%Check length of all rows
length_r([], _).
length_r([Row | Rest], N):-
    length(Row, N),
    length_r(Rest, N).

%Create a list of elements from 1 through N
new_list(0, []).
new_list(N, [Hd | Tl]):-
    length([Hd | Tl], N),
    N = Hd,
    N1 is N - 1,
    new_list(N1, Tl).

%Checks if all elements 1 through N are members - i.e. checks for permutation
perm(N, Row):-
    new_list(N, L),
    permutation(L, Row).

%Checks if all rows are valid
valid_rows(_, []).
valid_rows(N, [Row | Rest]):-
    length(Row, N),
    perm(N, Row),
    valid_rows(N, Rest).

%Transpose a board
transpose([[] | _], []).
transpose(Board, [Col | Rest_Of_Cols]):-
    maplist(hd, Board, Col),
    maplist(tl, Board, Rest_Of_Rows),
    transpose(Rest_Of_Rows, Rest_Of_Cols).
    
valid_board(N, Board):-
    length(Board, N),
    length_r(Board, N),
    valid_rows(N, Board),
    transpose(Board, Board_T),
    valid_rows(N, Board_T).

numbers_in_range( _, []).
numbers_in_range( N, [Hd | Tl]):-
    Hd <= N,
    numbers_in_range( N, Tl).

valid_counts(N, counts(Top, Bottom, Left, Right)):-
    numbers_in_range(N, Top),
    numbers_in_range(N, Bottom),
    numbers_in_range(N, Left),
    numbers_in_range(N, Right).

visibile()
visibility( counts(Top, Bottom, Left, Right), Board):-
    visible(Left, Board),
    maplist(reverse, Board, Board_R),
    visible(Right, Board_R),
    transpose(Board, Board_T)
    visible(Top, Board_T),
    maplist(reverse, Board_T, Board_T_R)
    visible(Bottom, Board_T_R).

%Plain tower - solves without finite domain solver
plain_tower(0, [], counts([], [], [], [])).
plain_tower(N, T, C):-
    number(N),
    valid_counts(N, C),
    valid_board(N, T),
    visibility(C, T).