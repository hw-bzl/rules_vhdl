"""vhdl rules"""

load("@rules_verilog//verilog:verilog_info.bzl", "VerilogInfo")
load(":vhdl_info.bzl", "VhdlInfo")

def _vhdl_library_impl(ctx):
    """Collects VHDL sources and transitive dependency info.

    Cross-language Verilog/SV deps declared via `verilog_deps` are recorded
    on this target's `VhdlInfo.verilog_deps` field, transitively walking
    both the direct entries' `VerilogInfo` and any Verilog deps inherited
    through the `deps` graph (i.e. a vhdl_library dep that itself has
    `verilog_deps`).

    Args:
      ctx: The context for this rule.

    Returns:
      A list of providers: `VhdlInfo` and `DefaultInfo`.
    """
    dep_infos = [dep[VhdlInfo] for dep in ctx.attr.deps]

    # Direct verilog_deps + verilog_deps inherited through the VHDL dep
    # graph. Storing the resolved depset on `VhdlInfo.verilog_deps` means
    # consumers walk one merged transitive depset (no need to recurse into
    # `VhdlInfo.deps` and re-aggregate `verilog_deps` themselves).
    direct_verilog_dep_infos = [dep[VerilogInfo] for dep in ctx.attr.verilog_deps]

    return [
        VhdlInfo(
            srcs = depset(ctx.files.srcs),
            data = depset(ctx.files.data),
            library = ctx.attr.library or ctx.label.name,
            standard = ctx.attr.standard,
            top_entity = ctx.attr.top_entity,
            deps = depset(dep_infos, order = "postorder", transitive = [d.deps for d in dep_infos]),
            verilog_deps = depset(
                direct_verilog_dep_infos,
                order = "postorder",
                transitive = (
                    # Direct entries' own Verilog dep chains.
                    [d.deps for d in direct_verilog_dep_infos] +
                    # Verilog deps inherited through the VHDL dep graph.
                    [d.verilog_deps for d in dep_infos]
                ),
            ),
        ),
        DefaultInfo(
            files = depset(ctx.files.srcs + ctx.files.data),
        ),
        coverage_common.instrumented_files_info(
            ctx,
            source_attributes = ["srcs"],
            dependency_attributes = ["deps", "verilog_deps"],
            extensions = ["vhd", "vhdl"],
        ),
    ]

vhdl_library = rule(
    doc = "Collect VHDL design units into a library target.",
    implementation = _vhdl_library_impl,
    attrs = {
        "data": attr.label_list(
            doc = "Data files needed during compilation or simulation (memory init files, etc.).",
            allow_files = True,
        ),
        "deps": attr.label_list(
            doc = "Other vhdl_library targets this design depends on.",
            providers = [
                VhdlInfo,
            ],
        ),
        "library": attr.string(
            doc = "VHDL library name this target compiles into. Defaults to the target's name.",
            default = "",
        ),
        "srcs": attr.label_list(
            doc = "VHDL source files.",
            allow_files = [".vhd", ".vhdl"],
        ),
        "standard": attr.string(
            doc = "VHDL standard version. Empty string means not specified; consumer rules apply their default.",
            default = "",
            values = ["", "1993", "2000", "2002", "2008", "2019"],
        ),
        "top_entity": attr.string(
            doc = "The top entity of this library. This is a local concept; the library's own entry-point entity, not necessarily the global design top. Empty string means not specified.",
            default = "",
        ),
        "verilog_deps": attr.label_list(
            doc = ("verilog_library targets this VHDL library instantiates " +
                   "(e.g. via component declarations bound to Verilog/SV " +
                   "modules). The rule walks each entry's `VerilogInfo` " +
                   "and stores the transitive Verilog dep chain on " +
                   "`VhdlInfo.verilog_deps`, so consumers that already " +
                   "iterate `VhdlInfo` see cross-language sources by " +
                   "additionally walking that field. Empty by default — " +
                   "pure-VHDL targets get an empty `verilog_deps` depset."),
            providers = [VerilogInfo],
        ),
    },
    provides = [
        VhdlInfo,
        DefaultInfo,
    ],
)
