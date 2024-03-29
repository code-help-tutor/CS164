WeChat: cstutorcs
QQ: 749389476
Email: tutorcs@163.com
open String

module Symtab = Map.Make (struct
  type t = string

  let compare = compare
end)

type 'a symtab = 'a Symtab.t

include Symtab
