workspace(name = "bazel_latex")

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

http_archive(
    name = "bazel_toolchains",
    sha256 = "109a99384f9d08f9e75136d218ebaebc68cc810c56897aea2224c57932052d30",
    strip_prefix = "bazel-toolchains-94d31935a2c94fe7e7c7379a0f3393e181928ff7",
    urls = [
        "https://mirror.bazel.build/github.com/bazelbuild/bazel-toolchains/archive/94d31935a2c94fe7e7c7379a0f3393e181928ff7.tar.gz",
        "https://github.com/bazelbuild/bazel-toolchains/archive/94d31935a2c94fe7e7c7379a0f3393e181928ff7.tar.gz",
    ],
)

register_toolchains(
    "@bazel_latex//:latex_toolchain_aarch64-darwin",
    # The latex_toolchain_amd64-freebsd seems broken, see comment in BUILD.bazel, so disabled for now
    #"@bazel_latex//:latex_toolchain_amd64-freebsd",
    "@bazel_latex//:latex_toolchain_x86_64-darwin",
    "@bazel_latex//:latex_toolchain_x86_64-linux",
)

load("@bazel_latex//:repositories.bzl", "latex_repositories")

latex_repositories()

# Needed for building ghostscript
# Which is needed by dvisvgm,
# dvisvgm is part of the texlive toolchain,
# but cannot produce correct svg files without dynamically
# linking to ghostscript.
load("@rules_foreign_cc//foreign_cc:repositories.bzl", "rules_foreign_cc_dependencies")

rules_foreign_cc_dependencies()

# mac os shared lib was difficult to build via foreign rules so as a temporary
# solution we provide it as a precompiled artifact.
# Consider making it available via bazel_latex binaries repo instead
http_archive(
    name = "ghostscript_macos",
    build_file_content = """
filegroup(
    name = "libgs_macos",
    srcs = glob(["*/*"]),
    target_compatible_with = ["@platforms//os:osx"],
    visibility = ["//visibility:public"],
)
""",
    sha256 = "56b480ebdf34000eac4a29e108ce6384858941d892fd69e604d90585aaae4c94",
    urls = [
        "https://github.com/solsjo/rules_latex_deps/releases/download/v0.9.4/rules_latex_deps_macos-latest.zip",
    ],
)

http_archive(
    name = "rules_python",
    sha256 = "5fa3c738d33acca3b97622a13a741129f67ef43f5fdfcec63b29374cc0574c29",
    strip_prefix = "rules_python-0.9.0",
    url = "https://github.com/bazelbuild/rules_python/archive/0.9.0.tar.gz",
)

load("@rules_python//python:pip.bzl", "pip_install")

pip_install(
    name = "py_deps",
    requirements = "//:requirements.txt",
)
