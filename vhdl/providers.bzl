"""Describe VHDL providers and some helpful functions for manipulating them."""

# WARNING: prefer using 'make_vhdl_info' rather than constructing these directly
# to ensure the depset ordering is correct.
VhdlInfo = provider(
    doc = "Contains DAG info per node in a struct.",
    fields = {
        "dag": "A depset of the DAG entries to propagate upwards.",
    },
)

def make_dag_entry(srcs, hdrs, includes, data, deps, label, tags):
    """Create a new DAG entry for use in VhdlInfo.

    As VhdlInfo should be created via 'make_vhdl_info' (rather than directly),
    the new entries being passed in should be created with this function in order to
    ensure the struct contains the correct fields.

    Any fields marked 'legacy' are under immediate plans to be deprecated. New uses
    should be avoided. Fields marked as 'experimental' are more likely to experience
    changes in semantics in the future. Future users should exercise caution before
    using them and consider consulting the rule maintainers first.

    Args:
      srcs: A list of File that are 'srcs'.
      hdrs: A list of File that are 'hdrs'.
      includes: A list of str that are 'includes'.
      data: A list of File that are `data`.
      deps: A list of Label that are deps of this entry.
      label: A Label to use as the name for this entry.
      tags: A list of str. (Ideally) just the entry tags for later filelist filtering.
    Returns:
      struct with all these fields properly stored.
    """
    return struct(
        srcs = tuple(srcs),
        hdrs = tuple(hdrs),
        includes = tuple(includes),
        data = tuple(data),
        deps = tuple(deps),
        tags = tuple(tags),
        label = label,
    )

def make_vhdl_info(
        new_entries = (),
        old_infos = ()):
    """Return a new VhdlInfo that merges other VhdlInfo and new DAG entries.

    WARNING: Prefer using this function instead of manually creating or merging
    VhdlInfo providers to ensure the DAG traversal ordering is correct.

    Note: It is expected that the new DAG entries point to entries in the other
    VhdlInfo (but this is not required or enforced).

    Args:
      new_entries: list of DAG entries (from 'make_dag_entry') to add to the DAG
      old_infos: list of VhdlInfo that hold other parts of the DAG
    Returns:
      VhdlInfo that combines all the DAGs together.
    """
    return VhdlInfo(
        dag = depset(
            direct = new_entries,
            order = "postorder",
            transitive = [x.dag for x in old_infos],
        ),
    )

def _vhdl_library_impl(ctx):
    """Produces a DAG for the given vhdl_library target.

    Args:
      ctx: The context for this rule.

    Returns:
      A struct containing the DAG at this level of the dependency graph.
    """

    vhdl_info = make_vhdl_info(
        new_entries = [make_dag_entry(
            srcs = ctx.files.srcs,
            hdrs = ctx.files.hdrs,
            includes = [],
            data = ctx.files.data,
            deps = ctx.attr.deps,
            label = ctx.label,
            tags = [],
        )],
        old_infos = [dep[VhdlInfo] for dep in ctx.attr.deps],
    )

    return [
        vhdl_info,
    ]

vhdl_library = rule(
    doc = "Define a VHDL module.",
    implementation = _vhdl_library_impl,
    attrs = {
        "data": attr.label_list(
            doc = "Compile data read by sources.",
            allow_files = True,
        ),
        "deps": attr.label_list(
            doc = "The list of other libraries to be linked.",
            providers = [
                VhdlInfo,
            ],
        ),
        "hdrs": attr.label_list(
            doc = "VHDL header or package files.",
            allow_files = [".vhd", ".vhdl"],
        ),
        "srcs": attr.label_list(
            doc = "VHDL sources.",
            allow_files = [".vhd", ".vhdl"],
        ),
    },
)
