WeChat: cstutorcs
QQ: 749389476
Email: tutorcs@163.com
open Tokens
open Ast

exception ParseError of token list

(** [consume_token t toks] ensures that the head of [toks] is [t]. If it is, it
    returns the tail of [toks]. Otherwise, it raises a [ParseError].  *)
let consume_token : token -> token list -> token list =
  fun t toks ->
    begin match toks with
      | t' :: tail when t = t' ->
          tail

      | _ ->
          raise (ParseError toks)
    end

(** [call_or_prim f args toks] returns an expression corresponding to the
    application of [f] to [args]. If [f] is a primitive, the AST node for this
    will application will be [Prim0], [Prim1], or [Prim2]; otherwise, it will be
    [Call]. If the length of [args] does not match the arity of [f], this
    function will throw [ParseError toks]. *)
let call_or_prim : string -> expr list -> token list -> expr =
  fun f args toks ->
  begin match f with
    | "read_num" ->
        begin match args with
          | [] -> Prim0 ReadNum
          | _ -> raise (ParseError toks)
        end

    | "newline" ->
        begin match args with
          | [] -> Prim0 Newline
          | _ -> raise (ParseError toks)
        end

    | "add1" ->
        begin match args with
          | [arg] -> Prim1 (Add1, arg)
          | _ -> raise (ParseError toks)
        end

    | "sub1" ->
        begin match args with
          | [arg] -> Prim1 (Sub1, arg)
          | _ -> raise (ParseError toks)
        end

    | "is_zero" ->
        begin match args with
          | [arg] -> Prim1 (IsZero, arg)
          | _ -> raise (ParseError toks)
        end

    | "is_num" ->
        begin match args with
          | [arg] -> Prim1 (IsNum, arg)
          | _ -> raise (ParseError toks)
        end

    | "is_pair" ->
        begin match args with
          | [arg] -> Prim1 (IsPair, arg)
          | _ -> raise (ParseError toks)
        end

    | "is_empty" ->
        begin match args with
          | [arg] -> Prim1 (IsEmpty, arg)
          | _ -> raise (ParseError toks)
        end

    | "left" ->
        begin match args with
          | [arg] -> Prim1 (Left, arg)
          | _ -> raise (ParseError toks)
        end

    | "right" ->
        begin match args with
          | [arg] -> Prim1 (Right, arg)
          | _ -> raise (ParseError toks)
        end

    | "print" ->
        begin match args with
          | [arg] -> Prim1 (Print, arg)
          | _ -> raise (ParseError toks)
        end

    | "pair" ->
        begin match args with
          | [arg1; arg2] -> Prim2 (Pair, arg1, arg2)
          | _ -> raise (ParseError toks)
        end

    | _ ->
        Call (f, args)
  end

let rec parse_program : token list -> program =
  fun toks ->
    let defns, toks = parse_defns toks in
    let body, toks = parse_expr toks in
    if List.length toks <> 0 then
      raise (ParseError toks)
    else
      {defns; body}

and parse_defns : token list -> defn list * token list =
  fun toks ->
    ([], toks)

and parse_expr : token list -> expr * token list =
  fun toks ->
    (True, toks)

let parse : string -> program =
  fun s ->
    s
      |> tokenize
      |> parse_program
