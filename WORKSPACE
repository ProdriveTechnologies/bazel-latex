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

http_archive(
    name = "biber_amd64_freebsd",
    sha256 = "12c15ad29a3e8be5eb64192d910affd1244bd745aaf31aa0b94525322111e908",
    url = "https://sourceforge.net/projects/biblatex-biber/files/biblatex-biber/2.12/binaries/FreeBSD/biber-amd64-freebsd.tar.xz",
    build_file_content = """
exports_files(["biber"])
    """,
)

http_archive(
    name = "biber_linux_x86_64",
    sha256 = "fd0b5145cc908c400a701b583330635d533d750b73a272d1d5ea47e10b2fbf71",
    url = "https://sourceforge.net/projects/biblatex-biber/files/biblatex-biber/2.12/binaries/Linux/biber-linux_x86_64.tar.gz",
    build_file_content = """
exports_files(["biber"])
    """,
)

http_archive(
    name = "biber_darwin_x86_64",
    sha256 = "5a5f20669bd3e4cf56fd246ef2ba37d601ca2059510590a5022da4487d5e7bb8",
    url = "https://sourceforge.net/projects/biblatex-biber/files/biblatex-biber/2.12/binaries/OSX_Intel/biber-darwin_x86_64.tar.gz",
    build_file_content = """
exports_files(["biber"])
    """,
)

register_toolchains(
    "//:latex_toolchain_amd64-freebsd",
    "//:latex_toolchain_x86_64-darwin",
    "//:latex_toolchain_x86_64-linux",
)

load("@bazel_latex//:repositories.bzl", "latex_repositories")

latex_repositories()
