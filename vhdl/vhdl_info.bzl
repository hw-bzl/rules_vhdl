"""vhdl rules"""

VhdlInfo = provider(
    doc = "VHDL compilation information.",
    fields = {
        "data": "depset[File]: Data files needed during compilation for this target.",
        "deps": "depset[VhdlInfo]: Transitive dependency providers.",
        "library": "str: VHDL library name for this target.",
        "srcs": "depset[File]: VHDL source files for this target.",
        "standard": "str: VHDL standard version for this target.",
        "top_entity": "str: The top entity of this library.",
    },
)
