This directory contains shared code for the homework assignments.

- `s_exp` is a miniatuare S-expression parsing library
- `assemble.ml` is a wrapper around `nasm` that will assemble the output of our
  compiler
- `cli.ml` provides helper functions for the command-line interface of our
  interpreter and compiler
- `difftest.ml` is a small differential testing library
- `directive.ml` provides the x86 assmebly directives that are recognized by
  `assemble.ml`
- `error.ml` provides the `Stuck` exception (and a pretty-printer for it)
- `infra.ml` allows for per-homework infrastructure configuration
