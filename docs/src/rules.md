# Rules

`rules_vhdl` exposes a single public rule.

## Library

- [`vhdl_library`](./vhdl_library.md) — collect VHDL sources, metadata
  (library name, standard, top-entity), and dependency edges into a
  transitive [`VhdlInfo`](./vhdl_info.md) provider consumed by
  downstream synthesis and simulation rulesets.

## Providers

- [`VhdlInfo`](./vhdl_info.md) — the transitive provider `vhdl_library`
  emits and downstream rules consume. Carries VHDL sources plus a
  merged `verilog_deps` depset for cross-language designs.
