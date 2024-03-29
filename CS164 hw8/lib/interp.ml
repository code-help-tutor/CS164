WeChat: cstutorcs
QQ: 749389476
Email: tutorcs@163.com
open Printf
open Util
open Shared
open Error
open Ast

(** a [value]  is the runtime value of an expression *)
type value = Num of int | Bool of bool | Pair of (value * value) | Nil

type environment = value Symtab.symtab

let input_channel = ref stdin

let output_channel = ref stdout

(** [display_value v] returns a string representation of the runtime value [v] *)
let rec display_value = function
  | Num x ->
      sprintf "%d" x
  | Bool b ->
      if b then "true" else "false"
  | Pair (v1, v2) ->
      sprintf "(pair %s %s)" (display_value v1) (display_value v2)
  | Nil ->
      "()"

let interp_0ary_primitive prim =
  match prim with
  | ReadNum ->
      Some (Num (input_line !input_channel |> int_of_string))
  | Newline ->
      output_string !output_channel "\n" ;
      Some (Bool true)

(** [interp_unary_primitive prim arg] tries to evaluate the primitive operation
   [prim] on the argument [arg]. If the operation is ill-typed, or if
   [prim] does not refer to a valid primitive operation, it returns None.*)
let interp_unary_primitive prim arg =
  match (prim, arg) with
  | Add1, Num x ->
      Some (Num (x + 1))
  | Sub1, Num x ->
      Some (Num (x - 1))
  | IsZero, Num 0 ->
      Some (Bool true)
  | IsZero, _ ->
      Some (Bool false)
  | IsNum, Num _ ->
      Some (Bool true)
  | IsNum, _ ->
      Some (Bool false)
  | Not, Bool false ->
      Some (Bool true)
  | Not, _ ->
      Some (Bool false)
  | IsPair, Pair _ ->
      Some (Bool true)
  | IsPair, _ ->
      Some (Bool false)
  | Left, Pair (v, _) ->
      Some v
  | Right, Pair (_, v) ->
      Some v
  | IsEmpty, Nil ->
      Some (Bool true)
  | IsEmpty, _ ->
      Some (Bool false)
  | Print, v ->
      v |> display_value |> output_string !output_channel ;
      Some (Bool true)
  | _ ->
      None

(** [interp_binary_primitive prim arg1 arg2] tries to evaluate the primitive
   operation [prim] on the arguments [arg] and [arg2]. If the operation
   is ill-typed, or if [prim] does not refer to a valid primitive operation, it
   returns None.*)
let interp_binary_primitive prim arg1 arg2 =
  match (prim, arg1, arg2) with
  | Plus, Num x1, Num x2 ->
      Some (Num (x1 + x2))
  | Minus, Num x1, Num x2 ->
      Some (Num (x1 - x2))
  | Eq, Num x1, Num x2 ->
      Some (Bool (x1 = x2))
  | Lt, Num x1, Num x2 ->
      Some (Bool (x1 < x2))
  | Pair, v1, v2 ->
      Some (Pair (v1, v2))
  | _ ->
      None

let rec interp_expr (defns : defn list) (env : environment) : expr -> value =
  function
  | Num x ->
      Num x
  | Var var as e -> (
    match Symtab.find_opt var env with
    | Some value ->
        value
    | None ->
        raise (Stuck (s_exp_of_expr e)) )
  | Nil ->
      Nil
  | Let (var, exp, body) ->
      let env = env |> Symtab.add var (interp_expr defns env exp) in
      interp_expr defns env body
  | If (test_exp, then_exp, else_exp) ->
      if interp_expr defns env test_exp <> Bool false then
        interp_expr defns env then_exp
      else interp_expr defns env else_exp
  | Do exps ->
      exps |> List.rev_map (interp_expr defns env) |> List.hd
  | Call (f, args) as e when is_defn defns f ->
      let defn = get_defn defns f in
      if List.length args = List.length defn.args then
        let fenv =
          args
          |> List.map (interp_expr defns env)
          |> List.combine defn.args |> Symtab.of_list
        in
        interp_expr defns fenv defn.body
      else raise (Stuck (s_exp_of_expr e))
  | Call _ as e ->
      raise (Stuck (s_exp_of_expr e))
  | Prim0 f as e -> (
    match interp_0ary_primitive f with
    | Some v ->
        v
    | None ->
        raise (Stuck (s_exp_of_expr e)) )
  | Prim1 (f, arg) as e -> (
    match interp_unary_primitive f (interp_expr defns env arg) with
    | Some v ->
        v
    | None ->
        raise (Stuck (s_exp_of_expr e)) )
  | Prim2 (f, arg1, arg2) as e -> (
    match
      let v1 = interp_expr defns env arg1 in
      let v2 = interp_expr defns env arg2 in
      interp_binary_primitive f v1 v2
    with
    | Some v ->
        v
    | None ->
        raise (Stuck (s_exp_of_expr e)) )
  | True ->
      Bool true
  | False ->
      Bool false

(** [interp prog] evaluates the program [prog] using [interp_expr], reading input
   from stdin and writing output to stdout. *)
let interp (prog : program) =
  interp_expr prog.defns Symtab.empty prog.body |> ignore

(** [interp_io prog input] evaluates the program [prog] using [interp_expr],
   reading input from the string [input] and returning the output as a
   string. *)
let interp_io (prog : program) input =
  let input_pipe_ex, input_pipe_en = Unix.pipe () in
  let output_pipe_ex, output_pipe_en = Unix.pipe () in
  input_channel := Unix.in_channel_of_descr input_pipe_ex ;
  set_binary_mode_in !input_channel false ;
  output_channel := Unix.out_channel_of_descr output_pipe_en ;
  set_binary_mode_out !output_channel false ;
  let write_input_channel = Unix.out_channel_of_descr input_pipe_en in
  set_binary_mode_out write_input_channel false ;
  let read_output_channel = Unix.in_channel_of_descr output_pipe_ex in
  set_binary_mode_in read_output_channel false ;
  output_string write_input_channel input ;
  close_out write_input_channel ;
  interp prog ;
  close_out !output_channel ;
  let r = input_all read_output_channel in
  input_channel := stdin ;
  output_channel := stdout ;
  r
