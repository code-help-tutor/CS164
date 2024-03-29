WeChat: cstutorcs
QQ: 749389476
Email: tutorcs@163.com
(* module Cli =  Shared.Cli.Make(Hw_infra.I)
let () = Cli.compile () *)
open Core
open Lib
open Shared

let command =
  Command.basic ~summary:"Compile the given file to an executable"
    Command.Let_syntax.(
      let%map_open filename = anon ("filename" %: Command.Param.string)
      and directory = anon ("directory" %: Command.Param.string)
      and passes = flag "-p" (listed string) ~doc:"optimization passes to use"
      and all_passes =
        flag "-o" no_arg ~doc:"enable all optimizations (overrides -p)"
      and run = flag "-r" no_arg ~doc:"run the binary" in
      fun () ->
        try
          let text = In_channel.read_all filename in
          let ast =
            Lisp_syntax.parse text
          in
          let ast =
            Optimize.optimize ast (if all_passes then None else Some passes)
          in
          let instrs = Compile.compile ast in
          let filename = Filename.basename filename in
          if run then
            Assemble.eval directory Runtime.runtime filename [] instrs
            |> function
            | Ok output ->
                printf "%s\n" output
            | Error (Expected error | Unexpected error) ->
                eprintf "%s\n" error
          else
            Assemble.build directory Runtime.runtime filename instrs |> ignore
        with Error.Stuck _ as e ->
          Printf.eprintf "Error: %s\n" (Exn.to_string e))

let () = Command_unix.run ~version:"1.0" command
