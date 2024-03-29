# Homework 8: Optimizations

In this homework, you'll implement some optimizations in your compiler. You'll
also come up with benchmark programs and see how well your optimizations do on a
collaboratively-developed benchmark suite.

You'll implement the following optimizations (all of which we
discussed in class):

- Constant propagation
- Inlining
- Common subexpression elimination

In order to make inlining and common subexpression elimination easier to
implement, you'll also write an AST pass (i.e., a function of type `program ->
program`) to make sure all variable names are globally unique.

_Note:_ Task 1 (as defined below) will be due **1 WEEK BEFORE** the rest of the
tasks. It has a separate assignment on Gradescope, `hw8-benchmarks`.

_Note:_ There are no "subtasks" in this assignment. Each numbered section has
exactly one task to go with it: Task 1, Task 2, Task 3a, Task 3b, and Task 3c.

### Starter code

The starter code is the same as for Homework 7, but without support for MLB
syntax. In particular, lambda expressions and function pointers are not
supported.

You will write all your optimizations in the file `lib/optimize.ml`. **You will
not need to modify any other files.**

### Testing

**There is no reference solution for this homework.** This is because everyone's
optimizations will be slightly different!

That being said, we still encourage you to write tests using the `OUnit2`
framework we used for Homework 1. For a refresher on how that works, check out
Section 2 on the course website. In any case, we will *not*
be grading any tests you write for this assignment _except for_ the benchmarks
that you explicitly submit in Task 1.  It's up to you what kinds of tests you write!

### Running the optimizer and compiler

You can run the compiler with specific optimization passes enabled using the
`bin/compile.exe` executable, by passing the `-p` argument one or more
times. For instance:

```sh
dune exec bin/compile.exe -- examples/ex1.lisp output -r -p propagate-constants -p uniquify-variables -p inline
```

will execute the compiler with constant propagation, globally unique names, and
inlining enabled. You can also use this to execute an optimization more than
once—for instance, doing constant propagation, then inlining, then constant
propagation again.

You can also pass `-o` instead to enable all optimizations.

## 1. Benchmarks (due 1 week early)

We've set up a
[repository for benchmarks](https://github.com/berkeley-cs164-2023/hw8-benchmarks)
for this homework assignment, as well as a script that you can use to see how
much your optimizations improve performance on the various benchmarks.

_Note:_ We will **not** be grading your optimizations based on a competition of
any kind with the benchmarks submitted. Instead, we will just be grading your
optimizations on the basis of whether or not they behave as prescribed (based
on our own internal tests).

**Task 1 (DUE 1 WEEK EARLY):** In the Gradescope assignment `hw8-benchmarks`,
upload _at least three_ interesting benchmark programs.  These must be programs that the Homework 8 starter code can actually run!  For instance, since the Homework 8 language doesn't include variadic functions or let expressions that bind multiple variables, your benchmarks should not use these features.

We will periodically take some of these submissions from Gradescope and upload them to
the *public* benchmarking repository, so please **DO NOT INCLUDE ANY IDENTIFYING
INFORMATION IN YOUR BENCHMARKS** (e.g. name, email, date of birth, social
security number, password...).

This also means that if you're interested in testing your optimizations on 
benchmarks contributed by others, you should periodically do a `git pull` on the
`hw8-benchmarks` repo, to get the latest benchmark suite!  This is totally optional.
Again, the grade for your optimizations will not have anything to do with the
benchmarks submitted by your peers.  We have our own set of tests that we'll use
to evaluate your optimizations.  But if you want access to benchmarks that your
peers have created, just for your own purposes of assessing your optimizations,
pulling from `hw8-benchmarks`is the way to get a whole suite!

## 2. Globablly unique names

Many optimizations can benefit from a pass that ensures all names are globally
unique.

**Task 2:** Implement this pass using `gensym`.

This pass should be run before inlining and common subexpression elimination,
and both of those optimizations can then assume globally-unique names (this is
an exception to the usual principle that the order of optimizations shouldn't
matter for correctness). The `validate_passes` function in `optimize.ml` ensures
that this optimization is executed before inlining and common subexpression
elimination.

_Hint:_ You should implement this optimization before implementing
inlining or common subexpression elimination!

## 3a. Constant propagation

Constant propagation is a crucial optimization in which as much computation as
possible is done at _compile time_ instead of at _run time_.

We implemented a sketch of a simple version of constant propagation in class.

**Task 3a:** Implement constant propagation, which should support:

- Replacing the primitive operations `add1`, `sub1`, `plus`, `minus`, `eq`, and
  `lt` with their statically-determined result when possible;
- Replacing `let`-bound names with constant boolean or number values when
  possible;
- Eliminating `if` expressions where the test expression's value can be
  statically determined.

**Optional extension (for no additional credit):** You can also implement
re-associating binary operations (possibly in a separate pass) to find
opportunities for constant propagation. For instance, consider the expression

```scheme
(+ 5 (+ 2 (read-num)))
```

This expression won't be modified by the constant propagation algorithm
described above, but with re-association it could be optimized to

```scheme
(+ 7 (read-num))
```

## 3b. Inlining

In this task, you will implement function inlining for function definitions.

In general, inlining functions can be tricky because of variable names; consider
the following code:

```scheme
(define (f x y) (+ x y))

(let ((x 2))
  (let ((y 3))
    (f y x)))
```

A naive inlining implementation might result in code like this:

```scheme
(let ((x 2))
  (let ((y 3))
    (let ((x y))
      (let ((y x))
        (+ x y)))))
```

This expression, however, is not equivalent!

This problem can be solved by adding a simultaneous binding form like the one
you implemented in Homework 3. _It can also be solved by just ensuring that all
variable and parameter names are globally unique._

You should implement a heuristic for when to inline a given function. This
heuristic should involve both (1) the number of static call sites and (2) the
size of the function body. For example, you could multiply some measure of the
size of the function body by the number of call sites and see if this exceeds
some target threshold. We recommend implementing your inliner as follows:

1. Find a function to inline. This function should satisfy your heuristics and
   be a *leaf* function, i.e., one that doesn't contain any function calls.
2. Inline the function, and remove the function's definition.
3. Go back to Step 1. Now that you've inlined a function, more functions may now
   be leaf functions.

This process will never inline recursive functions, including mutually-recursive
functions.

**Task 3b:** Implement function inlining for function definitions. Please
describe your heuristic in a comment at the **VERY TOP** of the
`optimizations.ml` file.

## 3c. Common subexpression elimination

In this task, you will implement common subexpression elimination.

This optimization pass should find common subexpressions, add names for those
subexpressions, and replace the subexpressions with variable references.

This optimization is more challenging to implement than inlining is. Our
suggested approach is to:

- Optimize each definition (including the top-level program body) independently.
  For each definition:
  - Make a list of *all* of the subexpressions in the program that don't include
    calls to `(read-num)` or `(print)`
  - Find any such subexpressions that occur more than once
  - Pick a new variable name for each expression that occurs more than once
  - Replace each subexpression with this variable name
  - Add a let-binding for each common subexpression

The most difficult part of this process is determining where to put the new
let-binding. Consider replacing the (identical) subexpressions `e1`, `e2`, and
`e3` with the variable `x`. You'll need to find the lowest common ancestor `e`
of `e1`, `e2`, and `e3`, then replace it with

```scheme
(let ((x e1)) e)
```

In order to find this lowest common ancestor, it will likely be useful to track
the "path" to a given expression: how to get to that subexpressson from the top
level of the given definition. How exactly you do this is up to you.

**Task 3c:** Implement common subexpression elimination.
