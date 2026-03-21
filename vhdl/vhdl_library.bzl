"""vhdl rules"""

load(":vhdl_info.bzl", "VhdlInfo")

def _vhdl_library_impl(ctx):
    """Collects VHDL sources and transitive dependency info.

    Args:
      ctx: The context for this rule.

    Returns:
      A list of providers: VhdlInfo and DefaultInfo.
    """
    dep_infos = [dep[VhdlInfo] for dep in ctx.attr.deps]

    return [
        VhdlInfo(
            srcs = depset(ctx.files.srcs),
            data = depset(ctx.files.data),
            library = ctx.attr.library,
            standard = ctx.attr.standard,
            deps = depset(dep_infos, order = "postorder", transitive = [d.deps for d in dep_infos]),
        ),
        DefaultInfo(files = depset(ctx.files.srcs + ctx.files.data)),
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
            doc = "VHDL library name this target compiles into.",
            default = "work",
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
    },
)
