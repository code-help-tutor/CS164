# Homework 6: `apply` and Variadic Functions

In this homework, you'll extend the function calls we developed in class with
two additional features:

-  **The `apply` operation**, which takes in the name of a function and a list
   of arguments and calls the functions on those arguments. Lists are defined as
   in Homework 4: either nil (i.e., `()`) or a pair where there second element
   is a list. Thus, we may use `apply` as follows:

   ```
   (define (f x y) (+ x y))
   (print (apply f (pair 1 (pair 2 ()))))
   ```

   The above program should print `3`.

-  **Variadic functions**, which can take additional arguments beyond those
   given static names. The additional arguments are put into a list that the
   function can access. Here's an example of a program with a variadic function:
 
   ```
   (define (f x xs ...) (pair x xs))
   (print (f 1 2 3 4))
   ```

   The above program should print `(pair 1 (pair 2 (pair 3 (pair 4 ()))))`.

A function's *arity* is the number of arguments it takes. (Accordingly, variadic
functions are also called "variable-arity" functions.) In class, we implemented
static arity checking: since we know at compile-time how many arguments we're
passing when calling a function, we can throw a compile-time error when the
number of arguments doesn't match the function's arity.  However, in order to
correctly implement `apply`, we'll need to switch to *dynamic* arity checking,
checking the number of arguments at runtime.

At the end of this homework assignment, your interpreter and compiler should
support the following grammar (we've highlighted what you'll be adding):

```diff
<program>
  ::= <defn> ... <expr>

<defn>
  ::= (define (<id> <id> ...) <expr>)
+   | (define (<id> <id> ... <id> "...") <expr>)

<expr>
  ::= <num>
    | <id>
    | true
    | false
    | ()
    | (<z-prim>)
    | (<unary-prim> <expr>)
    | (<binary-prim> <expr> <expr>)
    | (<id> <expr> ...)
+   | (apply <id> <expr>)
    | (if <expr> <expr> <expr>)
    | (let ((<id> <expr>)) <expr>)
    | (do <expr> <expr> ...)

<z-prim>
  ::= read-num
    | newline

<unary-prim>
  ::= add1
    | sub1
    | zero?
    | num?
    | not
    | pair?
    | empty?
    | left
    | right
    | print

<binary-prim>
  ::= +
    | -
    | =
    | <
    | pair

```

## Testing

### Tests will not be graded

_We will **NOT** be grading your tests for this homework._

However, it will still be that case that when you submit your implementation to
Gradescope (to the assignment `hw6`), your suite of examples in the `examples/`
directory will be run against the reference interpreter and compiler. If the
reference implementation fails on any of your examples, Gradescope will show you
how its output differed from the expected output of your example (if you wrote a
`.out` file for it).

You can do this as many times as you want. We encourage you to use this option
to develop a good set of examples *before* you start working on your interpreter
and compiler!

### Evaluating a list of s-expressions

The testing framework now supports evaluating multiple expressions where all but
the last expression is a definition, as per the grammar above.

For example, you could make a file `examples/test.lisp` consisting of the
following content:
```
(define (f x y) (+ x y))
(print (apply f (pair 1 (pair 2 ()))))
```
The corresponding valid `examples/test.out` file would then consist of the
following content:
```
3
```

You can also use multiple expressions in the `examples/examples.csv` file. The
above example would be encoded as a row in this file as follows:
```
(define (f x y) (+ x y)) (print (apply f (pair 1 (pair 2 ())))), 3
```

## General advice

### Starter code

The starting language for this assignment includes nil (`()`) from Homework 4.
It also includes a unary operator `empty?` that returns `true` if its argument
is `()` and `false` otherwise.

### Implementing the compiler

You will need to implement some of the new functionality in this homework by
writing somewhat larger functions using x86 assembly directives in the compiler.
Here are some tips for doing so:

- The `R8`, `R9`, `R10`, and `R11` registers are all available to store
  temporary data.
- It may be helpful to write `(* OCaml comments *)` in your list of assembly
  directives that describe, at a high level, what the assembly is doing.

## 1. `apply` (4 subtasks)

**Task 1.1 (ungraded):** Write tests for the `apply` operation in the
`examples/` directory.

**Task 1.2:** Implement `apply` in the interpreter, including dynamic arity
checking. You should do so by evaluating its second argument, then traversing
the list and adding each element to the environment with the corresponding
argument name. **You should raise a runtime exception (of any kind) in the
following cases:**
- The second argument is not a list.
- The second argument is a list but does not contain the right number of
  arguments for the function being applied. (This is the "dynamic arity check"
  for the interpreter.)

**Task 1.3:** Implement `apply` in the compiler, NOT including the dynamic arity
check. You should do so by traversing its second argument, adding each to the
stack where the function arguments would go. **You should jump to the C function
`lisp_error` if the second argument is not a list.**

Now that we have `apply`, we can't guarantee at compile-time that a function
will be called with the right number of arguments. So, we'll need to modify our
functions to check this. To do this, functions should take an additional first
"argument" on the stack which represents the number of actual arguments passed
in. Each function is then responsible for making sure that this value is equal
to the number of arguments it expects.

**Task 1.4:** Implement dynamic arity checking for `apply` in the compiler by
modifying the code for `apply` and regular function calls to pass in this extra
"argument." Since you're doing this, you can now remove the static error
checking from regular function calls.

## 2. Variadic functions (3 subtasks)

Variadic functions in our language look like this:

```
(define (add args ...)
  (if (empty? args)
    0
    (+ (left args) (apply add (right args)))))
```

The `...` (which corresponds to the `Dots` constructor of our `s_exp` type)
indicates that the function is variadic. The last named parameter (called the
"rest" parameter) gets a list of all of the "extra" arguments passed
in.

Consider the following program:

```
(define (f a b c ...) (pair a (pair b c)))
(f 1 2 3 4 5)
```

When `f`'s body is executed, `a` is `1`, `b` is `2`, and `c` is
`(pair 3 (pair 4 (pair 5 ())))` (i.e., a list containing 3, 4, and 5).

If a variadic function has `N` regular parameters in addition to the rest
parameter, it is an error to call it with less than `N` arguments. If it is
called with exactly `N` arguments, the rest parameter will be bound to the empty
list.

**Task 2.1 (ungraded):** Write tests for variadic functions in the `examples/`
directory.

We have extended the `defn` type shown in class with an extra `rest` field,
which is a `string option`. This field will be `None` for non-variadic
functions. For variadic functions, it will be `Some "<name of rest
parameter>"`. The `defns_and_body` helper function has been extended to support
variadic functions.

**Task 2.2:** Add support for variadic functions to the interpreter. Do this by
adding a binding to the environment for the rest parameter.

_Hint:_ You'll need to convert an OCaml list of arguments to a Lisp list.

**Task 2.3:** Add support for variadic functions to the compiler.

_Hint:_ Here are some pointers for adding variadic functions to the compiler:

-  We recommend calling variadic functions just like regular functions:
   push all of the arguments onto the stack. In other words, the code to call a
   function shouldn't need to change to support variadic functions.
-  Once a variadic function is called, it should take care of copying any extra
   arguments from the stack to a freshly-allocated list. You should have already
   implemented dynamic arity checking in **Task 1.4**, so you'll be able to tell
   how many of these extra arguments there are.
-  Once these arguments have been copied from the stack into a list, put a
   pointer to this list (tagged as usual) onto the stack as the `N+1`-th
   argument; the rest parameter should point at this index in the symbol table.

_Hint:_ You may find the `Symtab.cardinal` function helpful; it returns the
number of bindings in a symbol table.
