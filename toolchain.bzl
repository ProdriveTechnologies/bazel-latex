def _latex_toolchain_info_impl(ctx):
    return [
        platform_common.ToolchainInfo(
            kpsewhich = ctx.attr.kpsewhich,
            luatex = ctx.attr.luatex,
            bibtex = ctx.attr.bibtex,
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
        "bibtex": attr.label(
            allow_single_file = True,
            cfg = "host",
            executable = True,
        ),
    },
    implementation = _latex_toolchain_info_impl,
)

def latex_toolchain(platform, exec_compatible_with):
    _latex_toolchain_info(
        name = "latex_toolchain_info_%s" % platform,
        kpsewhich = "@texlive_bin__%s//:kpsewhich" % platform,
        luatex = "@texlive_bin__%s//:luatex" % platform,
        bibtex = "@texlive_bin__%s//:bibtex" % platform,
        visibility = ["//visibility:public"],
    )

    native.toolchain(
        name = "latex_toolchain_%s" % platform,
        exec_compatible_with = exec_compatible_with,
        toolchain = ":latex_toolchain_info_%s" % platform,
        toolchain_type = ":latex_toolchain_type",
    )
