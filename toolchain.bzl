LatexInfo = provider(
    doc = "Information about how to invoke the latex compiler",
    fields = [
        "biber",
        "bibtex",
        "gsftopk",
        "kpsewhich",
        "luahbtex",
        "luatex",
    ],
)

def _latex_toolchain_info_impl(ctx):
    return [
        platform_common.ToolchainInfo(
            latexinfo = LatexInfo(
                biber = ctx.attr.biber,
                bibtex = ctx.attr.bibtex,
                gsftopk = ctx.attr.gsftopk,
                kpsewhich = ctx.attr.kpsewhich,
                luahbtex = ctx.attr.luahbtex,
                luatex = ctx.attr.luatex,
            ),
        ),
    ]

_latex_toolchain_info = rule(
    attrs = {
        "biber": attr.label(
            allow_single_file = True,
            cfg = "host",
            executable = True,
        ),
        "bibtex": attr.label(
            allow_single_file = True,
            cfg = "host",
            executable = True,
        ),
        "gsftopk": attr.label(
            allow_single_file = True,
            cfg = "host",
            executable = True,
        ),
        "kpsewhich": attr.label(
            allow_single_file = True,
            cfg = "host",
            executable = True,
        ),
        "luahbtex": attr.label(
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

def latex_toolchain(platform, exec_compatible_with, platform_name_override = None):
    _name = platform_name_override if platform_name_override != None else platform

    _latex_toolchain_info(
        name = "latex_toolchain_info_%s" % _name,
        biber = "@texlive_bin__%s//:biber" % platform,
        bibtex = "@texlive_bin__%s//:bibtex" % platform,
        gsftopk = "@texlive_bin__%s//:gsftopk" % platform,
        kpsewhich = "@texlive_bin__%s//:kpsewhich" % platform,
        luahbtex = "@texlive_bin__%s//:luahbtex" % platform,
        luatex = "@texlive_bin__%s//:luatex" % platform,
        visibility = ["//visibility:public"],
    )

    native.toolchain(
        name = "latex_toolchain_%s" % _name,
        exec_compatible_with = exec_compatible_with,
        toolchain = ":latex_toolchain_info_%s" % _name,
        toolchain_type = ":latex_toolchain_type",
    )
