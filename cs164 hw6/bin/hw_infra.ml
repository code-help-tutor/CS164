WeChat: cstutorcs
QQ: 749389476
Email: tutorcs@163.com
open Shared

module I : Infra.T = struct
  type program = S_exp.s_exp list
  let parse syntax s =
    begin match syntax with
      | Infra.Lisp -> S_exp.parse_many s
      | Infra.Mlb -> failwith "Cannot parse .mlb files for this homework"
    end

  let interp = Lib.Interp.interp
  let interp_io ~input prog = Lib.Interp.interp_io prog input

  let compile = Lib.Compile.compile
  let runtime_object_file = Lib.Runtime.runtime
end

module Cli =  Shared.Cli.Make(I)
module Difftest = Shared.Difftest.Make(I)
