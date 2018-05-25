load("@bazel_tools//tools/build_defs/pkg:pkg.bzl", "pkg_tar")

def _latex_pdf_impl(ctx):
    ctx.actions.run(
        executable = "sh",
        use_default_shell_env = True,
        arguments = [
            ctx.executable._run_pdflatex.path,
            ctx.label.name,
            ctx.outputs.out.path,
        ] + [src.path for src in ctx.files.srcs],
        inputs = ctx.files.srcs + [ctx.executable._run_pdflatex],
        outputs = [ctx.outputs.out],
    )

_latex_pdf = rule(
    attrs = {
        "srcs": attr.label_list(allow_files = True),
        "_run_pdflatex": attr.label(
            default = Label("//:run_pdflatex.sh"),
            allow_files = True,
            executable = True,
            cfg = "host",
        ),
    },
    outputs = {"out": "%{name}.pdf"},
    implementation = _latex_pdf_impl,
)

def latex_document(name, srcs):
    # PDF generation.
    _latex_pdf(
        name = name,
        srcs = srcs,
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
              "echo 'exec xdg-open '\\''./" + native.package_name() + "/" + name + ".pdf'\\' >> $@",
    )
    native.sh_binary(
        name = name + "_view",
        srcs = [":" + name + "_view_sh"],
        data = [":" + name + "_view_lib"],
    )
