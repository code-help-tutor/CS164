WeChat: cstutorcs
QQ: 749389476
Email: tutorcs@163.com
let gensym : string -> string =
  let counter = ref 0 in
  fun (base : string) ->
    let number = !counter in
    counter := !counter + 1 ;
    Printf.sprintf "%s__%d" base number

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
