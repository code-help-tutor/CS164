WeChat: cstutorcs
QQ: 749389476
Email: tutorcs@163.com
type t =
  | Num of int
  | Sym of string
  | Chr of char
  | Str of string
  | Lst of t list
  | Dots
[@@deriving show]
