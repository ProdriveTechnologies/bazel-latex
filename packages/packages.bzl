load("//:latex.bzl", "latex_document")

def latex_package(name, srcs = []):
    native.filegroup(
        name = name,
        srcs = srcs,
        visibility = ["//visibility:public"],
    )

    latex_document(
        name = name + "_test",
        main = name + "_test.tex",
        srcs = [":" + name],
    )
