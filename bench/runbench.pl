run :-
    consult('bench/derive.o'),
    write('derive'),nl,
    measure(test),
    consult('bench/devide10.o'),
    write('devide10'),nl,
    measure(test),
    consult('bench/log10.o'),
    write('log10'),nl,
    measure(test),
    consult('bench/nreverse.o'),
    write('nreverse'),nl,
    measure(test),
    consult('bench/ops8.o'),
    write('ops8'),nl,
    measure(test),
    consult('bench/qsort.o'),
    write('qsorte'),nl,
    measure(test),
    consult('bench/serialize.o'),
    write('serialize'),nl,
    measure(test),
    consult('bench/times10.o'),
    write('times10'),nl,
    measure(test).

