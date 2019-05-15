% Defining the valid syntax for the counts data structure - depicting the visibile counts for the edges
counts([], [], [], []).
counts([_ | Top], [_ | Bottom], [_ | Left], [_ | Right]):- 
    counts(Top, Bottom, Left, Right ). 

%Analog of List.hd from Ocaml
hd([X | _], X).
hd([_, Tl], X):-
    hd(Tl, X).

%Check length of all rows
length_r([], _).
length_r([Row | Rest], N):-
    length(Row, N),
    length_r(Rest, N).

%Checks if all elements 1 through N are members - i.e. checks for permutation
perm(0, _).
perm(N, Row):-
    member(N, Row),
    perm(N - 1, Row).

%Checks if Board has valid dimensions i.e N x N
validDimensions(N, Board):-
    length(Board, N),
    length_r(Board, N).

%Checks if all rows are valid
validRows(N, []):-
    number(N).
validRows(N, [Row | Rest]):-
    number(N), 
    perm(N, Row),
    validRows(N, Rest).

%Transpose a matrix
transpose([], []).
transpose(Board, [])


    
validBoard(N, Board):-
    validRows(N, Board),
    transpose(Board, Board_T),
    validRows(N, Board_T).

%Plain tower - solves without finite domain solvering 
plain_tower(0, [], counts([], [], [], [])).
plain_tower(N, Board, counts(Top, Bottom, Left, Right)):-
    validDimensions(N, Board)
    validBoard(N, Board)