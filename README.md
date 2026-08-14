# rules_vhdl

[![BCR](https://img.shields.io/badge/BCR-rules_vhdl-green?logo=bazel)](https://registry.bazel.build/modules/rules_vhdl)
[![CI](https://github.com/hw-bzl/bazel_rules_vhdl/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/hw-bzl/bazel_rules_vhdl/actions/workflows/ci.yml)

A small Bazel module that provides reusable VHDL dependency-graph
metadata via
[`vhdl_library`](https://hw-bzl.github.io/bazel_rules_vhdl/vhdl_library.html).
Downstream synthesis, simulation, and lint rulesets consume the
resulting
[`VhdlInfo`](https://hw-bzl.github.io/bazel_rules_vhdl/vhdl_info.html)
provider to drive tools like Vivado, GHDL, NVC, or Modelsim — this
module deliberately doesn't run any of them itself.

Cross-language dependencies are first-class:
[`vhdl_library.verilog_deps`](https://hw-bzl.github.io/bazel_rules_vhdl/vhdl_library.html#vhdl_library-verilog_deps)
accepts
[`rules_verilog`](https://registry.bazel.build/modules/rules_verilog)
targets and the resolved `VerilogInfo` chain is carried on
`VhdlInfo.verilog_deps`, so mixed-language consumers walk one merged
depset per axis.

Quick start, cross-language dep authoring, and the full per-rule /
per-provider reference are hosted at
**<https://hw-bzl.github.io/bazel_rules_vhdl/>**.

## License

Apache License 2.0
