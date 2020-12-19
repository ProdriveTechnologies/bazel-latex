def _latex_pdf_impl(ctx):
    toolchain = ctx.toolchains["@bazel_latex//:latex_toolchain_type"]
    ctx.actions.run(
        mnemonic = "LuaLatex",
        executable = "python",
        use_default_shell_env = True,
        arguments = [
            "run_lualatex.py",
            toolchain.kpsewhich.files.to_list()[0].path,
            toolchain.luatex.files.to_list()[0].path,
            ctx.files._latexrun[0].path,
            ctx.label.name,
            ctx.files.main[0].path,
            ctx.outputs.out.path,
        ],
        inputs = depset(direct = ctx.files._latexrun + ctx.files.main + ctx.files.srcs, transitive = [toolchain.kpsewhich.files, toolchain.luatex.files]),
        outputs = [ctx.outputs.out],
    )

_latex_pdf = rule(
    attrs = {
        "main": attr.label(allow_files = True),
        "srcs": attr.label_list(allow_files = True),
        "_latexrun": attr.label(
            allow_files = True,
            default = "@bazel_latex_latexrun//:latexrun",
        ),
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
    native.sh_binary(
        name = name + "_view",
        srcs = ["@bazel_latex//:view_pdf.sh"],
        data = [name + ".pdf"],
    )
