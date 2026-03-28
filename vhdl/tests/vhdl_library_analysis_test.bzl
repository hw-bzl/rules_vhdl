"""Analysis tests for vhdl_library."""

load("@bazel_skylib//lib:unittest.bzl", "analysistest", "asserts")
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
    asserts.equals(env, "work", info.library)
    asserts.equals(env, "", info.standard)
    asserts.equals(env, "", info.top_entity)

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
    asserts.equals(env, "work", info.library)

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
            name + "_bad_src_extension",
        ],
    )
