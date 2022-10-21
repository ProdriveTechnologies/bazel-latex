"""
Helpers for built-in packages.
"""

load("//:latex.bzl", "latex_document")

def latex_package(name, srcs = [], tests = [], tests_deps = []):
    native.filegroup(
        name = name,
        srcs = srcs,
        visibility = ["//visibility:public"],
    )

    for test in tests:
        latex_document(
            name = name + "_" + test,
            main = test,
            srcs = [":" + name] + tests_deps,
        )
