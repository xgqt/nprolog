verify(X) :- 
	ifthenelse(
		call(X), 
		true, 
		(write('wrong '), write(X), nl)
	).

alltest :-
    test(Test),
    fail.
alltest.

test(atmark) :-
    verify(3 @> 2.1),
    verify([1,2,3] @>= [1,2,3]),
    verify([2,2,3] @> [1,2,3]).

test(atom) :-
    verify(atom(a)),
    verify(not(atom(1))),
    verify(not(atom(1.1))),
    verify(atom('a*b')),
    verify(atom(動物)).

test(atomic) :-
    verify(atomic(1)),
    verify(atomic(abc)),
    verify(atomic(1.0)).

test(integer) :-
    verify(integer(1)),
    verify(integer(10000000000)),
    verify(integer(-1)),
    verify(integer(-10000000001)).

test(float) :-
    verify(float(1.0)),
    verify(float(1.0e10)),
    verify(not(float(1))).

test(arithmetic) :-
    verify(2 is 1+1),
    verify(1.2 is 0.7+0.5),
    verify(2==2),
    verify(2\=3),
    verify(2\=0.3),
    verify(2>1),
    verify(3.2>3),
    verify(2>=1),
    verify(1<2),
    verify(1=<1).

test(unify) :-
    verify(c(Z) = c(c(z))),
    verify(Z == c(z)),

    verify(a(b,C) = a(B,c)),
    verify(C == c),
    verify(B == b),

    verify([E1,E2,E3] = [a,b,c]),
    verify(E1 == a),
    verify(E2 == b),
    verify(E3 == c),

    verify(not(a(a,b) = b(a,b))),

    verify(a(a,A1) = a(A1,a)),
    verify(A1 == a),

    verify(not(a(a,B1) = a(B1,b))).

test(list_difference) :-
    L = [a|T]-T, T = [], L = L1-[], 
    verify(L1 == [a]).

test(list_difference) :-
    L = T-T, L1 = [a,b|T], T = [c,d],
    verify(L1 == [a,b,c,d]).

test(univ) :-
    X =.. [sin,3],
    verify(X == sin(3)).


:- alltest,write('All tests are done\n').