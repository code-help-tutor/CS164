# Homework 4: Error Handling and the Heap

_**Note:** This is a 1-week assignment (due 1 week after release)._

## Introduction

In this homework, you'll implement lists in two ways: first using pairs, then
using arrays. You'll get practice handling runtime errors and dealing with data
on the heap.

At the end of this homework assignment, your interpreter and compiler should
support the following grammar (we've highlighted what you'll be adding):

```diff
<expr>
  ::= <num>
    | <id>
    | true
    | false
    | ()
    | (<unary-prim> <expr>)
    | (<binary-prim> <expr> <expr>)
    | (<trinary-prim> <expr> <expr> <expr>)
    | (if <expr> <expr> <expr>)
    | (let ((<id> <expr>)) <expr>)
    | (do <expr> <expr> ...)
             

<unary-prim>
  ::= add1
    | sub1
    | zero?
    | num?
    | not
    | pair?
    | left
    | right
+   | list?
+   | vector?
+   | vector-length


<binary-prim>
  ::= +
    | -
    | =
    | <
    | pair
+   | vector
+   | vector-get


<trinary-prim>
+ ::= vector-set
```

## Testing

### Tests will not be graded

_We will **NOT** be grading your tests for this homework._

However, it will still be the case that when you submit your implementation to
Gradescope (to the assignment `hw4`), your suite of examples in the `examples/`
directory will be run against the reference interpreter and compiler. If the
reference implementation fails on any of your examples, Gradescope will show you
how its output differed from the expected output of your example if you provided
one.

You can do this as many times as you want. We encourage you to use this option
to develop a good set of examples *before* you start working on your interpreter
and compiler!

### Running tests

You can use `dune runtest -f` to run all your tests in the `examples/`
directory. As before, the testing framework supports both `.lisp`/`.out` files
and the `examples/examples.csv` file.

## Some tips

### Running the compiler and the interpreter manually

In addition to using `dune runtest -f`, you can manually run the interpreter
and compiler on input files.

To run the interpreter on a file, execute the following command:

```
dune exec bin/interp.exe -- <file.lisp>
```

To run the compiler on a file, execute the following command:

```
dune exec bin/compile.exe -- <file.lisp> output
```

The resulting `.s` file (containing assembly code) and `.exe` file (an
executable) will be in the `output/` directory. You can then run the executable
with:

```
./output/<file.lisp>.exe
```

You can also tell the compiler to run the executable immediately after compiling
by adding `-r`, e.g.:

```
dune exec bin/compile.exe -- <file.lisp> output -r
```

### Inspecting and debugging assembly

If you run the compiler on a `.lisp` file (as described above), you can take a
look at the emitted assembly by looking in the `.s` file in the `output`
directory. This is a really useful way to understand how your compiler is
working as a whole and to debug any issues you may be facing.

You can also take a look at `_build/default/test/test_output/*.s` to take a look
at the assembly for your test cases, including those in `examples/examples.csv`.

For a more interactive way to debug assembly, check out
Section 4 on the course website!

### Manually assembling `.s` files

If it ever happens that the assembly emitted by your compiler is invalid and
you're not sure why, you can try manually compiling a test file (see above),
then manually running `nasm` on the `.s` file in the `output` directory:

```bash
nasm <input-filename>.s -o <output-filename>.o -f elf64
```

This may give you more helpful error messages than the automated testing
infrastructure.

## 1. Lists (5 subtasks)

As we saw in class, lists can be implemented using pairs. In fact, this is how
lists are generally implemented in Scheme and other Lisp-like languages. A list
is either:

- The empty list, for which we used `false` in class.
- A pair where the second element is a list.

Instead of using `false` to signal the empty list, Scheme includes a special
value `()` (pronounced "nil").

**Task 1.1:** Add support for `()` to the interpreter.

**Task 1.2:** Add support for `()` to the compiler. Use `0b11111111` as the
runtime representation of `()`.

_Hint:_ You'll need to modify the runtime to properly display nil values.

Now we can build lists using `pair` and `()`. Here are a few such lists:

- `()`
- `(pair 1 ())`
- `(pair 1 (pair 2 ()))`
- `(pair (pair 1 2) ())`

We can now define a primitive `(list? e)` that evaluates to `true` when its
argument is a list and `false` otherwise.

**Task 1.3 (ungraded):** Write tests for the `list?` primitive in the
`examples/` directory.

**Task 1.4:** Add support for `list?` to the interpreter.

_Hint:_ You can use a recursive helper function to implement `list?` in the
interpreter.

**Task 1.5:** Add support for `list?` to the compiler.

_Hint:_ You can generate a loop to execute this primitive; to do so, you'll need
to define a label and repeatedly jump back to that label.

## 2. Vectors (3 subtasks)

We can also implement lists using arrays. In Scheme, array-backed lists are
called _vectors_. In this task, you'll implement the following five vector
primitives:

- `(vector n e)`, which creates a vector of length `n` where all of the elements
  are `e`.
    - **Precondition:** `n` evaluates to a positive integer.
- `(vector? e)` returns `true` if `e` is a vector and `false` otherwise.
    - **Precondition:** none.
- `(vector-length v)` returns the length of the vector `v`.
    - **Precondition:** `v` is a vector.
- `(vector-get v n)` returns the element of the vector `v` at (0-based) index
  `n`.
    - **Precondition:** `v` is a vector and `n` evaluatase to a non-negative
      integer less than the length of `v`.
- `(vector-set v n e)` sets the element at index `n` of the vector `v` to `e`
  and evaluates to the vector.
    - **Precondition:** `v` is a vector and `n` evaluates to a non-negative
      integer less than the length of `v`.

### An important note about error handling

For this assignment, unlike previous assignments, **you are expected to
implement error-handling in the compiler.**

An expression that does not meet its corresponding precondition **must** result
in a runtime error. (This is sometimes what is meant by a language being
"safe.") Here's what your code should do when evaluating an expression that does
not meet its precondition:

- _In the interpreter_, you must throw an exception. Any exception will do; we
    will not check the exception type nor its contents.

- _In the compiler_, you must jump to the `lisp_error` symbol, defined in
  `lib/runtime/runtime.c`. Take a look at `ensure_num` and `ensure_pair` for
  some examples of the error handling we've implemented so far.

  _Hint:_ C functions assume their first argument is stored in the register
  `Rdi`, and the `dq` directive lets you embed bytes into the location in memory
  where the instruction is stored.

### Displaying vector outputs

Vectors should be displayed as space-delimited lists of their values enclosed
in square brackets. For instance, here are some simple vectors of
numbers:

- `[1]`
- `[1 2 3]`

Note that this syntax is not supported in our grammar, so you cannot use `[1 1]`
as shorthand for `(vector 2 1)`, for example.

**Task 2.1 (ungraded):** Write tests for the five vector primitives in the
`examples/` directory.

### Implementing vectors

**Task 2.2:** Add support for vectors and the five vector primitives to the
interpreter.  In the interpreter, you should implement vectors using OCaml's
built-in `array` type and the functions in the `Array` module.

**Task 2.3:** Add support for vectors and the five vector primitives to the
compiler.  In the compiler, you should implement vectors on the heap: A vector
of length `n` should occupy `n+1` 8-byte cells, where the first cell should be
used to store its length. Use the three-bit tag `0b101` for vector values.

_Hint:_ In `compile.ml`, look at where we call `compile_binary_primitive` to see that the second argument is held in `Rax`, and the first is on the stack.  See where we call `compile_trinary_primitive` to see where we store arguments for primitives that accept three arguments.

_Hint:_ You may need to make use of an additional register in order to implement
some of the vector primitives. If you do, you can use `R9` in addition to the
usual `Rax` and `R8`.

_Hint:_ You'll need to modify the runtime to properly display vector values.
In order to do so, it will likely be helpful to cast a vector's pointer to the
heap into a C pointer to a `uint64_t` and then use
[pointer arithmetic](https://www.tutorialspoint.com/cprogramming/c_pointer_arithmetic.htm)
to access each of the values in the vector.  Recall how we handled pairs in class.

We will not test on vectors over size 100, and we will not test display of cyclic vectors.
