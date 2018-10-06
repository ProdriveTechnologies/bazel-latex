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

def _latex_view_sh_impl(ctx):
    ctx.actions.write(ctx.outputs.out, """#!/bin/sh
filename="%s"
if type xdg-open > /dev/null; then
    # X11-based systems (Linux, BSD).
    exec xdg-open "${filename}" &
elif type open > /dev/null; then
    # macOS.
    exec open "${filename}"
else
    echo "Don't know how to view PDFs on this platform." >&2
    exit 1
fi
""" % ctx.attr.document_path)

_latex_view_sh = rule(
    attrs = {
        "document_path": attr.string(),
    },
    outputs = {"out": "%{name}.sh"},
    implementation = _latex_view_sh_impl,
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
    _latex_view_sh(
        name = name + "_view_sh",
        document_path = "%s/%s.pdf" % (native.package_name(), name),
    )
    native.sh_binary(
        name = name + "_view",
        srcs = [":" + name + "_view_sh"],
        data = [":" + name + "_view_lib"],
    )
