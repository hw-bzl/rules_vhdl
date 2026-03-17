"""vhdl rules"""

load(
    ":providers.bzl",
    _VhdlInfo = "VhdlInfo",
    _make_dag_entry = "make_dag_entry",
    _make_vhdl_info = "make_vhdl_info",
    _vhdl_library = "vhdl_library",
)

VhdlInfo = _VhdlInfo
vhdl_library = _vhdl_library
make_dag_entry = _make_dag_entry
make_vhdl_info = _make_vhdl_info
