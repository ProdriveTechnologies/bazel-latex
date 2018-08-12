def _latex_pdf_impl(ctx):
    ctx.actions.run(
        executable = "python",
        use_default_shell_env = True,
        arguments = [
            "external/bazel_latex/run_pdflatex.py",
            ctx.label.name,
            ctx.files.main[0].path,
            ctx.outputs.out.path,
        ],
        inputs = ctx.files.main + ctx.files.srcs,
        outputs = [ctx.outputs.out],
    )

_latex_pdf = rule(
    attrs = {
        "main": attr.label(allow_files = True),
        "srcs": attr.label_list(allow_files = True),
    },
    outputs = {"out": "%{name}.pdf"},
    implementation = _latex_pdf_impl,
)

def latex_document(name, main, srcs = []):
    # PDF generation.
    _latex_pdf(
        name = name,
        srcs = srcs + [
            "@bazel_latex//:run_pdflatex.py",
            "@texlive_bin",
            "@texlive_extra__tlpkg__TeXLive",
            "@texlive_texmf__texmf-dist__fonts__enc__dvips__base",
            "@texlive_texmf__texmf-dist__fonts__enc__dvips__cm-super",
            "@texlive_texmf__texmf-dist__fonts__map__pdftex__updmap",
            "@texlive_texmf__texmf-dist__fonts__tfm__public__cm",
            "@texlive_texmf__texmf-dist__fonts__tfm__public__latex-fonts",
            "@texlive_texmf__texmf-dist__fonts__type1__public__amsfonts__cm",
            "@texlive_texmf__texmf-dist__fonts__type1__public__cm-super",
            "@texlive_texmf__texmf-dist__scripts__texlive",
            "@texlive_texmf__texmf-dist__tex__generic__hyphen",
            "@texlive_texmf__texmf-dist__tex__generic__tex-ini-files",
            "@texlive_texmf__texmf-dist__tex__latex__base",
            "@texlive_texmf__texmf-dist__tex__latex__latexconfig",
            "@texlive_texmf__texmf-dist__web2c",
        ],
        main = main,
    )

    # Convenience rule for viewing PDFs.
    native.sh_library(
        name = name + "_view_lib",
        data = [":" + name],
    )
    native.genrule(
        name = name + "_view_sh",
        outs = [name + "_view.sh"],
        cmd = "echo '#!/bin/sh' > $@; " +
              "echo 'exec xdg-open '\\''./" + native.package_name() + "/" + name + ".pdf'\\'' &' >> $@",
    )
    native.sh_binary(
        name = name + "_view",
        srcs = [":" + name + "_view_sh"],
        data = [":" + name + "_view_lib"],
    )
