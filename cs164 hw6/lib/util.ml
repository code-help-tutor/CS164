WeChat: cstutorcs
QQ: 749389476
Email: tutorcs@163.com
open S_exp
open Shared
open Error

let gensym : string -> string =
  let counter = ref 0 in
  fun (base : string) ->
    let number = !counter in
    counter := !counter + 1 ;
    Printf.sprintf "%s__%d" base number

let get_bindings (lst : s_exp list) : (string * s_exp) list =
  List.map
    (fun (e : s_exp) ->
      match e with
      | Lst [Sym var; exp] ->
          (var, exp)
      | _ ->
          raise (Stuck e))
    lst

let get_cases (lst : s_exp list) : (int * s_exp) list =
  List.map
    (fun (e : s_exp) ->
      match e with Lst [Num n; exp] -> (n, exp) | _ -> raise (Stuck e))
    lst

module List = struct
  include List

  let rec range lo hi = if lo > hi then [] else lo :: range (lo + 1) hi

  let partition_at (n : int) (l : 'a list) =
    if n < 0 then raise (Invalid_argument "partition_at") ;
    let rec go left rest = function
      | 0 ->
          (List.rev left, rest)
      | n ->
          go (List.hd rest :: left) (List.tl rest) (n - 1)
    in
    go [] l n
end

let rec input_all (ch : in_channel) : string =
  try
    let c = input_char ch in
    String.make 1 c ^ input_all ch
  with End_of_file -> ""

type defn = {name: string; args: string list; rest: string option; body: s_exp}

let sym = function Sym s -> s | e -> raise (Stuck e)

let defns_and_body (exps : s_exp list) : defn list * s_exp =
  let rec args_and_rest args = function
    | [] ->
        (List.rev args, None)
    | [arg; Dots] ->
        (List.rev args, Some (sym arg))
    | arg :: exps ->
        args_and_rest (sym arg :: args) exps
  in
  let get_defn = function
    | Lst [Sym "define"; Lst (Sym name :: args); body] ->
        let args, rest = args_and_rest [] args in
        {name; args; rest; body}
    | e ->
        raise (Stuck e)
  in
  let rec go exps defns =
    match exps with
    | [e] ->
        (List.rev defns, e)
    | d :: exps ->
        go exps (get_defn d :: defns)
    | _ ->
        raise (Stuck (Sym "empty"))
  in
  go exps []

let is_defn defns name = List.exists (fun d -> d.name = name) defns

let get_defn defns name = List.find (fun d -> d.name = name) defns
