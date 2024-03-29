WeChat: cstutorcs
QQ: 749389476
Email: tutorcs@163.com
open Util
open Shared
open Error
open Directive
open Ast

(** constants used for tagging values at runtime *)
let num_shift = 2

let num_mask = 0b11

let num_tag = 0b00

let bool_shift = 7

let bool_mask = 0b1111111

let bool_tag = 0b0011111

let heap_mask = 0b111

let pair_tag = 0b010

let nil_tag = 0b11111111

type symtab = int Symtab.symtab

let function_label s =
  let nasm_char c =
    match c with
    | 'a' .. 'z'
    | 'A' .. 'Z'
    | '0' .. '9'
    | '_'
    | '$'
    | '#'
    | '@'
    | '~'
    | '.'
    | '?' ->
        c
    | _ ->
        '_'
  in
  Printf.sprintf "function_%s_%d" (String.map nasm_char s) (Hashtbl.hash s)

(** [operand_of_num x] returns the runtime representation of the number [x] as an
   operand for instructions *)
let operand_of_num (x : int) : operand = Imm ((x lsl num_shift) lor num_tag)

(** [operand_of_bool b] returns the runtime representation of the boolean [b] as an
   operand for instructions *)
let operand_of_bool (b : bool) : operand =
  Imm (((if b then 1 else 0) lsl bool_shift) lor bool_tag)

let operand_of_nil = Imm nil_tag

let zf_to_bool =
  [ Mov (Reg Rax, Imm 0)
  ; Setz (Reg Rax)
  ; Shl (Reg Rax, Imm bool_shift)
  ; Or (Reg Rax, Imm bool_tag) ]

let setl_bool =
  [ Mov (Reg Rax, Imm 0)
  ; Setl (Reg Rax)
  ; Shl (Reg Rax, Imm bool_shift)
  ; Or (Reg Rax, Imm bool_tag) ]

let stack_address (index : int) : operand = MemOffset (Imm index, Reg Rsp)

let ensure condition err_msg =
  let msg_label = gensym "emsg" in
  let continue_label = gensym "continue" in
  condition
  @ [ Je continue_label
    ; LeaLabel (Reg Rdi, msg_label)
    ; Jmp "lisp_error"
    ; Label msg_label
    ; DqString err_msg
    ; Label continue_label ]

let ensure_type mask tag op e =
  ensure
    [Mov (Reg R8, op); And (Reg R8, Imm mask); Cmp (Reg R8, Imm tag)]
    (string_of_expr e)

let ensure_num = ensure_type num_mask num_tag

let ensure_pair = ensure_type heap_mask pair_tag

let align_stack_index (stack_index : int) : int =
  if stack_index mod 16 = -8 then stack_index else stack_index - 8

(** [compile_0ary_primitive e prim] produces X86-64 instructions for the zero-arity
   primitive operation  [prim]; if [prim] isn't a valid zero-arity operation,
   it raises an error using the expression [e] *)
let compile_0ary_primitive stack_index _e = function
  | ReadNum ->
      [ Mov (stack_address stack_index, Reg Rdi)
      ; Add (Reg Rsp, Imm (align_stack_index stack_index))
      ; Call "read_num"
      ; Sub (Reg Rsp, Imm (align_stack_index stack_index))
      ; Mov (Reg Rdi, stack_address stack_index) ]
  | Newline ->
      [ Mov (stack_address stack_index, Reg Rdi)
      ; Add (Reg Rsp, Imm (align_stack_index stack_index))
      ; Call "print_newline"
      ; Sub (Reg Rsp, Imm (align_stack_index stack_index))
      ; Mov (Reg Rdi, stack_address stack_index)
      ; Mov (Reg Rax, operand_of_bool true) ]

(** [compile_unary_primitive e prim] produces X86-64 instructions for the unary
   primitive operation [prim]; if [prim] isn't a valid unary operation,
   it raises an error using the expression [e] *)
let compile_unary_primitive stack_index e = function
  | Add1 ->
      ensure_num (Reg Rax) e @ [Add (Reg Rax, operand_of_num 1)]
  | Sub1 ->
      ensure_num (Reg Rax) e @ [Sub (Reg Rax, operand_of_num 1)]
  | IsZero ->
      [Cmp (Reg Rax, operand_of_num 0)] @ zf_to_bool
  | IsNum ->
      [And (Reg Rax, Imm num_mask); Cmp (Reg Rax, Imm num_tag)] @ zf_to_bool
  | Not ->
      [Cmp (Reg Rax, operand_of_bool false)] @ zf_to_bool
  | IsPair ->
      [And (Reg Rax, Imm heap_mask); Cmp (Reg Rax, Imm pair_tag)] @ zf_to_bool
  | Left ->
      ensure_pair (Reg Rax) e
      @ [Mov (Reg Rax, MemOffset (Reg Rax, Imm (-pair_tag)))]
  | Right ->
      ensure_pair (Reg Rax) e
      @ [Mov (Reg Rax, MemOffset (Reg Rax, Imm (-pair_tag + 8)))]
  | IsEmpty ->
      [Cmp (Reg Rax, operand_of_nil)] @ zf_to_bool
  | Print ->
      [ Mov (stack_address stack_index, Reg Rdi)
      ; Mov (Reg Rdi, Reg Rax)
      ; Add (Reg Rsp, Imm (align_stack_index stack_index))
      ; Call "print_value"
      ; Sub (Reg Rsp, Imm (align_stack_index stack_index))
      ; Mov (Reg Rdi, stack_address stack_index)
      ; Mov (Reg Rax, operand_of_bool true) ]

(** [compile_binary_primitive stack_index e prim] produces X86-64 instructions
   for the binary primitive operation [prim]; if [prim] isn't a valid
   binary operation, it raises an error using the expression [e] *)
let compile_binary_primitive stack_index e = function
  | Plus ->
      ensure_num (Reg Rax) e
      @ ensure_num (stack_address stack_index) e
      @ [Add (Reg Rax, stack_address stack_index)]
  | Minus ->
      ensure_num (Reg Rax) e
      @ ensure_num (stack_address stack_index) e
      @ [ Mov (Reg R8, Reg Rax)
        ; Mov (Reg Rax, stack_address stack_index)
        ; Sub (Reg Rax, Reg R8) ]
  | Eq ->
      ensure_num (Reg Rax) e
      @ ensure_num (stack_address stack_index) e
      @ [Cmp (stack_address stack_index, Reg Rax)]
      @ zf_to_bool
  | Lt ->
      ensure_num (Reg Rax) e
      @ ensure_num (stack_address stack_index) e
      @ [Cmp (stack_address stack_index, Reg Rax)]
      @ setl_bool
  | Pair ->
      [ Mov (Reg R8, stack_address stack_index)
      ; Mov (MemOffset (Reg Rdi, Imm 0), Reg R8)
      ; Mov (MemOffset (Reg Rdi, Imm 8), Reg Rax)
      ; Mov (Reg Rax, Reg Rdi)
      ; Or (Reg Rax, Imm pair_tag)
      ; Add (Reg Rdi, Imm 16) ]

let align n alignment =
  if n mod alignment = 0 then n else n + (alignment - (n mod alignment))

(** [compile_expr e] produces X86-64 instructions for the expression [e] *)
let rec compile_expr (defns : defn list) (tab : symtab) (stack_index : int)
    (is_tail : bool) : expr -> directive list = function
  | Num x ->
      [Mov (Reg Rax, operand_of_num x)]
  | True ->
      [Mov (Reg Rax, operand_of_bool true)]
  | False ->
      [Mov (Reg Rax, operand_of_bool false)]
  | Var var when Symtab.mem var tab ->
      [Mov (Reg Rax, stack_address (Symtab.find var tab))]
  | Var _ as e ->
      raise (Stuck (s_exp_of_expr e))
  | Nil ->
      [Mov (Reg Rax, operand_of_nil)]
  | If (test_expr, then_expr, else_expr) ->
      let then_label = gensym "then" in
      let else_label = gensym "else" in
      let continue_label = gensym "continue" in
      compile_expr defns tab stack_index false test_expr
      @ [Cmp (Reg Rax, operand_of_bool false); Je else_label]
      @ [Label then_label]
      @ compile_expr defns tab stack_index is_tail then_expr
      @ [Jmp continue_label] @ [Label else_label]
      @ compile_expr defns tab stack_index is_tail else_expr
      @ [Label continue_label]
  | Let (var, exp, body) ->
      compile_expr defns tab stack_index false exp
      @ [Mov (stack_address stack_index, Reg Rax)]
      @ compile_expr defns
          (Symtab.add var stack_index tab)
          (stack_index - 8) is_tail body
  | Do exps ->
      List.concat
        (List.mapi
           (fun i exp ->
             compile_expr defns tab stack_index
               (if i = List.length exps - 1 then is_tail else false)
               exp)
           exps)
  | Call (f, args) as e when is_defn defns f && is_tail ->
      let defn = get_defn defns f in
      if List.length args = List.length defn.args then
        let compiled_args =
          args
          |> List.mapi (fun i arg ->
                 compile_expr defns tab (stack_index - (8 * i)) false arg
                 @ [Mov (stack_address (stack_index - (8 * i)), Reg Rax)])
          |> List.concat
        in
        let moved_args =
          args
          |> List.mapi (fun i _ ->
                 [ Mov (Reg R8, stack_address (stack_index - (8 * i)))
                 ; Mov (stack_address ((i + 1) * -8), Reg R8) ])
          |> List.concat
        in
        compiled_args @ moved_args @ [Jmp (function_label f)]
      else raise (Stuck (s_exp_of_expr e))
  | Call (f, args) as e when is_defn defns f ->
      let stack_base = align_stack_index (stack_index + 8) in
      let defn = get_defn defns f in
      if List.length args = List.length defn.args then
        let compiled_args =
          args
          |> List.mapi (fun i arg ->
                 compile_expr defns tab (stack_base - ((i + 2) * 8)) false arg
                 @ [Mov (stack_address (stack_base - ((i + 2) * 8)), Reg Rax)])
          |> List.concat
        in
        compiled_args
        @ [ Add (Reg Rsp, Imm stack_base)
          ; Call (function_label f)
          ; Sub (Reg Rsp, Imm stack_base) ]
      else raise (Stuck (s_exp_of_expr e))
  | Call _ as e ->
    raise (Stuck (s_exp_of_expr e))
  | Prim0 f as exp ->
      compile_0ary_primitive stack_index exp f
  | Prim1 (f, arg) as exp ->
      compile_expr defns tab stack_index false arg
      @ compile_unary_primitive stack_index exp f
  | Prim2 (f, arg1, arg2) as exp ->
      compile_expr defns tab stack_index false arg1
      @ [Mov (stack_address stack_index, Reg Rax)]
      @ compile_expr defns tab (stack_index - 8) false arg2
      @ compile_binary_primitive stack_index exp f

(** [compile_defn defns defn] produces X86-64 instructions for the function
   definition [defn] **)
let compile_defn (defns : defn list) defn : directive list =
  let ftab =
    defn.args |> List.mapi (fun i arg -> (arg, (i + 1) * -8)) |> Symtab.of_list
  in
  [Label (function_label defn.name)]
  @ compile_expr defns ftab ((List.length defn.args + 1) * -8) true defn.body
  @ [Ret]

(** [compile] produces X86-64 instructions, including frontmatter, for the
   expression [e] *)
let compile (prog : program) =
  [ Global "lisp_entry"
  ; Extern "lisp_error"
  ; Extern "read_num"
  ; Extern "print_value"
  ; Extern "print_newline"
  ; Section "text" ]
  @ List.concat_map (compile_defn prog.defns) prog.defns
  @ [Label "lisp_entry"]
  @ compile_expr prog.defns Symtab.empty (-8) true prog.body
  @ [Ret]
