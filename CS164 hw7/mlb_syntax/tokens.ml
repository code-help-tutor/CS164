WeChat: cstutorcs
QQ: 749389476
Email: tutorcs@163.com
type token =
  | FUNCTION
  | LET
  | IN
  | IF
  | THEN
  | ELSE
  | PLUS
  | MINUS
  | EQ
  | LT
  | LPAREN
  | RPAREN
  | COMMA
  | SEMICOLON
  | ID of string
  | NUM of int

let function_regex = Str.regexp "function\\b"

let let_regex = Str.regexp "let\\b"

let in_regex = Str.regexp "in\\b"

let if_regex = Str.regexp "if\\b"

let then_regex = Str.regexp "then\\b"

let else_regex = Str.regexp "else\\b"

let plus_regex = Str.regexp "\\+"

let minus_regex = Str.regexp "-"

let eq_regex = Str.regexp "="

let lt_regex = Str.regexp "<"

let lparen_regex = Str.regexp "("

let rparen_regex = Str.regexp ")"

let comma_regex = Str.regexp ","

let semicolon_regex = Str.regexp ";"

let whitespace_regex = Str.regexp "[ \n\t]+"

let id_regex = Str.regexp "\\([A-Za-z][A-Za-z0-9_]*\\)\\b"

let num_regex = Str.regexp "\\(-?[0-9]+\\)\\b"

exception TokenizerError of int

let get_token : string -> int -> token option * int =
  fun s index ->
    if Str.string_match whitespace_regex s index then
      (None, Str.match_end ())
    else if Str.string_match function_regex s index then
      (Some FUNCTION, Str.match_end ())
    else if Str.string_match let_regex s index then
      (Some LET, Str.match_end ())
    else if Str.string_match in_regex s index then
      (Some IN, Str.match_end ())
    else if Str.string_match if_regex s index then
      (Some IF, Str.match_end ())
    else if Str.string_match then_regex s index then
      (Some THEN, Str.match_end ())
    else if Str.string_match else_regex s index then
      (Some ELSE, Str.match_end ())
    else if Str.string_match plus_regex s index then
      (Some PLUS, Str.match_end ())
    else if Str.string_match num_regex s index then
      (Some (NUM (int_of_string (Str.matched_group 1 s))), Str.match_end ())
    else if Str.string_match minus_regex s index then
      (Some MINUS, Str.match_end ())
    else if Str.string_match eq_regex s index then
      (Some EQ, Str.match_end ())
    else if Str.string_match lt_regex s index then
      (Some LT, Str.match_end ())
    else if Str.string_match lparen_regex s index then
      (Some LPAREN, Str.match_end ())
    else if Str.string_match rparen_regex s index then
      (Some RPAREN, Str.match_end ())
    else if Str.string_match comma_regex s index then
      (Some COMMA, Str.match_end ())
    else if Str.string_match semicolon_regex s index then
      (Some SEMICOLON, Str.match_end ())
    else if Str.string_match id_regex s index then
      (Some (ID (Str.matched_group 1 s)), Str.match_end ())
    else
      raise (TokenizerError index)

let tokenize : string -> token list =
  fun s ->
    let rec helper : int -> token list =
      fun index ->
        if index >= String.length s then
          []
        else
          let token, index = get_token s index in
          begin match token with
            | None ->
                helper index

            | Some token ->
                token :: helper index
          end
    in
    helper 0

let string_of_token : token -> string =
  fun tok ->
    begin match tok with
      | FUNCTION -> "FUNCTION"
      | LET -> "LET"
      | IN -> "IN"
      | IF -> "IF"
      | THEN -> "THEN"
      | ELSE -> "ELSE"
      | PLUS -> "PLUS"
      | MINUS -> "MINUS"
      | EQ -> "EQ"
      | LT -> "LT"
      | LPAREN -> "LPAREN"
      | RPAREN -> "RPAREN"
      | COMMA -> "COMMA"
      | SEMICOLON -> "SEMICOLON"
      | ID x -> "ID(" ^ x ^ ")"
      | NUM n -> "NUM(" ^ string_of_int n ^ ")"
    end
