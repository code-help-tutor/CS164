# Homework 7: Parsing

In this homework, you'll implement a top-down predictive parser for an
alternative syntax for our language. This syntax is called ML (Berkeley),
because it bears a vague resemblance to ML-family languages like OCaml.
We'll usually refer to it as MLB.

Here's an example of an MLB program:

```
function add_up(a, b, c) =
  a + b = c

let x = 
  if 
    add_up(read_num(), read_num(), read_num())
  then 1
  else 2 
in
print(x)
```

Unlike the previous assignments, **you won't be modifying either the interpreter
or the compiler.** We've provided an AST-based version of the HW6 compiler and
interpreter as well as functions to produce the AST from s-expressions. You'll
write a parser that produces the *same* AST but that instead reads in
MLB-formatted source code.

Here's a grammar (like the ones we discussed in class) for MLB:

```
<program> ::= <defns> <expr>

<defns> ::=
  | epsilon
  | <defn> <defns>

<defn> ::=
  | FUNCTION ID LPAREN <params> EQ <expr>

<params> ::=
  | RPAREN
  | ID <rest-params>

<rest-params> ::=
  | RPAREN
  | COMMA ID <rest-params>

<expr> ::=
  | IF <expr> THEN <expr> ELSE <expr>
  | LET ID EQ <expr> IN <expr>
  | <seq>

<seq> ::=
  | <infix1> <rest-seq>

<rest-seq> ::=
  | epsilon
  | SEMICOLON <infix1> <rest-seq>

<infix1> ::=
  | <infix2> <infix1'>

<infix1'> ::=
  | epsilon
  | EQ <infix1>
  | LT <infix1>

<infix2> ::=
  | <term> <infix2'>

<infix2'> ::=
  | epsilon
  | PLUS <infix2>
  | MINUS <infix2>

<term> ::=
  | ID
  | ID LPAREN <args>
  | NUM
  | LPAREN <expr> RPAREN

<args> ::=
  | RPAREN
  | <expr> <rest-args>

<rest-args> ::=
  | RPAREN
  | COMMA <expr> <rest-args>
```

## Testing

### Tests will not be graded

_Except for the specific example we require in Task 1.1, we will **NOT** be
grading your tests for this homework._

However, it will still be that case that when you submit your implementation to
Gradescope (to the assignment `hw7`), your suite of examples in the `examples/`
directory will be run against the reference interpreter and compiler. If the
reference implementation fails on any of your examples, Gradescope will show you
how its output differed from the expected output of your example (if you wrote a
`.out` file for it).

You can do this as many times as you want. We encourage you to use this option
to develop a good set of examples *before* you start working on your parser!

### Support for `.mlb` files

We've extended the testing framework to support programs in the new syntax. You
can write MLB-syntax examples either by:

- Putting `.mlb` files in the `examples` directory
- Writing a _tab_-separated `examples/mlb-examples.tsv` file. This file is
  tab-separated instead of comma-separated because, unlike our Lisp-like syntax,
  MLB uses commas pretty extensively.

Note that in general, the interpreter and the compiler will give the same result
on all of your programs! You'll probably want to write `.out` files (or include
expected output in the `.tsv` file) to make sure your parser is actually
working. These work exactly the same as with `.lisp` files.

On this homework more than on previous ones, it may be useful to run your
functions in an OCaml shell. You can do that by running `dune utop` from the
`hw7` directory, then entering, for example:

```
> open Mlb_syntax;;
> parse "1 + 3";;
```

## 1. Writing an MLB program (1 subtask)

To start, complete the following task to familiarize yourself with the MLB
syntax. _Note that this task WILL be graded!_

**Task 1.1:** In the file `examples/task1.mlb`, write a valid program in the MLB
syntax that defines a `sort` function that sorts a list of integers.

_Hint:_ Recall that we represent lists as nested `pair`s with a `nil` at the
end. For example, the list `[1, 2]` would be written as `pair(1, pair(2, nil))`
in the MLB syntax.

_Hint:_ It may be helpful to define a `sorted_insert` helper function that takes
in an integer `n` and a sorted list `xs` and returns `xs` with `n` inserted into
it at a location that maintains the sorted order.

## 2. Parsing MLB syntax (1 subtask)

Now that you are familiar with MLB syntax, it's time to write a parser for the
language!

We provide you with a tokenizer in `mlb_syntax/tokenizer.ml`; it should not be
necessary to change it, but you are free to do so if you wish. Instead, you'll
be working on the parser in the file `mlb_syntax/parser.ml`.

The AST you'll produce is defined in `ast/ast.ml`; it's quite similar to the AST
we defined in class. A few hints for mapping the MLB grammar to the AST:

- The `<seq>` non-terminal should correspond to `Do` if and only if you end up
  parsing more than one semicolon-separated expression.
- The `<infix1>` and `<infix2>` non-terminals can produce `Eq`, `Lt`, `Plus`,
  and `Minus` primitive calls.
- The first `ID` case in the `<term>` non-terminal should produce `True` on the
  identifier `true`, `False` on the identifier `false`, `Nil` on the identifier
  `nil`, and `Var id` on other identifiers.
- The second `ID` case in the `<term>` non-terminal should produce either `Call`
  or a primitive. You can use the provided `call_or_prim` function to decide
  which one to produce.

**Task 2.1:** In the file `mlb_syntax/parser.ml`, finish the implementation of
the `parse` function by implementing `parse_defns` and `parse_expr`, which parse
MLB definitions and expressions respectively.

_Hint:_ We recommend writing a top-down parser like the ones we developed in
class:

- Write one function per non-terminal (with the exception of primed cases---for
  instance, you can handle `infix1'` inside the function for `infix1`).
- Return a value (usually, but not always, an expression) and a list of tokens
  from each function.
- Decide which production rule to use by examining the front of the token list.

You may wish to review `handparser.ml` and `handparser2.ml` from class, along
with the class sessions covering how they work.  Make sure you remember how
you're using the returned token list!

_Hint:_ The MLB grammar does not have any left-recursion or left-ambiguity
except for in `<term>`, where you can handle the two `ID` cases with careful
pattern matching.

_Hint_: You shouldn't need to change the top-level `parse_program` function, but
you'll need to fill in the bodies of `parse_defns` and `parse_expr` and add
additional non-terminal parsing functions.

_Hint:_ We've provided one other helper function: `consume_token`. This function
checks to see that the head of a token list is what you want it to be, returning
the tail of the list if it is and raising an error otherwise.

## Extra credit: associativity (1 extra credit subtask worth 10%)

With the grammar specified above, the MLB expression
`2 + 3 + 4`
will parse to something like (in s-expression syntax)
`(+ 2 (+ 3 4)`.

This is a little different from what we'd usually expect: addition is generally
defined to left-associative. Most languages parse that same expression to
`(+ (+ 2 3) 4)`.

For addition, this doesn't really matter---since it's associative, those
expressions evaluate to the same thing. This can lead to weird behavior on
subtraction, though. The expression
```
10 - 3 - 2
```
should probably evaluate to `5`, but if you implement the grammar as specified
above it will instead evaluate to `9` (i.e., `10 - (3 - 2)`).

**Extra Credit Task:** If you finish your parser early, try to fix this!
Specifically, modify your parser so that `+` and `-` associate to the left.

_Hint:_ There's more than one way to achieve this! One way to get started would
be to take a look at the `<seq>` and `<rest-seq>` non-terminals, which are used
to get a list of expressions. Could you do something similar to get a list of
terms, then transform the list into an AST of the correct shape?

_This task is worth 10% additional credit on this homework assignment._
