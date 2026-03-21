"""vhdl rules"""

load(
    "vhdl_info.bzl",
    _VhdlInfo = "VhdlInfo",
)
load(
    "vhdl_library.bzl",
    _vhdl_library = "vhdl_library",
)

VhdlInfo = _VhdlInfo
vhdl_library = _vhdl_library
