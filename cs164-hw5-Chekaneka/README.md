# Homework 5: Fun with Files

_**Note:** This is a 1-week assignment (due 1 week after release)._

## Introduction

In this homework, you'll implement string support and file handling. You'll get
more practice dealing with data on the heap and learn how to extend your
compiler's functionality via the C runtime.

At the end of this homework assignment, your interpreter and compiler should
support the following grammar (we've highlighted what you'll be adding):


```diff
<expr> ::= <num>
         | <id>
+        | <string>
         | true
         | false
+        | stdin
+        | stdout
         | (<z-prim>)
         | (<un_prim> <expr>)
         | (<bin_prim> <expr> <expr>)
         | (if <expr> <expr> <expr>)
         | (let ((<id> <expr>)) <expr>)
         | (do <expr> <expr> ...)

<z-prim> ::= read-num | newline

<un_prim> ::= add1
            | sub1
            | zero?
            | num?
            | not
            | pair?
            | left
            | right
            | print
+           | open-in
+           | open-out
+           | close-in
+           | close-out

<bin_prim> ::= +
             | -
             | =
             | <
             | pair
+            | input
+            | output

```

## Testing

### Tests will not be graded

_We will **NOT** be grading your tests for this homework._

However, it will still be that case that when you submit your implementation to
Gradescope (to the assignment `hw5`), your suite of examples in the `examples/`
directory will be run against the reference interpreter and compiler. If the
reference implementation fails on any of your examples, Gradescope will show you
how its output differed from the expected output of your example (if you wrote a
`.out` file for it).

You can do this as many times as you want. We encourage you to use this option
to develop a good set of examples *before* you start working on your interpreter
and compiler!

### Providing program input

Your programs can now read from standard input, using both the `read-num`
operator defined in class and the `input` operator you'll write on this
assignment. For testing, you should provide inputs by writing `.in` files for
each `.lisp` file that expects an input. For example, if we defined a program
like this in `examples/read-num.lisp`:

```
(print (pair (read-num) (pair (read-num) (read-num))))
```

We could define its input in `examples/read-num.in`:

```
8
13
21
```

The testing system will provide this as the input to both the interpreter and
the compiler.

Additionally, the testing framework handles rows in `examples/examples.csv` of
the form

```csv
<PROGRAM>,<INPUT1>,<OUTPUT1>,<INPUT2>,<OUTPUT2>,...
```

For instance, to test a program that echoes single characters read from `stdin`
to `stdout`, you could write:

```csv
(output stdout (input stdin 1)), a, a, b, b
```

### The scratch directory

When testing reading/writing to files, it can be easy for state to get mixed up
between tests (e.g. one test creates a file and writes some things to it, while
the test that runs after it expects the file not to exist).

Therefore, we've set this homework up such that when you run `dune runtest -f`,
your code will run in a directory that contains a subdirectory called `tmp`.
(As an example path, you could have some tests that read and write to the path
`tmp/hello.txt`.) Reading and writing files from `tmp` directory will work both
locally and on Gradescope.

This is a great place to read/write files in your tests, but **please do not
store anything important in this directory---it WILL get erased on each test
run!** (As a consequence, you will likely not be able to see the actual files
that get created and accessed when you use the testing framework.)

If you want to see the files that your program reads from and writes to, we
recommend running your program manually in the same manner as previous
homeworks (i.e., using `dune exec`). Since your tests will likely be writing
from paths like `tmp/hello.txt`, we recommend creating a `tmp` folder in
whatever directory you run your code manually from.


## 1. Strings (4 subtasks)

In this task, you will implement support for strings. For now, this just means
adding support for string literals (i.e., s-expressions built with the `Str`
constructor). Here are some pointers:

- String literals are sequences of characters enclosed in double-quotes. Strings
  should be displayed in the same double-quote-enclosed representation.
- Strings may contain characters with special meaning (namely, newlines and
  double-quotes). When displaying strings, these should be escaped as `\n` and
  `\"` to ensure the resulting expression is well-formed. For instance, a string
  containing only a double-quote should be displayed as `"\""` and not `"""`.
  You do *not* need to support special characters besides quote and newline.

**Task 1.1 (ungraded):** Write tests for strings in the `examples/` directory.

**Task 1.2:** Add support for strings to the interpreter.

_Hint:_ Add a constructor to `value` and extend the interpreter's
`display_value` function to display strings (use `String.escaped` to escape
special characters).

**Task 1.3:** Add support for strings to the compiler. We'll represent strings
like C does: `NUL`-terminated sequences of characters. The runtime value for a
string should be a pointer to the first character of the sequence tagged with
`0b011`.

_Hint:_ Since we're only concerned with string literals for now, you can
implement string support using `DqString`, which will embed a string literal
into the compiled program as data. As with `DqLabel`, you should be sure that
program execution never runs this directive---it's just data, not instructions.

_Hint:_ String literals embedded in this way must be placed at 8-byte aligned
addresses, since you will need to tag the pointers with `0b011`. You can use
the `Align` directive to ensure the next directive will be aligned properly.

_Hint:_ The ASCII character `NUL` has ASCII value `0` and is written in C as
`\0`. The code we provide for you in `./asm/directive.ml` automatically adds
the `NUL` terminator to the argument of `DqString` when writing to an assembly
file.

**Task 1.4:** Extend the runtime with support for displaying strings. In order
to properly escape newlines and double-quotes, implement this as a loop over the
string's characters, and check if each needs to be escaped.

## 2. File I/O using channels (6 subtasks)

Next you will add a miniature version of OCaml's channel-based I/O to your
language.

### Channels

First, you'll need to add support for channel types. Here are some pointers:

- Channels can be either input channels or output channels. Input channels can
  be read from, and output channels can be written to. 

- The symbols `stdin` and `stdout` refer to the program's input and output.
  `stdin` is an input channel, and `stdout` is an output channel.

- Channels should be printed as `<in-channel>` or `<out-channel>`.

**Task 2.1 (ungraded):** Write tests for channels in the `examples/` directory.

**Task 2.2:** In the interpreter, implement input and output channels with the
built-in OCaml types `in_channel` and `out_channel`. In the top-level
environment, the symbols `stdin` and `stdout` should be initialized to
`!input_channel` and `!output_channel`, respectively (this is necessary to make
tests work).

**Task 2.3:** In the compiler, implement both types of channels with the same
mask, `0b111111111`. Input channels should have tag `0b011111111`, and output
channels should have tag `0b001111111`. `stdin` should be represented at runtime
as `0` shifted left and tagged with the input-channel tag; `stdout` should be
represented as `1` shifted left and tagged with the output channel tag. You will
also need to update the runtime to accommodate this addition.

### File I/O

Now you will implement some primitive I/O operations to open, close, read from,
and write to channels:

- `(open-in filename)` takes in a string representing a filename and opens it
  as an input channel, returning the channel. You do not need to handle the
  case in which the file named by `filename` does not exist.
- `(open-out filename)` takes in a string representing a filename and opens it
  as an output channel, returning the channel.
- `(close-in ch)` takes in an input channel and closes it, returning `true`.
- `(close-out ch)` takes in an output channel and closes it, returning `true`.
- `(input ch n)` reads `n` bytes from the input channel `ch`, returning a string
  of those bytes with a `NUL` terminator appended at the end. This primitive
  should fail if `n < 0`.  We will not test on cases where `n >` the size of the input.
- `(output ch s)` writes the string `s` with a `NUL` terminator appended at the
  end to the output channel `ch`, returning `true`.

Closing `stdin` or `stdout` is undefined behavior.

**Task 2.4 (ungraded):** Write tests for the six I/O primitives in the `examples/`
directory.

**Task 2.5:** Implement the six I/O primitives in the interpreter.

_Hint:_ Here are some tips for implementing each primitive in the interpreter.
Each of the functions below is defined in the
[OCaml `Stdlib` module](https://ocaml.org/api/Stdlib.html).

- `open-in` should be implemented using `open_in`.
- `open-out` should be implemented using `open_out`.
- `close-in` should be implemented using `close_in`.
- `close-out` should be implemented using `close_out`.
- `input` should be implemented using `really_input` (you can use something like
  `Bytes.make n '\000'` to create a buffer of the appropriate size).
- `output` should be implemented using `output_string`.

**Task 2.6:** Implement the six I/O primitives in the compiler. All of these
operations will be implemented with C functions that you add to the runtime. You
should define a C function for each operation (except for `close-in` and
`close-out`, which should be implemented identically in the runtime and can use
the same C function). **Like Homework 4, the assembly that your compiler
generates is required to do error checking; this means that if one of the
primitive I/O operations is applied to an argument of an unexpected type, the
program should jump to the `lisp_error` function in C.**

_Hint:_ C functions assume their first argument is stored in the register
`Rdi`, their second argument is stored in the register `Rsi`, and their third
argument is stored in the register `Rdx`.

_Hint:_ Here are some tips for implementing each primitive in the runtime:

- Your functions for `open-in` and `open-out` should use the `open_for_reading`
  and `open_for_writing` helper functions we have provided in `runtime.c`. Both
  functions return a file descriptor as an integer. Turn this file descriptor
  into a channel by shifting it and tagging it with the correct channel tag.
- Your function for `close-in` and `close-out` should use the `close` C
  function, passing in the file descriptor obtained from `open`. Input and
  output channels can be handled exactly the same.
- Your function for `input` should use the `read_all` helper function we've
  provided in `runtime.c`; this helper function takes care of reading the
  correct number of bytes, adding a `NUL` terminator, and handling errors. Here
  are some tips:
    - `read_all` reads into a buffer, so you'll need to pass in a pointer to the
      Lisp heap (which means you'll have to pass the heap pointer as an argument
      to your function).
    - After you call `read_all` you'll need to adjust your heap pointer to make
      sure that subsequent allocations don't overwrite this string.
    - You'll also need to make sure that the heap pointer remains a multiple 
      of 8. We recommend doing this by returning the heap adjustment from your C
      function as an integer (taking care to make sure it's a multiple of 8),
      but there are other ways of doing it.
- `output` should be implemented using the `write_all` helper function provided
  in `runtime.c`.
