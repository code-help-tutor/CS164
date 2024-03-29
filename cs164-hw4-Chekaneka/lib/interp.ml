WeChat: cstutorcs
QQ: 749389476
Email: tutorcs@163.com
open Printf
open Util
open S_exp
open Shared
open Error

(** A [value]  is the runtime value of an expression. *)
type value
  = Num of int
  | Bool of bool
  | Pair of (value * value)

type environment =
  value Symtab.symtab

let top_env : environment =
  Symtab.empty
    |> Symtab.add "true" (Bool true)
    |> Symtab.add "false" (Bool false)

(** [display_value v] returns a string representation of the runtime value
    [v]. *)
let rec display_value : value -> string =
  fun v ->
    begin match v with
      | Num x ->
          sprintf "%d" x

      | Bool b ->
          if b then "true" else "false"

      | Pair (v1, v2) ->
          sprintf "(pair %s %s)" (display_value v1) (display_value v2)
    end

(** [interp_unary_primitive prim arg] tries to evaluate the primitive operation
    named by [prim] on the argument [arg]. If the operation is ill-typed, or if
    [prim] does not refer to a valid primitive operation, it returns [None]. *)
let interp_unary_primitive : string -> value -> value option =
  fun prim arg ->
    begin match (prim, arg) with
      | ("add1", Num x) ->
          Some (Num (x + 1))

      | ("sub1", Num x) ->
          Some (Num (x - 1))

      | ("zero?", Num 0) ->
          Some (Bool true)

      | ("zero?", _) ->
          Some (Bool false)

      | ("num?", Num _) ->
          Some (Bool true)

      | ("num?", _) ->
          Some (Bool false)

      | ("not", Bool false) ->
          Some (Bool true)

      | ("not", _) ->
          Some (Bool false)

      | ("pair?", Pair _) ->
          Some (Bool true)

      | ("pair?", _) ->
          Some (Bool false)

      | ("left", Pair (v, _)) ->
          Some v

      | ("right", Pair (_, v)) ->
          Some v

      | _ ->
          None
    end

(** [interp_binary_primitive prim arg1 arg2] tries to evaluate the primitive
    operation named by [prim] on the arguments [arg1] and [arg2]. If the
    operation is ill-typed, or if [prim] does not refer to a valid primitive
    operation, it returns [None]. *)
let interp_binary_primitive : string -> value -> value -> value option =
  fun prim arg1 arg2 ->
    begin match (prim, arg1, arg2) with
      | ("+", Num x1, Num x2) ->
          Some (Num (x1 + x2))

      | ("-", Num x1, Num x2) ->
          Some (Num (x1 - x2))

      | ("=", Num x1, Num x2) ->
          Some (Bool (x1 = x2))

      | ("<", Num x1, Num x2) ->
          Some (Bool (x1 < x2))

      | ("pair", v1, v2) ->
          Some (Pair (v1, v2))

      | _ ->
          None
    end

(** [interp_trinary_primitive prim arg1 arg2 arg3] tries to evaluate the
    primitive operation named by [prim] on the arguments [arg1], [arg2], and
    [arg3]. If the operation is ill-typed, or if [prim] does not refer to a
    valid primitive operation, it returns [None]. *)
let interp_trinary_primitive :
 string -> value -> value -> value -> value option =
  fun prim arg1 arg2 arg3 ->
    begin match (prim, arg1, arg2, arg3) with
      | _ ->
        None
    end

(** [interp_expr e] tries to evaluate the s_expression [e], producing a
    value. If [e] isn't a valid expression, it raises an exception. *)
let rec interp_expr : environment -> s_exp -> value =
  fun env e ->
    begin match e with
      | Num x ->
          Num x

      | Sym var ->
          begin match Symtab.find_opt var env with
            | Some value ->
                value

            | None ->
                raise (Stuck e)
          end

      | Lst [Sym "let"; Lst [Lst [Sym var; exp]]; body] ->
          let env' =
            Symtab.add var (interp_expr env exp) env
          in
          interp_expr env' body

      | Lst [Sym "if"; test_exp; then_exp; else_exp] ->
          begin match interp_expr env test_exp with
            | Bool false ->
                interp_expr env else_exp

            | _ ->
                interp_expr env then_exp
          end

      | Lst (Sym "do" :: exps) when List.length exps > 0 ->
          exps
            |> List.rev_map (interp_expr env)
            |> List.hd

      | Lst [Sym f; arg] ->
          begin match interp_unary_primitive f (interp_expr env arg) with
            | Some v ->
                v

            | None ->
                raise (Stuck e)
          end

      | Lst [Sym f; arg1; arg2] ->
          begin match
            interp_binary_primitive
              f
              (interp_expr env arg1)
              (interp_expr env arg2)
          with
            | Some v ->
                v

            | None ->
                raise (Stuck e)
          end

      | Lst [Sym f; arg1; arg2; arg3] ->
        begin match
          interp_trinary_primitive
            f
            (interp_expr env arg1)
            (interp_expr env arg2)
            (interp_expr env arg3)
        with
          | Some v ->
              v

          | None ->
              raise (Stuck e)
        end

      | e ->
          raise (Stuck e)
    end

(** [interp e] evaluates the s_expression [e] using [interp_expr], then formats
    the result as a string. *)
let interp : s_exp -> string =
  fun e ->
    e
      |> interp_expr top_env
      |> display_value
