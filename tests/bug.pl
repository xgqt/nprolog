foo([X|Y]) :- write(X),write(Y).

max_list([N],N) :- write(N).
max_list([L|Ls],L) :-
    max_list(Ls,Y),
    L >= Y.
max_list([L|Ls],Y) :-
    max_list(Ls,Y),
    L < Y.


fib(0,0).
fib(1,1).
fib(N,A) :-
    N1 is N-1,N2 is N-2,
    fib(N1,A1),fib(N2,A2),
    A is A1+A2,
    asserta(fib(N,A)).

ack(0,N,A) :- 
    A is N+1,asserta(ack(0,N,A)).
ack(M,0,A) :- 
    M1 is M-1,ack(M1,1,A),
    asserta(ack(M1,1,A)),
    asserta(ack(M,0,A)).
ack(M,N,A) :- 
    M1 is M-1,N1 is N-1,
    ack(M,N1,A1), ack(M1,A1,A),
    asserta(ack(M,N1,A1)),
    asserta(ack(M1,A1,A)).

a([1,2]).

test(_文字) :- write(_文字).