WeChat: cstutorcs
QQ: 749389476
Email: tutorcs@163.com
exception Stuck of S_exp.s_exp
exception UndefinedBehavior of string

let () =
  Printexc.register_printer (function
    | Stuck e ->
        Some (Printf.sprintf "Stuck[%s]" (S_exp.string_of_s_exp e))
    | _ ->
        None)
