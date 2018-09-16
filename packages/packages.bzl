load("//:latex.bzl", "latex_document")

def public_filegroup(name, srcs = []):
    native.filegroup(
        name = name,
        srcs = srcs,
        visibility = ["//visibility:public"],
    )

def latex_package(name, srcs = []):
    public_filegroup(
        name = name,
        srcs = srcs
    )

    latex_document(
        name = name + "_test",
        main = name + "_test.tex",
        srcs = [":" + name],
    )
