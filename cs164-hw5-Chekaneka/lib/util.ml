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
end

let rec input_all (ch : in_channel) : string =
  try
    let c = input_char ch in
    String.make 1 c ^ input_all ch
  with End_of_file -> ""
