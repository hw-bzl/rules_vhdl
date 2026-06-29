"""Analysis tests for vhdl_library."""

load("@bazel_skylib//lib:unittest.bzl", "analysistest", "asserts")
load("@rules_verilog//verilog:verilog_info.bzl", "VerilogInfo")
load("//vhdl:defs.bzl", "VhdlInfo")

def _file_basenames(files):
    return sorted([f.basename for f in files])

def _leaf_provider_test_impl(ctx):
    env = analysistest.begin(ctx)
    target = analysistest.target_under_test(env)
    info = target[VhdlInfo]

    asserts.equals(env, ["leaf.vhd", "leaf_pkg.vhd"], _file_basenames(info.srcs.to_list()))
    asserts.equals(env, ["leaf.dat"], _file_basenames(info.data.to_list()))
    asserts.equals(env, [], info.deps.to_list())
    asserts.equals(env, "leaf", info.library)
    asserts.equals(env, "", info.standard)
    asserts.equals(env, "", info.top_entity)
    asserts.equals(
        env,
        [],
        info.verilog_deps.to_list(),
        "pure-VHDL leaf target must have an empty cross-language depset",
    )

    return analysistest.end(env)

def _explicit_top_entity_test_impl(ctx):
    env = analysistest.begin(ctx)
    target = analysistest.target_under_test(env)
    info = target[VhdlInfo]

    asserts.equals(env, "my_top", info.top_entity)

    return analysistest.end(env)

def _transitive_deps_test_impl(ctx):
    env = analysistest.begin(ctx)
    target = analysistest.target_under_test(env)
    info = target[VhdlInfo]

    asserts.equals(env, ["top.vhd"], _file_basenames(info.srcs.to_list()))

    dep_providers = info.deps.to_list()
    asserts.equals(env, 2, len(dep_providers))

    # Postorder guarantees dependencies before dependents (dep_a before dep_b).
    dep_src_order = [f.basename for d in dep_providers for f in d.srcs.to_list()]
    asserts.equals(env, ["dep_a.vhd", "dep_b.vhdl"], dep_src_order)

    return analysistest.end(env)

def _custom_library_test_impl(ctx):
    env = analysistest.begin(ctx)
    target = analysistest.target_under_test(env)
    info = target[VhdlInfo]

    asserts.equals(env, "my_custom_lib", info.library)
    asserts.equals(env, "", info.standard)
    asserts.equals(env, ["dep_a.vhd"], _file_basenames(info.srcs.to_list()))

    return analysistest.end(env)

def _legacy_standard_test_impl(ctx):
    env = analysistest.begin(ctx)
    target = analysistest.target_under_test(env)
    info = target[VhdlInfo]

    asserts.equals(env, "1993", info.standard)
    asserts.equals(env, "legacy_target", info.library)

    return analysistest.end(env)

def _vhdl_library_single_provider_test_impl(ctx):
    """vhdl_library never directly emits VerilogInfo.

    Locks in the contract that `vhdl_library` ALWAYS provides only
    `VhdlInfo` + `DefaultInfo`, regardless of whether `verilog_deps` is
    set. Cross-language deps are carried inside `VhdlInfo.verilog_deps`
    (a depset[VerilogInfo]) rather than via a separate provider — keeps
    the rule's provider set unconditional and avoids consumers having to
    branch on `VerilogInfo in target` for a vhdl_library target.
    """
    env = analysistest.begin(ctx)
    target = analysistest.target_under_test(env)
    asserts.true(env, VhdlInfo in target, "vhdl_library must always provide VhdlInfo")
    asserts.false(
        env,
        VerilogInfo in target,
        "vhdl_library must never directly provide VerilogInfo — " +
        "cross-language deps live in VhdlInfo.verilog_deps",
    )
    return analysistest.end(env)

def _verilog_deps_on_vhdl_info_test_impl(ctx):
    """verilog_deps surface on VhdlInfo.verilog_deps, postorder + transitive.

    A `verilog_deps`-using target keeps its own VHDL srcs and exposes the
    Verilog dep chain via `VhdlInfo.verilog_deps`.
    """
    env = analysistest.begin(ctx)
    target = analysistest.target_under_test(env)
    info = target[VhdlInfo]

    asserts.equals(env, ["mixed.vhd"], _file_basenames(info.srcs.to_list()))
    asserts.equals(env, "mixed_lib", info.library)

    # Direct + transitive: `vlog_dep` is the direct verilog_deps entry,
    # and `vlog_transitive` is reached through `vlog_dep`'s own `deps`.
    verilog_dep_srcs = [
        f.basename
        for d in info.verilog_deps.to_list()
        for f in d.srcs.to_list()
    ]
    asserts.equals(
        env,
        ["vlog_transitive.v", "vlog_dep.sv"],
        verilog_dep_srcs,
        "postorder walk should yield transitive Verilog srcs before direct ones",
    )
    return analysistest.end(env)

def _empty_vhdl_library_carries_library_for_verilog_test_impl(ctx):
    """Empty-vhdl_library wrap pattern propagates library + verilog_deps.

    Zero VHDL srcs + `library = ...` + `verilog_deps = [...]`. Confirms
    VUnit-style consumers can read the library name from
    `VhdlInfo.library` while collecting Verilog srcs from the
    `VhdlInfo.verilog_deps` chain — the use case that lets pure-Verilog
    test sources land in a named VHDL library namespace without
    `verilog_library` needing its own `library` attr.
    """
    env = analysistest.begin(ctx)
    target = analysistest.target_under_test(env)
    info = target[VhdlInfo]

    asserts.equals(env, [], info.srcs.to_list(), "wrap target must have no VHDL srcs")
    asserts.equals(env, "verilog_namespace", info.library)

    verilog_dep_srcs = [
        f.basename
        for d in info.verilog_deps.to_list()
        for f in d.srcs.to_list()
    ]
    asserts.equals(env, ["vlog_transitive.v", "vlog_dep.sv"], verilog_dep_srcs)
    return analysistest.end(env)

def _verilog_deps_inherit_through_vhdl_deps_test_impl(ctx):
    """verilog_deps inherit through a vhdl_library `deps` chain.

    A vhdl_library whose `deps` include another vhdl_library that has
    `verilog_deps` must see those Verilog deps via its own
    `VhdlInfo.verilog_deps`. Locks in the transitive walk through the
    VHDL graph, not just through direct `verilog_deps` entries.
    """
    env = analysistest.begin(ctx)
    target = analysistest.target_under_test(env)
    info = target[VhdlInfo]

    verilog_dep_srcs = [
        f.basename
        for d in info.verilog_deps.to_list()
        for f in d.srcs.to_list()
    ]
    asserts.equals(
        env,
        ["vlog_transitive.v", "vlog_dep.sv"],
        verilog_dep_srcs,
        "verilog_deps from a vhdl_library dep must flow into this target's verilog_deps",
    )
    return analysistest.end(env)

def _bad_src_extension_test_impl(ctx):
    env = analysistest.begin(ctx)
    asserts.expect_failure(env, "expected .vhd or .vhdl")
    return analysistest.end(env)

leaf_provider_test = analysistest.make(_leaf_provider_test_impl)
explicit_top_entity_test = analysistest.make(_explicit_top_entity_test_impl)
transitive_deps_test = analysistest.make(_transitive_deps_test_impl)
custom_library_test = analysistest.make(_custom_library_test_impl)
legacy_standard_test = analysistest.make(_legacy_standard_test_impl)
vhdl_library_single_provider_test = analysistest.make(_vhdl_library_single_provider_test_impl)
verilog_deps_on_vhdl_info_test = analysistest.make(_verilog_deps_on_vhdl_info_test_impl)
empty_vhdl_library_carries_library_for_verilog_test = analysistest.make(
    _empty_vhdl_library_carries_library_for_verilog_test_impl,
)
verilog_deps_inherit_through_vhdl_deps_test = analysistest.make(
    _verilog_deps_inherit_through_vhdl_deps_test_impl,
)
bad_src_extension_test = analysistest.make(
    _bad_src_extension_test_impl,
    expect_failure = True,
)

def vhdl_library_test_suite(*, name):
    """Define a suite of tests for `vhdl_library`

    Args:
        name (str): The name of the test suite
    """
    leaf_provider_test(
        name = name + "_leaf_provider",
        target_under_test = ":leaf",
    )

    explicit_top_entity_test(
        name = name + "_explicit_top_entity",
        target_under_test = ":explicit_top_entity_target",
    )

    transitive_deps_test(
        name = name + "_transitive_deps",
        target_under_test = ":top",
    )

    custom_library_test(
        name = name + "_custom_library",
        target_under_test = ":custom_lib_target",
    )

    legacy_standard_test(
        name = name + "_legacy_standard",
        target_under_test = ":legacy_target",
    )

    # Pure-VHDL target: never provides VerilogInfo directly.
    vhdl_library_single_provider_test(
        name = name + "_pure_vhdl_single_provider",
        target_under_test = ":leaf",
    )

    # Mixed-language target: also never provides VerilogInfo directly,
    # cross-language deps live in VhdlInfo.verilog_deps.
    vhdl_library_single_provider_test(
        name = name + "_mixed_lib_single_provider",
        target_under_test = ":mixed_lib_target",
    )

    verilog_deps_on_vhdl_info_test(
        name = name + "_verilog_deps_on_vhdl_info",
        target_under_test = ":mixed_lib_target",
    )

    empty_vhdl_library_carries_library_for_verilog_test(
        name = name + "_empty_vhdl_library_carries_library_for_verilog",
        target_under_test = ":verilog_namespace_wrap",
    )

    verilog_deps_inherit_through_vhdl_deps_test(
        name = name + "_verilog_deps_inherit_through_vhdl_deps",
        target_under_test = ":vhdl_consumer_of_mixed",
    )

    bad_src_extension_test(
        name = name + "_bad_src_extension",
        target_under_test = ":bad_src",
    )

    native.test_suite(
        name = name,
        tests = [
            name + "_leaf_provider",
            name + "_explicit_top_entity",
            name + "_transitive_deps",
            name + "_custom_library",
            name + "_legacy_standard",
            name + "_pure_vhdl_single_provider",
            name + "_mixed_lib_single_provider",
            name + "_verilog_deps_on_vhdl_info",
            name + "_empty_vhdl_library_carries_library_for_verilog",
            name + "_verilog_deps_inherit_through_vhdl_deps",
            name + "_bad_src_extension",
        ],
    )
