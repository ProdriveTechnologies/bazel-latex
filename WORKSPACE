workspace(name = "bazel_latex")

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

http_archive(
    name = "bazel_toolchains",
    sha256 = "4329663fe6c523425ad4d3c989a8ac026b04e1acedeceb56aa4b190fa7f3973c",
    strip_prefix = "bazel-toolchains-bc09b995c137df042bb80a395b73d7ce6f26afbe",
    urls = [
        "https://mirror.bazel.build/github.com/bazelbuild/bazel-toolchains/archive/bc09b995c137df042bb80a395b73d7ce6f26afbe.tar.gz",
        "https://github.com/bazelbuild/bazel-toolchains/archive/bc09b995c137df042bb80a395b73d7ce6f26afbe.tar.gz",
    ],
)

load("@bazel_latex//:repositories.bzl", "latex_repositories")

latex_repositories()

register_toolchains(
    "@bazel_latex//:latex_toolchain_amd64-freebsd",
    "@bazel_latex//:latex_toolchain_x86_64-darwin",
    "@bazel_latex//:latex_toolchain_x86_64-linux",
)
