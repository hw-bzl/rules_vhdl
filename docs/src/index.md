# rules_vhdl

A small Bazel module that provides reusable VHDL dependency-graph
metadata via [`vhdl_library`](./vhdl_library.md).

## Overview

`rules_vhdl` doesn't compile or simulate VHDL itself. It supplies a
single library rule — [`vhdl_library`](./vhdl_library.md) — that
collects source files, per-target metadata (library name, standard,
top-entity), and dependency edges, and exposes them as a transitive
[`VhdlInfo`](./vhdl_info.md) provider. Downstream synthesis, simulation,
and lint rules consume that provider to drive tools like Vivado, GHDL,
NVC, or Modelsim without each ruleset re-inventing the dependency
graph.

Cross-language dependencies are first-class: `vhdl_library.verilog_deps`
accepts `verilog_library` targets (from
[`rules_verilog`](https://registry.bazel.build/modules/rules_verilog)),
and the resolved
[`VerilogInfo`](https://github.com/hw-bzl/rules_verilog) chain is
carried on `VhdlInfo.verilog_deps` so mixed-language consumers walk one
merged depset per axis.

## Quick start

### `MODULE.bazel`

```python
bazel_dep(name = "rules_vhdl", version = "{version}")
```

`rules_vhdl` has no toolchain to register — `vhdl_library` is
metadata-only. The consuming ruleset (synthesis, simulation, etc.)
brings its own toolchain.

### `hello/utils_pkg.vhd`

```vhdl
library ieee;
use ieee.std_logic_1164.all;

package utils_pkg is
  function bit_or(a, b : std_logic) return std_logic;
end package;

package body utils_pkg is
  function bit_or(a, b : std_logic) return std_logic is
  begin
    return a or b;
  end function;
end package body;
```

### `hello/hello.vhd`

```vhdl
library ieee;
use ieee.std_logic_1164.all;
library my_utils;
use my_utils.utils_pkg.all;

entity hello is
  port (
    a   : in  std_logic;
    b   : in  std_logic;
    led : out std_logic
  );
end entity;

architecture rtl of hello is
begin
  led <= bit_or(a, b);
end architecture;
```

### `hello/BUILD.bazel`

```python
load("@rules_vhdl//vhdl:defs.bzl", "vhdl_library")

vhdl_library(
    name = "utils",
    srcs = ["utils_pkg.vhd"],
    library = "my_utils",
)

vhdl_library(
    name = "hello",
    srcs = ["hello.vhd"],
    top_entity = "hello",
    deps = [":utils"],
)
```

### Consume it

`vhdl_library` targets don't build anything on their own — hand them
to a downstream rule that knows how to walk `VhdlInfo`. For example,
[`rules_vivado`](https://registry.bazel.build/modules/rules_vivado)
takes a `vhdl_library` as the `module` of a `vivado_project`:

```python
load("@rules_vivado//vivado:defs.bzl", "vivado_project", "vivado_synthesis")

vivado_project(
    name = "hello_project",
    module = "//hello",
    module_top = "hello",
    part_number = "xc7a35ticsg324-1L",
)

vivado_synthesis(
    name = "hello_synth",
    project = ":hello_project",
)
```

## Cross-language dependencies

A VHDL design that instantiates a Verilog/SystemVerilog module via a
component binding declares the Verilog target on `verilog_deps`:

```python
load("@rules_verilog//verilog:defs.bzl", "verilog_library")
load("@rules_vhdl//vhdl:defs.bzl", "vhdl_library")

verilog_library(
    name = "sv_fifo",
    srcs = ["fifo.sv"],
)

vhdl_library(
    name = "core",
    srcs = ["core.vhd"],
    verilog_deps = [":sv_fifo"],
)
```

Consumers walking `VhdlInfo.deps` for VHDL sources also walk
`VhdlInfo.verilog_deps` for the Verilog side of the graph — the two
depsets are aggregated transitively, so a top-level target sees every
cross-language dep reachable through the chain.

## Going further

- [Rules](./rules.md) — the public rule surface.
- [`VhdlInfo`](./vhdl_info.md) — the provider passed to downstream
  consumers.
