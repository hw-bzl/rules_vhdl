# rules_vhdl

[![CI](https://github.com/hw-bzl/bazel_rules_vhdl/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/hw-bzl/bazel_rules_vhdl/actions/workflows/ci.yml)

A small Bazel module that provides reusable VHDL dependency graph metadata via `vhdl_library`.

## What This Module Does

`vhdl_library` collects:

- `srcs` (`.vhd`, `.vhdl`) — VHDL source files
- `data` — data files needed during compilation or simulation
- `deps` — other `vhdl_library` targets
- `library` — VHDL library name (defaults to `"work"`)
- `standard` — VHDL standard version (optional; empty string means "unspecified")
- `top_entity` — the library's entry-point entity name (optional; empty string means "unspecified")

and propagates a transitive `VhdlInfo` provider that downstream rules can consume.

## Installation (Bzlmod)

Add to `MODULE.bazel`:

```starlark
# See releases for available versions.
bazel_dep(name = "rules_vhdl", version = "{version}")
```

## Usage

```starlark
load("@rules_vhdl//vhdl:defs.bzl", "vhdl_library")

vhdl_library(
    name = "utils",
    srcs = ["utils_pkg.vhd"],
    library = "my_utils",
)

vhdl_library(
    name = "core",
    srcs = ["core.vhd"],
    deps = [":utils"],
)

vhdl_library(
    name = "soc",
    srcs = ["soc_top.vhdl"],
    top_entity = "soc_top",
    deps = [":core"],
)
```

`VhdlInfo` is exported from `@rules_vhdl//vhdl:defs.bzl` for custom rule authors.

## Development

Run all checks locally:

```bash
bazel test //...
```

## License

Apache-2.0.
