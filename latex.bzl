def _latex_pdf_impl(ctx):
    toolchain = ctx.toolchains["@bazel_latex//:latex_toolchain_type"]
    ctx.actions.run(
        executable = "python",
        use_default_shell_env = True,
        arguments = [
            "external/bazel_latex/run_pdflatex.py",
            toolchain.kpsewhich.files.to_list()[0].path,
            toolchain.pdftex.files.to_list()[0].path,
            ctx.label.name,
            ctx.files.main[0].path,
            ctx.outputs.out.path,
        ],
        inputs = toolchain.kpsewhich.files + toolchain.pdftex.files + ctx.files.main + ctx.files.srcs,
        outputs = [ctx.outputs.out],
    )

_latex_pdf = rule(
    attrs = {
        "main": attr.label(allow_files = True),
        "srcs": attr.label_list(allow_files = True),
    },
    outputs = {"out": "%{name}.pdf"},
    toolchains = ["@bazel_latex//:latex_toolchain_type"],
    implementation = _latex_pdf_impl,
)

def latex_document(name, main, srcs = []):
    # PDF generation.
    _latex_pdf(
        name = name,
        srcs = srcs + ["@bazel_latex//:core_dependencies"],
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
