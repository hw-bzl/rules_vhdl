"""vhdl rules"""

def _vhdl_info_init(
        *,
        srcs = None,
        data = None,
        library = "",
        standard = "",
        top_entity = "",
        deps = None,
        verilog_deps = None):
    """`provider(init=...)` constructor for `VhdlInfo`.

    Runs on every `VhdlInfo(...)` call so callers get sensible defaults
    for optional fields — no need to know the full schema. New fields
    added to the provider grow a default value here, so external
    constructors (rules_systemrdl, kode's `k2_vivado_bd_wrapper_library`,
    etc.) stay forward-compatible without every downstream repo needing
    to add the new kwarg to their construction calls.

    Fields not supplied by the caller default to empty depsets or empty
    strings, matching the "this target contributes nothing on that axis"
    interpretation used across the ecosystem.

    Args:
        srcs: depset[File] of VHDL sources. Defaults to `depset()`.
        data: depset[File] of runtime data files. Defaults to `depset()`.
        library: str VHDL library name. Defaults to `""`.
        standard: str VHDL standard version. Defaults to `""`.
        top_entity: str top-entity name. Defaults to `""`.
        deps: depset[VhdlInfo] transitive VHDL dep chain. Defaults to `depset()`.
        verilog_deps: depset[VerilogInfo] transitive cross-language dep
            chain. Defaults to `depset()`.

    Returns:
        dict of field name -> value, consumed by the provider machinery.
    """
    return {
        "data": data if data != None else depset(),
        "deps": deps if deps != None else depset(),
        "library": library,
        "srcs": srcs if srcs != None else depset(),
        "standard": standard,
        "top_entity": top_entity,
        "verilog_deps": verilog_deps if verilog_deps != None else depset(),
    }

VhdlInfo, _new_vhdl_info = provider(
    doc = "VHDL compilation information.",
    fields = {
        "data": "depset[File]: Data files needed during compilation for this target.",
        "deps": "depset[VhdlInfo]: Transitive dependency providers.",
        "library": "str: VHDL library name for this target.",
        "srcs": "depset[File]: VHDL source files for this target.",
        "standard": "str: VHDL standard version for this target.",
        "top_entity": "str: The top entity of this library.",
        "verilog_deps": ("depset[VerilogInfo]: Transitive Verilog/SV " +
                         "dependencies a VHDL design instantiates via " +
                         "component-bound modules. Consumers walking this " +
                         "depset pick up Verilog srcs/hdrs/etc. for the " +
                         "cross-language part of the dep graph alongside " +
                         "the VHDL part walked via `deps`. Empty for " +
                         "pure-VHDL design units."),
    },
    init = _vhdl_info_init,
)
