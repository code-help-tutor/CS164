WeChat: cstutorcs
QQ: 749389476
Email: tutorcs@163.com
open Ast

(* Task 2 *)
let uniquify_variables : program -> program =
  fun p ->
    p

(* Task 3a *)
let propagate_constants : program -> program =
  fun p ->
    p

(* Task 3b *)
let inline : program -> program =
  fun p ->
    p

(* Task 3c *)
let eliminate_common_subexpressions : program -> program =
  fun p ->
    p

let all_passes : (string * (program -> program)) list =
  [ ("propagate-constants", propagate_constants)
  ; ("uniquify-variables", uniquify_variables)
  ; ("inline", inline)
  ; ("eliminate-common-subexpressions", eliminate_common_subexpressions)
  ]

exception InvalidPasses

let rec validate_passes : string list -> unit =
  fun passes ->
    begin match passes with
      | [] ->
          ()

      | "uniquify-variables" :: _ ->
          ()

      | "inline" :: _ ->
          raise InvalidPasses

      | "eliminate-common-subexpressions" :: _ ->
          raise InvalidPasses

      | _ :: l ->
          validate_passes l
    end

let get_passes : string list option -> (program -> program) list =
  fun pass_spec ->
    begin match pass_spec with
      | None ->
          List.map snd all_passes

      | Some l ->
          validate_passes l;
          List.map (fun s -> List.assoc s all_passes) l
    end

let optimize : program -> string list option -> program =
  fun prog pass_spec ->
    let passes = get_passes pass_spec in
    List.fold_left (fun p f -> f p) prog passes
