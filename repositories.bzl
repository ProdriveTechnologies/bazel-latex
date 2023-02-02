"""
Setup of all the LaTeX dependencies.
"""

load(
    "@bazel_latex//:texlive_2022_repos.bzl",
    "TEXLIVE_MODULAR_PACKAGES_BIN_2022",
    "TEXLIVE_MODULAR_PACKAGES_OTHER_2022",
    "TEXLIVE_VERSION_2022",
)
load("@bazel_latex//:version.bzl", "texlive_version")
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

bin_build_file = """
# {}

exports_files(
    glob(["*.*", "*"]),
    visibility = ["//visibility:public"],
)
"""

other_build_file = """

exports_files(
    glob(["*.*", "*"]),
    visibility = ["//visibility:public"],
)

filegroup(
    name = "{}",
    srcs = glob(
        include = ["**"],
        exclude = [
            "BUILD.bazel",
            "WORKSPACE",
        ],
    ),
    visibility = ["//visibility:public"],
)
"""

# This allows us to append versions and keep mutliple version alive instead of
# forcing users to use an older version of this repo just to use and older
# version of latex.
LATEX_DIST = {
    TEXLIVE_VERSION_2022: struct(
        bin = TEXLIVE_MODULAR_PACKAGES_BIN_2022,
        other = TEXLIVE_MODULAR_PACKAGES_OTHER_2022,
    ),
    #TEXLIVE_VERSION_2023: struct(...,
    #TEXLIVE_VERSION_40000: struct(...,
}

def download_pkg_archive(build_file_content, version, path, sha256, patches = [], patch_cmds = []):
    """
    Helper function for downloads of external dependencies.

    Args:
      build_file_content: The build file content
      version: The version of the toolchain to use
      path: The path to use
      sha256: The checksum to use
      patches: The optional patches to apply
      patch_cmds: The optional patch commands to apply
    """
    modular_url_stem = "https://github.com/ProdriveTechnologies/texlive-modular"
    modular_url = "/releases/download/%s/texlive-%s-%s.tar.xz"
    name = "texlive_%s" % path.replace("/", "__")
    http_archive(
        name = name,
        build_file_content = build_file_content.format(name),
        patches = patches,
        patch_cmds = patch_cmds,
        sha256 = sha256,
        url = modular_url_stem + modular_url % (version, version, path.replace("/", "--")),
    )

def latex_repositories(version = TEXLIVE_VERSION_2022):
    """
    Load all the dependencies required to compile LaTeX documents.

    Args:
      version: version of texlive. See the LATEX_DIST variable.
    """

    if version not in LATEX_DIST:
        fail("Available texlive dists are: {}".format(LATEX_DIST.keys()))
    pkgs = LATEX_DIST[version]

    other = [ent[0] for ent in pkgs.other]
    texlive_version(name = "texlive_version", version = ":../../".join(other))

    for path, sha256, patches in pkgs.bin:
        download_pkg_archive(bin_build_file, version, path, sha256, patches)

    for path, sha256, patches in pkgs.other:
        download_pkg_archive(other_build_file, version, path, sha256, patches)

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
