"""
   This modules allows ourselves to share and readup the used texlive version.
"""

def _version_impl(ctx):
    ctx.file("BUILD.bazel", "")
    ctx.file("texlive_version.bzl", "TEXLIVE_VERSION=[{}]".format(ctx.attr.version.split(":")))

texlive_version = repository_rule(
    implementation = _version_impl,
    attrs = {
        "version": attr.string(doc = "The texlive version"),
    },
)
