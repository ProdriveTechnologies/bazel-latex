load("//:latex.bzl", "latex_document")

def latex_package(name, srcs = [], tests = []):
    native.filegroup(
        name = name,
        srcs = srcs,
        visibility = ["//visibility:public"],
    )

    for i in tests:
        latex_document(
            name = name + "_" + i,
            main = i,
            srcs = [":" + name],
        )
