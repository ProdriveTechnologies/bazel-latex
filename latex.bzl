load("@bazel_tools//tools/build_defs/pkg:pkg.bzl", "pkg_tar")

latex_pdf = rule(
    attrs = {
        "srcs": attr.label_list(),
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
