LatexInfo = provider(
    doc = "Information about how to invoke LuaLatex",
    fields = [],
)

def _latex_toolchain_info_impl(ctx):
    return [
        platform_common.ToolchainInfo(
            kpsewhich = ctx.attr.kpsewhich,
            luatex = ctx.attr.luatex,
        ),
    ]

_latex_toolchain_info = rule(
    attrs = {
        "kpsewhich": attr.label(
            allow_single_file = True,
            cfg = "host",
            executable = True,
        ),
        "luatex": attr.label(
            allow_single_file = True,
            cfg = "host",
            executable = True,
        ),
    },
    implementation = _latex_toolchain_info_impl,
)

def latex_toolchain(name, platform, exec_compatible_with):
    """Defines a native toolchain for Latex

    Args:
        name: Name of the toolchain. Must end with the platform.
        platform: Platform as identified by Texlive.
        exec_compatible_with: Execution platform this toolchain is compatible with.
    """
    if not name.endswith(platform):
        fail("Latex toolchain '${name}' should end with '${platform}'".format(name = name, platform = platform))
    toolchain_info_name = name + "_info"
    _latex_toolchain_info(
        name = toolchain_info_name,
        kpsewhich = "@texlive_bin__%s//:kpsewhich" % platform,
        luatex = "@texlive_bin__%s//:luatex" % platform,
        visibility = ["//visibility:public"],
    )

    native.toolchain(
        name = name,
        exec_compatible_with = exec_compatible_with,
        toolchain = toolchain_info_name,
        toolchain_type = ":latex_toolchain_type",
    )
