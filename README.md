# rules_vhdl

[![CI](https://github.com/hw-bzl/bazel_rules_vhdl/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/hw-bzl/bazel_rules_vhdl/actions/workflows/ci.yml)

A small Bazel module that provides reusable VHDL dependency graph metadata via `vhdl_library`.

## What This Module Does

`vhdl_library` collects:

- `srcs` (`.vhd`, `.vhdl`)
- `hdrs` (`.vhd`, `.vhdl`)
- `data` (runtime/compile-side data files)
- `deps` (other `vhdl_library` targets)

and propagates a transitive `VhdlInfo` provider that downstream rules can consume.

## Installation (Bzlmod)

Add to `MODULE.bazel`:

```starlark
bazel_dep(name = "rules_vhdl", version = "0.1.0")
```

## Usage

```starlark
load("@rules_vhdl//vhdl:defs.bzl", "vhdl_library")

vhdl_library(
    name = "core",
    srcs = ["core.vhd"],
)

vhdl_library(
    name = "soc",
    srcs = ["soc_top.vhdl"],
    deps = [":core"],
)
```

`VhdlInfo` and helper constructors are exported from `@rules_vhdl//vhdl:defs.bzl` for custom rule authors.

## Development

Run all checks locally:

```bash
bazel test //...
```

## License

Apache-2.0.
