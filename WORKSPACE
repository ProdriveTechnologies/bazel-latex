workspace(name = "bazel_latex")

http_archive(
    name = "bazel_toolchains",
    sha256 = "7e85a14821536bc24e04610d309002056f278113c6cc82f1059a609361812431",
    strip_prefix = "bazel-toolchains-bc0091adceaf4642192a8dcfc46e3ae3e4560ea7",
    urls = [
        "https://mirror.bazel.build/github.com/bazelbuild/bazel-toolchains/archive/bc0091adceaf4642192a8dcfc46e3ae3e4560ea7.tar.gz",
        "https://github.com/bazelbuild/bazel-toolchains/archive/bc0091adceaf4642192a8dcfc46e3ae3e4560ea7.tar.gz",
    ],
)

load("@bazel_latex//:repositories.bzl", "latex_repositories")

latex_repositories()
