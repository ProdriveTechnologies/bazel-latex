"""
Extensions for fetching texlive packages
"""

load("@bazel_latex//:repositories.bzl", "latex_texlive_repositories")
load(
    "@bazel_latex//:texlive_2022_repos.bzl",
    "TEXLIVE_VERSION_2022",
)

def _texlive_repositories_impl(mctx):
    for install in mctx.modules[0].tags.install:
        latex_texlive_repositories(install.version)
    return mctx.extension_metadata(reproducible = True)

texlive_repositories = module_extension(
    implementation = _texlive_repositories_impl,
    tag_classes = {"install": tag_class(attrs = {"version": attr.string(default = TEXLIVE_VERSION_2022)})},
)
