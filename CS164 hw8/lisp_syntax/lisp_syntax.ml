WeChat: cstutorcs
QQ: 749389476
Email: tutorcs@163.com
open S_exp
open Ast

exception ParseError of s_exp

let prim0_of_string = function
  | "read-num" ->
      Some ReadNum
  | "newline" ->
      Some Newline
  | _ ->
      None

let prim1_of_string = function
  | "add1" ->
      Some Add1
  | "sub1" ->
      Some Sub1
  | "zero?" ->
      Some IsZero
  | "num?" ->
      Some IsNum
  | "pair?" ->
      Some IsPair
  | "empty?" ->
      Some IsEmpty
  | "not" ->
      Some Not
  | "left" ->
      Some Left
  | "right" ->
      Some Right
  | "print" ->
      Some Print
  | _ ->
      None

let prim2_of_string = function
  | "+" ->
      Some Plus
  | "-" ->
      Some Minus
  | "=" ->
      Some Eq
  | "<" ->
      Some Lt
  | "pair" ->
      Some Pair
  | _ ->
      None

let rec expr_of_s_exp : s_exp -> expr = function
  | Num x ->
      Num x
  | Sym "true" ->
      True
  | Sym "false" ->
      False
  | Sym var ->
      Var var
  | Lst [] ->
      Nil
  | Lst [Sym "let"; Lst [Lst [Sym var; exp]]; body] ->
      Let (var, expr_of_s_exp exp, expr_of_s_exp body)
  | Lst (Sym "do" :: exps) when List.length exps > 0 ->
      Do (List.map expr_of_s_exp exps)
  | Lst [Sym "if"; test_s; then_s; else_s] ->
      If (expr_of_s_exp test_s, expr_of_s_exp then_s, expr_of_s_exp else_s)
  | Lst [Sym prim] when Option.is_some (prim0_of_string prim) ->
      Prim0 (Option.get (prim0_of_string prim))
  | Lst [Sym prim; arg] when Option.is_some (prim1_of_string prim) ->
      Prim1 (Option.get (prim1_of_string prim), expr_of_s_exp arg)
  | Lst [Sym prim; arg1; arg2] when Option.is_some (prim2_of_string prim) ->
      Prim2
        ( Option.get (prim2_of_string prim)
        , expr_of_s_exp arg1
        , expr_of_s_exp arg2 )
  | Lst (Sym f :: args) ->
      Call (f, List.map expr_of_s_exp args)
  | e ->
      raise (ParseError e)

let program_of_s_exps (exps : s_exp list) : program =
  let rec get_args args =
    match args with
    | Sym v :: args ->
        v :: get_args args
    | e :: _ ->
        raise (ParseError e)
    | [] ->
        []
  in
  let get_defn = function
    | Lst [Sym "define"; Lst (Sym name :: args); body] ->
        let args = get_args args in
        {name; args; body= expr_of_s_exp body}
    | e ->
        raise (ParseError e)
  in
  let rec go exps defns =
    match exps with
    | [e] ->
        {defns= List.rev defns; body= expr_of_s_exp e}
    | d :: exps ->
        go exps (get_defn d :: defns)
    | _ ->
        raise (ParseError (Sym "empty"))
  in
  go exps []

let parse s = s |> S_exp.parse_many |> program_of_s_exps
