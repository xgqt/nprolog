/* template. generate c file as following

#include "jump.h"
int b_<name>(int arglist, int rest, int th);
int b_<name>(int arglist, int rest, int th){
int arg1,arg2,arg4,varX,varY,varZ,...,save1,save2,goal,cont;
save2 = Jget_sp(th);
if(n == 2){
    arg1 = Jnth(arglist,1);
    arg2 = Jnth(arglist,2);
  
    % first clause
    varX = Jmakevariant(th);
    varZ = Jmakevariant(th);
    varY = Jmakevariant(th);
    save1 = Jget_wp(th);
    if(Junify(term1,arg1,th) == YES && Junify_var(term2,arg2,th) == YES){
        body =Jwcons(119,Jwcons(varX,Jwcons(varY,NIL),th),th);
        if(Jexec_all(Jaddtail_body(rest,body,th),save2,th) == YES)
            return(YES);
    }
    Junbind(save2,th);
    Jset_wp(save1,th);}

    % second clause
    varX1 = Jmakevariant(th);
    varY1 = Jmakevariant(th);
    varZ1 = Jmakevariant(th);
    ...
    save1 = Jget_wp(th);
    if(Junify(term1,arg1,th) == YES && Junify_const(term1,arg2,th) == YES){
        body = Jwlist3(Jmakeope(","),Jwcons(173,Jwc ...., th)),th);
        if(Jexec_all(Jaddtail_body(rest,body,th),save2,th) == YES)
            return(YES);
    }
    Junbind(save2,th);
    Jset_wp(save1,th);

    Jerrorcomp(makeint(AIRTY_ERR),Jmakecomp(<name>),arglist);
    return(NO);
}

% initialize predicate
void init_tpredicate(void){(deftpred)("<name>",b_<name>);
}
% set execution code
void init_declare(void){
  ...execution 
}


unification 
Junify(head,arg,th)  all-round
Junify_const(head,arg,th)  for constant term
Junify_var(head,arg,th)    for variable term
Junify_nil(arg,th)    for [] check.
*/

% optimize flag
jump_optimize(on).
jump_typed_optimize(off).

optimize(X) :-
    abolish(jump_typed_optimize/1),
    assert(jump_typed_optimize(X)).

% main
compile_file(X) :-
    jump_pass1(X),
    jump_pass2(X),
    jump_invoke_gcc(X).

% for debug not remove C code.
compile_file1(X) :-
    jump_pass1(X),
    jump_pass2(X),
    jump_invoke_gcc_not_remove(X).


% genrate only c code 
compile_file2(X) :-
    jump_pass1(X),
    jump_pass2(X).

% generate object from c code
compile_file3(X) :-
    jump_invoke_gcc_not_remove(X).
 

/*
for tail recursive optimize code 
now ignore
*/
jump_pass1(X) :-
	write(user_output,'pass1'),
    nl(user_output),
    abolish(jump_pred_data/2),
    assert(jump_pred_data(jump_dummy,-1)),
    reconsult(X),
    jump_pass1_analize.

jump_pass1_analize :-
    n_reconsult_predicate(P),
    jump_analize(P),
    fail.
jump_pass1_analize.

/*
pass2 generate each clause or predicate code.
and write to <filename>.c
when all code is generated, close file and abolish optimizable/1
*/
jump_pass2(X) :-
	write(user_output,'pass2'),
    nl(user_output),
	n_filename(X,F),
    atom_concat(F,'.c',Cfile),
	tell(Cfile),
	write('#include "jump.h"'),nl,
    jump_gen_c_pred,
    jump_gen_c_exec,
    abolish(jump_pred_data/2),
    n_reconsult_abolish,
    told.

/*
when OS is Linux
system builtin predicate invoke GCC
gcc -O3 -w -shared -fPIC -o <filenam>.c <filename>.o <option>
*/
jump_invoke_gcc(X) :-
	write(user_output,'invoke GCC'),
    nl(user_output),
	n_filename(X,F),
    atom_concat(F,'.c ',Cfile),
    atom_concat(F,'.o ',Ofile),
    atom_concat(Ofile,Cfile,Files),
    atom_concat('gcc -O3 -w -shared -fPIC -I$HOME/nprolog -o ',Files,Gen),
    shell(Gen),
    atom_concat('rm ',Cfile,Del),
    shell(Del).

jump_invoke_gcc_not_remove(X) :-
	write(user_output,'invoke GCC'),
    nl(user_output),
	n_filename(X,F),
    atom_concat(F,'.c ',Cfile),
    atom_concat(F,'.o ',Ofile),
    atom_concat(Ofile,Cfile,Files),
    atom_concat('gcc -O3 -w -shared -fPIC -I$HOME/nprolog -o ',Files,Gen),
    shell(Gen).


/*
generate C code for predicate or clause.
They are provided by list.
e.g. [foo,bar,boo]
generate each predicate to make compiled pred
*/



% normal predicate
jump_gen_c_pred :-
    jump_gen_pred,
    jump_gen_c_def.

% generate all predicate code
jump_gen_pred :-
    n_reconsult_predicate(P),
    jump_gen_pred1(P),
    fail.
jump_gen_pred.

jump_gen_pred1(P) :-
    jump_pred_data(P,type1),
    jump_gen_tail_pred(P),!.
jump_gen_pred1(P) :-
    jump_pred_data(P,type2),
    jump_gen_tail_pred(P),!.    
jump_gen_pred1(P) :-
    not(jump_pred_data(P,type1)),
    jump_gen_a_pred(P),!.

% define compiled predicate
jump_gen_c_def :-
	write('void init_tpredicate(void){'),
    jump_gen_c_def1,
    write('}'),nl.

jump_gen_c_def1 :-
    n_reconsult_predicate(P),
	jump_gen_def(P),
    fail.
jump_gen_c_def1.


% generate deftpred for normal predicate
jump_gen_def(P) :-
    n_defined_predicate(P),
	write('(deftpred)("'),
    write(P),
    write('",'),
    write('b_'),
    n_atom_convert(P,P1),
    write(P1),
    write(');'),
    nl,!.

% generate deftinfix for user op
jump_gen_def(P) :-
    n_defined_userop(P),
	write('(deftinfix)("'),
    write(P),
    write('",'),
    write('b_'),
    n_atom_convert(P,P1),
    write(P1),
    write(','),
    current_op(W,S,P),
    jump_spec_to_c(S,S1),
    write(W),
    write(','),
    write(S1),
    write(');'),
    nl,!.


jump_spec_to_c(fx,'FX').
jump_spec_to_c(fy,'FY').
jump_spec_to_c(xfx,'XFX').
jump_spec_to_c(xfy,'XFY').
jump_spec_to_c(yfx,'YFX').
jump_spec_to_c(xf,'XF').
jump_spec_to_c(yf,'YF').
jump_spec_to_c(fx_xfx,'FX_XFX').
jump_spec_to_c(fy_xfx,'FY_XFX').
jump_spec_to_c(fx_yfx,'FX_YFX').
jump_spec_to_c(fy_yfx,'FY_YFX').
jump_spec_to_c(fx_xf,'FX_XF').
jump_spec_to_c(fx_yf,'FX_YF').
jump_spec_to_c(fy_xf,'FY_XF').
jump_spec_to_c(fy_yf,'FY_YF').


/*
last C code to make direct execute
void init_declare(void){
    execute code...
}
*/
jump_gen_c_exec :-
	write('void init_declare(void){'),
    jump_gen_exec,
    write('}').

/*
parts for gen_predicate
C type declare.
int_b_foo(int arglist, int rest);
*/
jump_gen_type_declare(P) :-
	write('int b_'),
    n_atom_convert(P,P1),
    write(P1),
    write('(int arglist, int rest, int th);'),
    nl.
/*
C variable declare.
generate following code
int(int arg1,arg2,...,argN){
int arg1,arg2 ... argN,body,save1,save2;

*/
jump_gen_var_declare(P) :-
    write('int '),
    n_arity_count(P,L),
    jump_max_list(L,E),
    jump_gen_var_declare1(1,E),
    n_generate_all_variable(P,V),
    jump_gen_all_var(V),
    write('n,body,save1,save2,goal,cont,res;'),nl,!.

jump_max_list([N],N).
jump_max_list([X|Xs],X) :-
    jump_max_list(Xs,Y),
    X >= Y.
jump_max_list([X|Xs],Y) :-
    jump_max_list(Xs,Y),
    X < Y.

% arg1,arg2,...argN
jump_gen_var_declare1(S,E) :-
	S > E.
jump_gen_var_declare1(S,E) :-
	write(arg),
    write(S),
    write(','),
    S1 is S+1,
    jump_gen_var_declare1(S1,E).


/*
generate predicate for not tail recursive
int b_<name>(int arglist, int rest){
int varX,varY,...
save2 = Jget_sp(th);
if(n == N){
    ...main code...
}
return(NO);
}
*/
jump_gen_a_pred(P) :-
	atom_concat('compiling ',P,M),
    write(user_output,M),
    nl(user_output),
    jump_gen_type_declare(P),
	write('int b_'),
    n_atom_convert(P,P1),
    write(P1),
    write('(int arglist, int rest, int th){'),nl,
    jump_gen_var_declare(P),
    write('save2 = Jget_sp(th);'),nl,
    write('n = Jlength(arglist);'),nl,
    n_arity_count(P,L),
    jump_gen_a_pred1(P,L),
    write('}'),nl.

% pred1,pred2,...,predN
jump_gen_a_pred1(P,[]) :-
    nl,
    write('Jerrorcomp(Jmakeint(ARITY_ERR),Jmakecomp("'),
    write(P),
    write('"),arglist);'),nl,
	write('return(NO);').

jump_gen_a_pred1(P,[L|Ls]) :-
	jump_gen_a_pred2(P,L),
    jump_gen_a_pred1(P,Ls).

% if(n == N){...}
jump_gen_a_pred2(P,N) :-
	write('if(n == '),
    write(N),
    write('){\n'),
    jump_gen_a_pred3(P,N),
    write('return(NO);}'),!.

% select all clauses that arity is N
jump_gen_a_pred3(P,N) :-
    jump_gen_var_assign(1,N),
	n_clause_with_arity(P,N,C),
    jump_gen_a_pred4(C).

% arg1 = Jnth(arglist,1);
% arg2 = Jnth(arglist,2);
% argn = Jnth(artglist,n);
jump_gen_var_assign(S,E) :-
	S > E.
jump_gen_var_assign(S,E) :-
	write(arg),
    write(S),
    write(' = Jnth(arglist,'),
    write(S),
    write(');\n'),
    S1 is S+1,
    jump_gen_var_assign(S1,E).


% generate each clause in CPS
jump_gen_a_pred4([]).
jump_gen_a_pred4([C|Cs]) :-
	n_variable_convert(C,X),
    n_generate_variable(X,V),
    jump_gen_var(V),
    jump_gen_a_pred5(X),
    jump_gen_a_pred4(Cs).


/*
save1 = Jget_wp(th);
save2 = jget_sp(th);
if( )... head
{body = }
...
*/


/*
   
*/
% clause
jump_gen_a_pred5((Head :- Body)) :-
    write('save1 = Jget_wp(th);'),nl,
	jump_gen_head(Head),
    jump_gen_body(Body,0).

% predicate with no arity
jump_gen_a_pred5(P) :-
	n_property(P,predicate),
    functor(P,_,0),
    write('return(Jexec_all(rest,Jget_sp(th),th));'),nl.

% predicate
jump_gen_a_pred5(P) :-
	n_property(P,predicate),
    write('save1 = Jget_wp(th);'),nl,
	jump_gen_head(P),
    write('if(Jexec_all(rest,Jget_sp(th),th) == YES) return(YES);'),nl,
    write('Junbind(save2,th);'),nl,
    write('Jset_wp(save1,th);'),nl.

% user ope
jump_gen_a_pred5(P) :-
	n_property(P,userop),
    write('save1 = Jget_wp(th);'),nl,
	jump_gen_head(P),
    write('if(Jexec_all(rest,Jget_sp(th),th) == YES) return(YES);'),nl,
    write('Junbind(save2,th);'),nl,
    write('Jset_wp(save1,th);'),nl.



% varA,varB,...
jump_gen_all_var([]).
jump_gen_all_var([L|Ls]) :-
    n_atom_convert(L,L1),
	write(L1),
    write(','),
    jump_gen_all_var(Ls).

% varA = Jmakevariant(th), varB = Jmakevariant(th);
jump_gen_var([]).
jump_gen_var([L|Ls]) :-
    n_atom_convert(L,L1),
    write(L1),
    write(' = Jmakevariant(th);'),nl,
    jump_gen_var(Ls).



/*
body for compiler
foo(X),bar(X),boo(X).

if(unify(....)){
    body = ...;
    if(Jexec_all(body,Jget_sp(th),th) == YES)
        return(YES)};

Junbind(save2,th);
Jset_wp(save1,th);


*/


% disjunction
jump_gen_body(((X1;X2);Y),N) :-
    write('{dp['),write(N),write(']=Jget_sp(th);'),nl,
    N1 is N+1,
    jump_gen_body(X,N1),
    write('Junbind(dp['),write(N),write('],th);'),nl,
    write('body = '),nl,
    jump_gen_body1(Y,N),
    write(';'),nl,
    write('if(Jexec_all(Jaddtail_body(rest,body,th),Jget_sp(th),th) == YES)'),nl,
    write('return(YES);'),nl,
    write('Junbind(dp['),write(N),write('],th);}'),nl.


jump_gen_body((X;(Y1;Y2)),N) :-
    write('{dp['),write(N),write(']=Jget_sp(th);'),nl,
    write('body = '),nl,
    jump_gen_body1(X,N),
    write(';'),nl,
    write('if(Jexec_all(Jaddtail_body(rest,body,th),Jget_sp(th),th) == YES)'),nl,
    write('return(YES);'),nl,
    write('Junbind(dp['),write(N),write('],th);'),nl,
    N1 is N+1,
    jump_gen_body((Y1;Y2),N1),
    write('Junbind(dp['),write(N),write('],th);}'),nl.


jump_gen_body((X;Y),N) :-
    n_has_cut(X),
    write('{dp['),write(N),write(']=Jget_sp(th);'),nl,
    jump_gen_body(X,N),
    write('Junbind(dp['),write(N),write('],th);'),nl,
    write('body = '),nl,
    jump_gen_body1(Y,N),
    write(';'),nl,
    write('if(Jexec_all(Jaddtail_body(rest,body,th),Jget_sp(th),th) == YES)'),nl,
    write('return(YES);'),nl,
    write('Junbind(dp['),write(N),write('],th);}'),nl.

jump_gen_body((X;Y),N) :-
    write('{dp['),write(N),write(']=Jget_sp(th);'),nl,
    write('body = '),nl,
    jump_gen_body1(X,N),
    write(';'),nl,
    write('if(Jexec_all(Jaddtail_body(rest,body,th),Jget_sp(th),th) == YES)'),nl,
    write('return(YES);'),nl,
    write('Junbind(dp['),write(N),write('],th);'),nl,
    write('body = '),nl,
    jump_gen_body1(Y,N),
    write(';'),nl,
    write('if(Jexec_all(Jaddtail_body(rest,body,th),Jget_sp(th),th) == YES)'),nl,
    write('return(YES);'),nl,
    write('Junbind(dp['),write(N),write('],th);}'),nl.


% has cut
jump_gen_body(X,N) :-
    n_has_cut(X),
    n_before_cut(X,X1),
    n_after_cut(X,X2),
    not(n_has_cut(X2)),
    write('{body = '),
    jump_gen_body1(X1,N),
    write(';'),nl,
    write('if((res=Jexec_all(body,Jget_sp(th),th)) == YES)'),nl,
    jump_gen_after_body(X2,N),
    write('}'),nl,
    write('Junbind(save2,th);'),nl,
    write('Jset_wp(save1,th);'),nl.

% nested has cut
jump_gen_body(X,N) :-
    n_has_cut(X),
    n_before_cut(X,X1),
    n_after_cut(X,X2),
    n_has_cut(X2),
    write('{body = '),
    jump_gen_body1(X1,N),
    write(';'),nl,
    write('if(Jexec_all(body,Jget_sp(th),th) == YES)'),nl,
    jump_gen_body(X2,N),
    write('}'),nl,
    write('Junbind(save2,th);'),nl,
    write('Jset_wp(save1,th);'),nl.
    
    
% conjunction 
jump_gen_body(X,N) :-
    write('{body = '),
    jump_gen_body1(X,N),
    write(';'),nl,
    write('if((res=Jexec_all(Jaddtail_body(rest,body,th),Jget_sp(th),th)) == YES)'),nl,
    write('return(YES);'),nl,
    write('Junbind(save2,th);'),nl,
    write('Jset_wp(save1,th);}'),nl.
    
jump_gen_after_body(X,N) :-
    write('{body = '),
    jump_gen_body1(X,N),
    write(';'),nl,
    write('if((Jexec_all(Jaddtail_body(rest,body,th),Jget_sp(th),th)) == YES)'),nl,
    write('return(YES);'),nl,
    write('Junbind(save2,th);'),nl,
    write('Jset_wp(save1,th);'),nl,
    write('return(NO);}'),nl.


jump_gen_body1([],N) :-
    write('NIL').

jump_gen_body1((D1;D2),N) :-
	write('Jwlist3(Jmakeope(";"),'),
	jump_gen_body1(D1,N),
    write(','),
    jump_gen_body1(D2,N),
    write(',th)').
jump_gen_body1(((D1;D2),Xs),N) :-
    write('Jwlist3(Jmakeope(","),'),
	write('Jwlist3(Jmakeope(";"),'),
	jump_gen_body1(D1,N),
    write(','),
    jump_gen_body1(D2,N),
    write(',th),'),
    jump_gen_body1(Xs,N),
    write(',th)').
    
jump_gen_body1((X,Xs),N) :-
	write('Jwlist3(Jmakeope(","),'),
	jump_gen_a_body(X),
    write(','),
    jump_gen_body1(Xs,N),
    write(',th)').

jump_gen_body1(X,N) :-
	jump_gen_a_body(X).

/*
generate one operation,user,builtin or compiled predicate.
when except of above type, invoke error.
*/
jump_gen_a_body((X;Xs)) :-
	write('Jwlist3(Jmakeope(";"),'),
	jump_gen_a_body(X),
    write(','),
    jump_gen_body1(Xs),
    write(',th)').
% defined predicate will become compiled predicate
jump_gen_a_body(X) :-
    n_defined_predicate(X),
    functor(X,P,0),
    write('Jmakecomp("'),
    write(P),
    write('")').
% defined predicate will become compiled predicate
jump_gen_a_body(X) :-
    n_defined_predicate(X),
    X =.. [P|L],
    write('Jwcons(Jmakecomp("'),
    write(P),
    write('"),'),
    jump_gen_argument(L),
    write(',th)').
jump_gen_a_body(X) :-
    n_property(X,predicate),
    X =.. [P|L],
    write('Jwcons(Jmakepred("'),
    write(P),
    write('"),'),
    jump_gen_argument(L),
    write(',th)').
% atom builtin e.g. nl fail
jump_gen_a_body(X) :-
    n_property(X,builtin),
    functor(X,P,0),
    n_findatom(P,builtin,A),
    write(A).
jump_gen_a_body(X) :-
    n_property(X,builtin),
    X =.. [P|L],
    n_findatom(P,builtin,A),
    write('Jwcons('),
    write(A),
    write(','),
    jump_gen_argument(L),
    write(',th)').
jump_gen_a_body(X) :-
    n_property(X,operation),
    gen_body1(X).
jump_gen_a_body(X) :-
    n_property(X,compiled),
    X =.. [P|L],
    write('Jwcons(Jmakecomp("'),
    write(P),
    write('"),'),
    jump_gen_argument(L),
    write(',th)').
jump_gen_a_body(X) :-
    n_property(X,userop),
    functor(X,P,0),
    write('Jmakeuser("'),
    write(P),
    write('")').
jump_gen_a_body(X) :-
    n_defined_userop(X),
    X =.. [P|L],
    write('Jwcons(Jmakecomp("'),
    write(P),
    write('"),'),
    jump_gen_argument(L),
    write(',th)').
jump_gen_a_body(X) :-
    n_property(X,userop),
    X =.. [P|L],
    write('Jwcons(Jmakeuser("'),
    write(P),
    write('"),'),
    jump_gen_argument(L),
    write(',th)').
jump_gen_a_body(X) :-
    atom(X),
	write('Jmakepred("'),
    write(X),
    write('")').
jump_gen_a_body(X) :-
    jump_invoke_error('illegal body ',X).


/*
generate_unify of head
e.g.  foo(X) -> if(Junify(arg1,varX,th) == YES)
anoymous variable generate 1 as true.
e.g   foo(_) -> if(1)
*/

jump_gen_head(X) :-
    functor(X,_,0).
jump_gen_head(X) :-
    X =.. [_|Y],
    write('if('),
    jump_gen_head1(Y,1),
    write(')\n').

jump_gen_head1([],_) :-
    write(1).

jump_gen_head1([[]|Xs],N) :-
    write('Junify_nil('),
    write('arg'),
    write(N),
    write(','),
    write(th),
    write(') == YES && '),
    N1 is N + 1,
    jump_gen_head1(Xs,N1).

jump_gen_head1([X|Xs],N) :-
    n_compiler_anoymous(X),
    N1 is N + 1,
    jump_gen_head1(Xs,N1).  

jump_gen_head1([X|Xs],N) :-
    n_compiler_variable(X),
    write('Junify_var('),
    jump_gen_a_argument(X),
    write(',arg'),
    write(N),
    write(','),
    write(th),
    write(') == YES && '),
    N1 is N + 1,
    jump_gen_head1(Xs,N1). 

jump_gen_head1([X|Xs],N) :-
    atomic(X),
    write('Junify_const('),
    jump_gen_a_argument(X),
    write(',arg'),
    write(N),
    write(','),
    write(th),
    write(') == YES && '),
    N1 is N + 1,
    jump_gen_head1(Xs,N1). 

jump_gen_head1([X|Xs],N) :-
    write('Junify('),
    jump_gen_a_argument(X),
    write(',arg'),
    write(N),
    write(','),
    write(th),
    write(') == YES && '),
    N1 is N + 1,
    jump_gen_head1(Xs,N1).


/*
generate evauation code
e.g.  X is 1+2.  X == 3*4.
*/
jump_eval_form([]) :-
	write('NIL').
jump_eval_form([X]) :-
	write('Jmakeconst("'),
    write(X),
    write('")').
jump_eval_form(pi) :-
	write('Jmakestrflt("3.14159265358979")').
jump_eval_form(random) :-
	write('Jrandom()').    
jump_eval_form(X) :-
	n_bignum(X),
    write('Jmakebig("'),
    write(X),
    write('")').
jump_eval_form(X) :-
	n_longnum(X),
    write('Jmakestrlong("'),
    write(X),
    write('")').
jump_eval_form(X) :-
	integer(X),
    write('Jmakeint('),
    write(X),
    write(')').
jump_eval_form(X) :-
	float(X),
    write('Jmakestrflt("'),
    write(X),
    write('")').
jump_eval_form(X) :-
	atom(X),
    n_compiler_variable(X),
    n_atom_convert(X,X1),
    write('Jderef('),
    write(X1),
    write(','),
    write(th),
    write(')').
jump_eval_form(X) :-
	atom(X),
    write('Jmakeconst("'),
    write(X),
    write('")').
jump_eval_form(X) :-
    list(X),
    jump_gen_a_argument(X).
jump_eval_form(X + Y) :-
	write('Jplus('),
    jump_eval_form(X),
    write(','),
    jump_eval_form(Y),
    write(',th)').
jump_eval_form(X - Y) :-
	write('Jminus('),
    jump_eval_form(X),
    write(','),
    jump_eval_form(Y),
    write(',th)').
jump_eval_form(X * Y) :-
	write('Jmult('),
    jump_eval_form(X),
    write(','),
    jump_eval_form(Y),
    write(',th)').
jump_eval_form(X / Y) :-
	write('Jdivide('),
    jump_eval_form(X),
    write(','),
    jump_eval_form(Y),
    write(',th)').
jump_eval_form(X//Y) :-
	write('Jdiv('),
    jump_eval_form(X),
    write(','),
    jump_eval_form(Y),
    write(',th)').
jump_eval_form(X ^ Y) :-
	write('Jexpt('),
    jump_eval_form(X),
    write(','),
    jump_eval_form(Y),
    write(',th)').
jump_eval_form(X mod Y) :-
	write('Jmod('),
    jump_eval_form(X),
    write(','),
    jump_eval_form(Y),
    write(',th)').
jump_eval_form(sin(X)) :-
	write('Jsin('),
    jump_eval_form(X),
    write(',th)').
jump_eval_form(asin(X)) :-
	write('Jasin('),
    jump_eval_form(X),
    write(',th)').
jump_eval_form(cos(X)) :-
	write('Jcos('),
    jump_eval_form(X),
    write(',th)').
jump_eval_form(acos(X)) :-
	write('Jacos('),
    jump_eval_form(X),
    write(',th)').
jump_eval_form(tan(X)) :-
	write('Jtan('),
    jump_eval_form(X),
    write(',th)').
jump_eval_form(atan(X)) :-
	write('Jatan('),
    jump_eval_form(X),
    write(',th)').
jump_eval_form(exp(X)) :-
	write('Jexp('),
    jump_eval_form(X),
    write(',th)').
jump_eval_form(log(X)) :-
	write('Jlog('),
    jump_eval_form(X),
    write(',th)').
jump_eval_form(ln(X)) :-
	write('Jln('),
    jump_eval_form(X),
    write(',th)').

jump_eval_form(X << Y) :-
	write('Jleftshift('),
    jump_eval_form(X),
    write(','),
    jump_eval_form(Y),
    write(',th)').
jump_eval_form(X >> Y) :-
	write('Jrightshift('),
    jump_eval_form(X),
    write(','),
    jump_eval_form(Y),
    write(',th)').

jump_eval_form(X /\ Y) :-
	write('Jlogicaland('),
    jump_eval_form(X),
    write(','),
    jump_eval_form(Y),
    write(',th)').
jump_eval_form(X \/ Y) :-
	  write('Jlogicalor('),
    jump_eval_form(X),
    write(','),
    jump_eval_form(Y),
    write(',th)').
jump_eval_form(\ X) :-
	write('Jcomplement('),
    jump_eval_form(X),
    write(',th)').
jump_eval_form(randi(X)) :-
	write('Jrandi('),
    jump_eval_form(X),
    write(',th)').
jump_eval_form(round(X,Y)) :-
	  write('Jround('),
    jump_eval_form(X),
    jump_eval_form(Y),
    write(',th)').


/*
generate arguments for pred ope fun.
arguments are provided by list.
e.g. [3,14,A,foo(2)]
*/
jump_gen_argument([]) :-
    write('NIL').
jump_gen_argument([X|Xs]) :-
	write('Jwcons('),
    jump_gen_a_argument(X),
    write(','),
    jump_gen_argument(Xs),
    write(',th)').
/*
generate one argument
there are all type of prolog object
*/
jump_gen_a_argument([]) :-
	write('NIL').
jump_gen_a_argument(X) :-
	n_compiler_variable(X),
    n_atom_convert(X,X1),
    write(X1).
jump_gen_a_argument(pi) :-
	write('Jmakestrflt("3.14159265358979")').
jump_gen_a_argument(X) :-
	n_bignum(X),
    write('Jmakebig("'),
    write(X),
    write('")').
jump_gen_a_argument(X) :-
	n_longnum(X),
    write('Jmakestrlong("'),
    write(X),
    write('")').
jump_gen_a_argument(X) :-
	integer(X),
    write('Jmakeint('),
    write(X),
    write(')').
jump_gen_a_argument(X) :-
	float(X),
    write('Jmakestrflt("'),
    write(X),
    write('")').
jump_gen_a_argument(X) :-
	string(X),
    write('Jmakestr("'),
    write(X),
    write('")').
jump_gen_a_argument(X) :-
    n_defined_predicate(X),
    functor(X,Y,0),
    write('Jmakecomp("'),
    write(Y),
    write('")').
jump_gen_a_argument(X) :-
    n_defined_predicate(X),
    X =.. [Y|Z],
    write('Jwcons(Jmakecomp("'),
    write(Y),
    write('"),'),
    jump_gen_argument(Z),
    write(',th)').
jump_gen_a_argument(X) :-
    n_property(X,predicate),
    X =.. [Y|Z],
    write('Jwcons(Jmakepred("'),
    write(Y),
    write('"),'),
    jump_gen_argument(Z),
    write(',th)').
jump_gen_a_argument(X) :-
    n_property(X,builtin),
    functor(X,Y,0),
    n_findatom(Y,builtin,A),
    write(A).
jump_gen_a_argument(X) :-
    n_property(X,builtin),
    X =.. [Y|Z],
    n_findatom(Y,builtin,A),
	write('Jwcons('),
    write(A),
    write(','),
    jump_gen_argument(Z),
    write(',th)').
jump_gen_a_argument(X) :-
    n_property(X,compiled),
    functor(X,Y,0),
    n_findatom(Y,compiled,A),
    write(A).
jump_gen_a_argument(X) :-
    n_property(X,compiled),
    X =.. [Y|Z],
    n_findatom(Y,compiled,A),
    write('Jwcons('),
    write(A),
    write(','),
    jump_gen_argument(Z),
    write(',th)').
jump_gen_a_argument(X) :-
    n_property(X,operation),
    functor(X,Y,0),
    n_findatom(Y,operator,A),
    write(A).
jump_gen_a_argument(X) :-
    n_property(X,operation),
    X =.. [Y|Z],
    n_findatom(Y,operator,A),
	write('Jwcons('),
    write(A),
    write(','),
    jump_gen_argument(Z),
    write(',th)').
%predicate indicator  e.g. foo/1
jump_gen_a_argument(A/B) :-
    atom(A),
    integer(B),
    write('Jwlist3(Jmakefun("/"),Jmakepred("'),
    write(A),
    write('"),'),
    jump_gen_a_argument(B),
    write(',th)').
jump_gen_a_argument(X) :-
    n_property(X,function),
    functor(X,F,0),
    write('Jmakefun("'),
    write(F),
    write('")').
jump_gen_a_argument(X) :-
    n_property(X,function),
    X =.. [F|Z],
	write('Jwcons(Jmakefun("'),
    write(F),
    write('"),'),
    jump_gen_argument(Z),
    write(',th)').
jump_gen_a_argument(X) :-
    n_property(X,userop),
    functor(X,Y,0),
    write('Jmakeuser("'),
    write(X),
    write('")').
jump_gen_a_argument(X) :-
    n_property(X,userop),
    X =.. [Y|Z],
	write('Jwcons(Jmakeuser("'),
    write(Y),
    write('"),'),
    jump_gen_argument(Z),
    write(',th)').
jump_gen_a_argument(X) :-
	atom(X),
    write('Jmakeconst("'),
    write(X),
    write('")').
jump_gen_a_argument(X) :-
	list(X),
    jump_gen_argument_list(X).
jump_gen_a_argument(X) :-
    jump_invoke_error('illegal argument ',X).

jump_gen_argument_list([X|Xs]) :-
	write('Jwlistcons('),
    jump_gen_a_argument(X),
    write(','),
    jump_gen_a_argument(Xs),
    write(','),
    write(th),
    write(')').

/*
invoke error
display error message and error code.
and close output file, finaly abort to REPL
*/
jump_invoke_error(Message,Code) :-
	write(user_output,Message),
    write(user_output,Code),nl(user_output),
    told,
    abort.

/*
e.g. :- op(...)
generate execution 
*/
jump_gen_exec :-
    n_get_execute(X),
    write('int body,th; th=0;'),nl,
    jump_gen_exec1(X).

jump_gen_exec1([]).
jump_gen_exec1([L|Ls]) :-
    jump_gen_exec2(L),
    nl,
    jump_gen_exec1(Ls).


jump_gen_exec2(X) :-
    write('body = '),
    jump_gen_body1(X,0),
    write(';'),nl,
    write('Jexec_all(body,Jget_sp(th),th);'),!.

/*
optimizer for deterministic predicate

deterministic e.g.

% type1 tail_recursive and body is unidirectory

bar(0).
bar(N) :- N1 is N-1,bar(N1).

% type2,3... if find new optimization, use this typeN

optimizable <=> deterministic

template e.g. nodiag/3 in 9queens problem
nodiag([], _, _).
nodiag([N|L], B, D) :-
	D =\= N - B,
	D =\= B - N,
	D1 is D + 1,
	nodiag(L, B, D1).

int b_nodiag(int nest, int n);
int b_nodiag(int nest, int n){
int n,arg1,arg2,arg3,varD1,varN,varL,varB,varD;
if(n == 3){
    loop:
    head = Jwlist3(NIL,makeconst("_"),makeconst("_"));
    if(Jcar(arglist) == NIL){if(Junify(arglist,head,th)==YES) 
                                  return(Jexec_all(rest,Jget_sp(th),th));
                             else 
                                  return(NO);}

    varN = Jcar(car(arglist));
    varL = Jcdr(car(arglist));
    varB = cadr(arglist);
    varD = caddr(arglist);
    if(!(Jnot_numeqp(varD),Jminus(varN,varB)))
        return(NO);
    if(!(Jnot_numeqp(varD),Jminus(varB),varN))))
        return(NO);
    varD1 = Jplus(varD,Jmakeint(1));
    arglist = Jwlist3(varL,varB,varD1);
    goto loop;
    }
    return(NO);
}
*/

%------------------------------------
%for tail recursive optimization
jump_gen_tail_pred(P) :-
    atom_concat('compiling tail ',P,M),
    write(user_output,M),nl(user_output),
    jump_gen_type_declare(P),
    write('int b_'),
    n_atom_convert(P,P1),
    write(P1),
    write('(int arglist, int rest, int th){'),
    nl,
    jump_gen_tail_var_declare(P),
    n_arity_count(P,[N]),
    jump_gen_tail_pred1(P,N),
    write('}'),nl.

% int a,varA,varB...
jump_gen_tail_var_declare(P) :-
    n_arity_count(P,L),
    write('int n,head,'),
    n_generate_all_variable(P,V),
    jump_gen_tail_all_var(V).


% varA,varB,...
jump_gen_tail_all_var([]) :-
    write('dummy;'),nl.
jump_gen_tail_all_var([L]) :-
    write(L),
    write(';'),nl.
jump_gen_tail_all_var([L|Ls]) :-
    write(L),
    write(','),
    jump_gen_tail_all_var(Ls).

% n = Jlength(arglist);
% if(n == N){arg1 = ;  loop: ...}
jump_gen_tail_pred1(P,N) :-
    write('n = Jlength(arglist);'),nl,
    write('if(n == '),
    write(N),
    write('){'),,nl,
    write('loop:'),nl,
    write('Jinc_proof(th);'),nl,
    jump_gen_tail_pred2(P,N),
    write('}'),
    write('return(NO);'),nl.
    


% select clauses that arity is N
jump_gen_tail_pred2(P,N) :-
    n_clause_with_arity(P,N,C),
    jump_gen_tail_pred3(C).

% generate each predicate or clause
jump_gen_tail_pred3([]).
    
jump_gen_tail_pred3([L|Ls]) :-
	n_variable_convert(L,X),
    jump_gen_tail_pred4(X),
    jump_gen_tail_pred3(Ls).

% clause with cut
jump_gen_tail_pred4((Head :- !)) :-
    n_property(Head,predicate),
    jump_gen_tail_head_unify(Head).

% clause
jump_gen_tail_pred4((Head :- Body)) :-
    jump_gen_tail_var(Head),
	jump_gen_tail_head(Head),
    write('{'),
    jump_gen_tail_body(Body,Head),
    write('}').

% predicate
jump_gen_tail_pred4(P) :-
    n_property(P,predicate),
    jump_gen_tail_head_unify(P).

% foo([A|B]) -> varA = car(car(arglist)); varB = cdr(car(arglist));
jump_gen_tail_var(X) :-
    functor(X,_,0).
jump_gen_tail_var(X) :-
    X =.. [_|Y],
    jump_gen_tail_var1(Y,[]).

jump_gen_tail_var1([],L).
% anoymous variable ignore
jump_gen_tail_var1(X,L) :-
    n_compiler_anoymous(X).
% normal variable
jump_gen_tail_var1(X,L) :-
    n_compiler_variable(X),
    n_atom_convert(X,X1),
    write(X1),
    write(' = '),
    jump_gen_tail_head3(X,L),
    write(';'),nl.
% ignore atom and number []
jump_gen_tail_var1(X,L) :-
    atomic(X).

% list
jump_gen_tail_var1([X|Xs],L) :-
    jump_gen_tail_var1(X,[car|L]),
    jump_gen_tail_var1(Xs,[cdr|L]).


% generate head of clause
% foo(1,2) ->
% if(car(arglist) == makeint(1) && cadr(arglist) == makeint(2))
jump_gen_tail_head(X) :-
    functor(X,_,0).
% if element of X is all compiler var -> ignore
jump_gen_tail_head(X) :-
    X =.. [_|Y],
    jump_all_var(Y).
% if element of X include constant
jump_gen_tail_head(X) :-
    X =.. [_|Y],
    write('if('),
    jump_gen_tail_head2(Y,[]),
    write(')').

%  varA = makevariant(th);
%  head = wlist1(varA);
%  if(o && o && ... &1) return(Junify(arglist,head,th));
jump_gen_tail_head_unify(Pred) :-
    Pred =.. [_|Args],
    n_generate_variable(Args,V),
    jump_gen_tail_head_unify1(V),
    write('head = '),
    jump_gen_argument(Args),
    write(';'),nl,
    jump_gen_tail_head_unify2(Args).

% varA = Jmakevariant(th); varB = Jmakevariant(th); ...
jump_gen_tail_head_unify1([]).
jump_gen_tail_head_unify1([X|Xs]) :-
    write(X),
    write(' = Jmakevariant(th);'),nl,
    jump_gen_tail_head_unify1(Xs).

% if( && &&) return(Junify(arglist,head,th));
jump_gen_tail_head_unify2(X) :-
    write('if('),
    jump_gen_tail_head2(X,[]),
    write('){if(Junify(arglist,head,th)==YES) return(Jexec_all(rest,Jget_sp(th),th)); else return(NO);}'),
    nl.
    
% unify head
% generate if(... && ... && 1) for constant value in head
% NIL []
jump_gen_tail_head2([],L) :-
    jump_gen_tail_head3(X,L),
    write(' == NIL && ').

% ignore anoymous
jump_gen_tail_head2(X,L) :-
    n_compiler_anoymous(X).
% ignore variable
jump_gen_tail_head2(X,L) :-
    n_compiler_variable(X).
% integer
jump_gen_tail_head2(X,L) :-
    integer(X),
    write('Jnumeqp(Jmakeint('),
    write(X),
    write('),'),
    jump_gen_tail_head3(X,L),
    write(') && '),nl.
% atom
jump_gen_tail_head2(X,L) :-
    atom(X),
    write('Jmakeconst("'),
    write(X),
    write('") == '),
    jump_gen_tail_head3(X,L),
    write(' && '),nl.
% float number
jump_gen_tail_head2(X,L) :-
    float(X),
    write('Jnumeqp(Jmakestrflt("'),
    write(X),
    write('"),'),
    jump_gen_tail_head3(X,L),
    write(') && '),nl.

% last element
jump_gen_tail_head2([X],L) :-
    jump_gen_tail_head2(X,[car|L]),
    write(1).

jump_gen_tail_head2([X|Xs],L) :-
    jump_gen_tail_head2(X,[car|L]),
    jump_gen_tail_head2(Xs,[cdr|L]).


% write L=[car,cdr] -> Jcar(Jcdr(arglist))
jump_gen_tail_head3(X,[]) :-
    write('arglist').
jump_gen_tail_head3(X,[L|Ls]) :-
    write('J'),
    write(L),
    write('('),
    jump_gen_tail_head3(X,Ls),
    write(')').

%if all elements are compiler_variable -> true
jump_all_var(X) :-
    member([],X),!,fail.
jump_all_var(X) :-
    jump_all_var1(X).
jump_all_var1([]).
jump_all_var1(X) :-
    n_compiler_variable(X).
jump_all_var1([X|Xs]) :-
    jump_all_var1(X),
    jump_all_var1(Xs).

%generate body that has tail call
jump_gen_tail_body(!,Head).
jump_gen_tail_body((X,Xs),Head) :-
    jump_gen_tail_a_body(X,Head),
    jump_gen_tail_body(Xs,Head).
jump_gen_tail_body((!,Xs),Head) :-
    jump_gen_tail_body(Xs,Head).  
jump_gen_tail_body(X,Head) :-
    jump_gen_tail_a_body(X,Head).

jump_gen_tail_a_body(X is Y,Head) :-
    write(X),
    write(' = '),
    jump_eval_form(Y),
    write(';'),nl.

jump_gen_tail_a_body(X = Y,Head) :-
    write('if(Junify('),
    jump_gen_a_argument(X),
    write(','),
    jump_gen_a_argument(Y),
    write(','),
    write(th),
    write(')==NO) return(NO);').

jump_gen_tail_a_body(X =:= Y,Head) :-
    write('if(!Jnumeqp('),
    jump_eval_form(X),
    write(','),
    jump_eval_form(Y),
    write(')) return(NO);'),nl.

jump_gen_tail_a_body(X =\= Y,Head) :-
    write('if(!Jnot_numeqp('),
    jump_eval_form(X),
    write(','),
    jump_eval_form(Y),
    write(')) return(NO);'),nl.

jump_gen_tail_a_body(X < Y,Head) :-
    write('if(!Jsmallerp('),
    jump_eval_form(X),
    write(','),
    jump_eval_form(Y),
    write(')) return(NO);'),nl.

jump_gen_tail_a_body(X =< Y,Head) :-
    write('if(!Jeqsmallerp('),
    jump_eval_form(X),
    write(','),
    jump_eval_form(Y),
    write(')) return(NO);'),nl.

jump_gen_tail_a_body(X > Y,Head) :-
    write('if(!Jgreaterp('),
    jump_eval_form(X),
    write(','),
    jump_eval_form(Y),
    write(')) return(NO);'),nl.

jump_gen_tail_a_body(X >= Y,Head) :-
    write('if(!Jeqgreaterp('),
    jump_eval_form(X),
    write(','),
    jump_eval_form(Y),
    write(')) return(NO);'),nl.

% builtin call
jump_gen_tail_a_body(X,Head) :-
    n_property(X,builtin),
    write('Jcallsubr(Jmakesys("'),
    X =.. [P|L],
    write(P),
    write('"),'),
    jump_gen_a_argument(L),
    write(',NIL,th);'),nl.

% tail call
jump_gen_tail_a_body(X,Head) :-
    functor(X,P,A),
    functor(Head,P,A),
    X =.. [_|Xs],
    jump_gen_tail_call(Xs).

% gen_tail_a_body(X,Head) :-
%    write(user_output,X).
jump_gen_tail_a_body(X,Head).

jump_gen_tail_call(X) :-
    write('arglist = '),
    jump_gen_argument(X),
    write(';'),nl,
    write('goto loop;'),nl.


% analize tail recursive optimization
% if clauses P is optimizable assert jump_pred_data(pred_name,dt)
jump_analize(P) :-
    n_arity_count(P,[N]),
	n_clause_with_arity(P,N,C),
    n_variable_convert(C,C1),
    jump_deterministic(P,C1).

jump_deterministic(P,C) :-
    jump_type1_deterministic(C,0),
    jump_optimize(on),
    assert(jump_pred_data(P,type1)).


% type1 if clause has tail recursive and body is unidirectory
jump_type1_deterministic([],1).
jump_type1_deterministic([],0) :- fail.
jump_type1_deterministic([(Head :- Body)|Cs],_) :-
    jump_tail_recursive(Head,Body),
    jump_unidirectory(Head,Body),
    jump_type1_deterministic(Cs,1).
jump_type1_deterministic([C|Cs],Flag) :-
    n_property(C,predicate),
    jump_self_independence(C),
    jump_type1_deterministic(Cs,Flag).


jump_tail_recursive(Head,Body) :-
    jump_last_body(Body,Last),
    functor(Head,Pred1,Arity1),
    functor(Last,Pred2,Arity2),
    Pred1 == Pred2,
    Arity1 == Arity2,
    jump_self_independence(Head).

jump_last_body((_,Body),Last) :-
    jump_last_body(Body,Last).
jump_last_body(Body,Body).


jump_flatten([],[]).
jump_flatten([X|Xs],[X|Y]) :-
    atomic(X),
    jump_flatten(Xs,Y).
jump_flatten([X|Y],[X,Y]) :-
    atomic(X),
    atomic(Y).
jump_flatten([X|Xs],Y) :-
    jump_flatten(X,X1),
    jump_flatten(Xs,X2),
    append(X1,X2,Y).

jump_unidirectory(Head,Body) :-
    Head =.. [_|A],
    jump_flatten(A,A1),
    jump_unidirectory1(A1,Body).

% body elements are all builtin predicate but last
% if arguments of head depends on left-side of is/2, it is not unidirectory.
jump_unidirectory1(A,(G1,G2)) :-
    n_property(G1,builtin),
    n_property(G2,predicate).
jump_unidirectory1(A,((X is Y),Gs)) :-
    member(X,A),
    !,fail.
jump_unidirectory1(A,(G,Gs)) :-
    n_property(G,builtin),
    jump_unidirectory1(A,Gs).
jump_unidirectory1(A,_) :- fail.


% foo([varX|varL],[varX|1]) -> no
% foo([varY|varL],[varX|1]) -> yes
jump_self_independence(Pred) :-
    Pred =.. [_|Args],
    jump_self_independence1(Args).

jump_self_independence1([]).
jump_self_independence1([X]).
jump_self_independence1([X1,X2|Xs]) :-
    jump_self_independence2(X1,X2),
    jump_self_independence1([X1|Xs]),
    jump_self_independence1([X2|Xs]).

jump_self_independence2(X,Y) :-
    list(X),list(Y),
    jump_list_member(X,Y),!,fail.
jump_self_independence2(X,Y) :-
    atom(X),list(Y),
    member(X,Y),!,fail.
jump_self_independence2(X,Y) :-
    atom(Y),list(X),
    member(Y,X),!,fail.
jump_self_independence2(X,Y) :-
    X = Y,!,fail.
jump_self_independence2(X,Y).

jump_deep_member(X,[X|Ys]) :-
    n_compiler_variable(X).
jump_deep_member(X,X) :-
    n_compiler_variable(X).
jump_deep_member(X,[Y|Ys]) :-
    jump_deep_member(X,Ys).

jump_list_member([],Y) :- fail.
jump_list_member(X,Y) :-
    atomic(X),jump_deep_member(X,Y).
jump_list_member([L|Ls],Y) :-
    jump_deep_member(L,Y).
jump_list_member([L|Ls],Y) :-
    jump_list_member(Ls,Y).


