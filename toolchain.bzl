"""
Definitions related to a LaTeX toolchain
"""

LatexInfo = provider(
    doc = "Information about how to invoke the latex compiler",
    fields = [
        "biber",
        "bibtex",
        "gsftopk",
        "kpsewhich",
        "kpsestat",
        "luahbtex",
        "luatex",
        "mktexlsr",
        "kpseaccess",
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
                kpsestat = ctx.attr.kpsestat,
                luahbtex = ctx.attr.luahbtex,
                luatex = ctx.attr.luatex,
                mktexlsr = ctx.attr.mktexlsr,
                kpseaccess = ctx.attr.kpseaccess,
            ),
        ),
    ]

_latex_toolchain_info = rule(
    attrs = {
        "biber": attr.label(
            allow_single_file = True,
            cfg = "exec",
            executable = True,
        ),
        "bibtex": attr.label(
            allow_single_file = True,
            cfg = "exec",
            executable = True,
        ),
        "gsftopk": attr.label(
            allow_single_file = True,
            cfg = "exec",
            executable = True,
        ),
        "kpseaccess": attr.label(
            allow_single_file = True,
            cfg = "exec",
            executable = True,
        ),
        "kpsestat": attr.label(
            allow_single_file = True,
            cfg = "exec",
            executable = True,
        ),
        "kpsewhich": attr.label(
            allow_single_file = True,
            cfg = "exec",
            executable = True,
        ),
        "luahbtex": attr.label(
            allow_single_file = True,
            cfg = "exec",
            executable = True,
        ),
        "luatex": attr.label(
            allow_single_file = True,
            cfg = "exec",
            executable = True,
        ),
        "mktexlsr": attr.label(
            allow_single_file = True,
            cfg = "exec",
            executable = True,
        ),
    },
    implementation = _latex_toolchain_info_impl,
)

def latex_toolchain(platform, exec_compatible_with, name = None):
    """
    Defines a LaTeX toolchain.

    Args:
      name: optional name for the toolchain, defaults to latex_toolchain_{platform}.
      platform: name of the platform as named by TeXLive.
      exec_compatible_with: execution constraints passed to the toolchain.
    """
    _toolchain_name = name if name != None else "latex_toolchain_%s" % platform

    stem = "@texlive_bin__" + platform + "//:"
    _latex_toolchain_info(
        name = "%s_info" % _toolchain_name,
        biber = stem + "biber",
        bibtex = stem + "bibtex",
        gsftopk = stem + "gsftopk",
        kpseaccess = stem + "kpseaccess",
        kpsestat = stem + "kpsestat",
        kpsewhich = stem + "kpsewhich",
        luahbtex = stem + "luahbtex",
        luatex = stem + "luatex",
        mktexlsr = "@texlive_texmf__texmf-dist__scripts__texlive//:" + "mktexlsr",
        visibility = ["//visibility:public"],
    )

    native.toolchain(
        name = _toolchain_name,
        exec_compatible_with = exec_compatible_with,
        toolchain = ":%s_info" % _toolchain_name,
        toolchain_type = ":latex_toolchain_type",
    )
