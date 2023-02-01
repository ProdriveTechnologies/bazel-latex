
"""
Setup of all the LaTeX dependencies.
"""

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("@bazel_latex//:texlive_2022_repos.bzl", "TEXLIVE_VERSION", "TEXLIVE_MODULAR_PACKAGES_BIN", "TEXLIVE_MODULAR_PACKAGES_OTHER")


def latex_repositories(name = None):
    """
    Load all the dependencies required to compile LaTeX documents.

    Args:
      name: unused.
    """
    for path, sha256 in TEXLIVE_MODULAR_PACKAGES_BIN:
        name = "texlive_%s" % path.replace("/", "__")
        http_archive(
            name = name,
            build_file_content = """
exports_files(
    [
        "biber",
        "bibtex",
        "kpsewhich",
        "gsftopk",
        "luahbtex",
        "luatex",
    ],
    visibility = ["//visibility:public"],
)
""",
            sha256 = sha256,
            url = "https://github.com/ProdriveTechnologies/texlive-modular/releases/download/%s/texlive-%s-%s.tar.xz" % (TEXLIVE_VERSION, TEXLIVE_VERSION, path.replace("/", "--")),
        )

    for path, sha256, patches in TEXLIVE_MODULAR_PACKAGES_OTHER:
        name = "texlive_%s" % path.replace("/", "__")
        http_archive(
            name = name,
            build_file_content = """
filegroup(
    name = "%s",
    srcs = glob(
        include = ["**"],
        exclude = [
            "BUILD.bazel",
            "WORKSPACE",
        ],
    ),
    visibility = ["//visibility:public"],
)
""" % name,
            patches = patches,
            sha256 = sha256,
            url = "https://github.com/ProdriveTechnologies/texlive-modular/releases/download/%s/texlive-%s-%s.tar.xz" % (TEXLIVE_VERSION, TEXLIVE_VERSION, path.replace("/", "--")),
        )

    http_archive(
        name = "bazel_latex_latexrun",
        build_file_content = "exports_files([\"latexrun\"])",
        patches = [
            "@bazel_latex//:patches/latexrun-force-colors",
            "@bazel_latex//:patches/latexrun-pull-21",
            "@bazel_latex//:patches/latexrun-pull-47",
            "@bazel_latex//:patches/latexrun-pull-52",
            "@bazel_latex//:patches/latexrun-pull-61",
            "@bazel_latex//:patches/latexrun-pull-62",
        ],
        patch_cmds = [
            "chmod +x latexrun",
        ],
        sha256 = "4e1512fde5a05d1249fd6b4e6610cdab8e14ddba82a7cbb58dc7d5c0ba468c2a",
        strip_prefix = "latexrun-38ff6ec2815654513c91f64bdf2a5760c85da26e",
        url = "https://github.com/aclements/latexrun/archive/38ff6ec2815654513c91f64bdf2a5760c85da26e.tar.gz",
    )

    http_archive(
        name = "platforms",
        urls = [
            "https://mirror.bazel.build/github.com/bazelbuild/platforms/releases/download/0.0.6/platforms-0.0.6.tar.gz",
            "https://github.com/bazelbuild/platforms/releases/download/0.0.6/platforms-0.0.6.tar.gz",
        ],
        sha256 = "5308fc1d8865406a49427ba24a9ab53087f17f5266a7aabbfc28823f3916e1ca",
    )

    native.register_toolchains(
        "@bazel_latex//:latex_toolchain_aarch64-darwin",
        "@bazel_latex//:latex_toolchain_amd64-freebsd",
        "@bazel_latex//:latex_toolchain_x86_64-darwin",
        "@bazel_latex//:latex_toolchain_x86_64-linux",
    )
