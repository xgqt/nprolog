/*
    exercize to remember prolog for me
    module test
*/

:- module(sort,[bsort/2,msort/2,qsort/2]).

bsort(X,X) :-
    bubble1(X,X1),
    X == X1.
bsort(X,X2) :-
    bubble1(X,X1),
    bsort(X1,X2).

bubble1([],[]).
bubble1([X],[X]).
bubble1([X1,X2|Xs],[X1|Y]) :-
    X1 =< X2,
    bubble1([X2|Xs],Y).

bubble1([X1,X2|Xs],[X2|Y]) :-
    X1 > X2,
    bubble1([X1|Xs],Y).

msort([X],Z) :- 
    merge([X],[],Z).
msort([X,Y],Z) :-
    merge([X],[Y],Z).
msort(X,Z) :-
    length(X,N),
    N1 is N // 2,
    take(X,N1,X1),
    drop(X,N1,X2),
    msort(X1,Y1),
    msort(X2,Y2),
    merge(Y1,Y2,Z).

take(X,0,[]).
take([X|Xs],N,[X|Y]) :-
    N1 is N - 1,
    take(Xs,N1,Y).

drop(X,0,X).
drop([X|Xs],N,Y) :-
    N1 is N - 1,
    drop(Xs,N1,Y).

merge(X,[],X).
merge([],Y,Y).
merge([X|Xs],[Y|Ys],[X|Z]) :-
    X =< Y,
    merge(Xs,[Y|Ys],Z).
merge([X|Xs],[Y|Ys],[Y|Z]) :-
    X > Y,
    merge([X|Xs],Ys,Z).


% tests code from M.Hiroi's page
qsort([X | Xs], Ys) :-
        partition(Xs, X, Littles, Bigs),
        qsort(Littles, Ls),
        qsort(Bigs, Bs),
        append(Ls, [X | Bs], Ys).
qsort([], []).


partition([X | Xs], Y, [X | Ls], Bs) :-
        X =< Y, partition(Xs, Y, Ls, Bs).
partition([X | Xs], Y, Ls, [X | Bs]) :-
        X > Y, partition(Xs, Y, Ls, Bs).
partition([], Y, [], []).

quick1(Xs, Ys) :- quick_sub(Xs, [Ys, []]).
quick_sub([X | Xs], [Ys, Zs]) :-
        partition(Xs, X, Littles, Bigs),
        quick_sub(Littles, [Ys, [X | Ys1]]),
        quick_sub(Bigs, [Ys1, Zs]).
quick_sub([], [Xs, Xs]).
