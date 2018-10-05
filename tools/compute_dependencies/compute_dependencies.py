#!/usr/bin/env python3

# compute_dependencies: Find minimal dependencies of a LaTeX document.
#
# This script invokes Bazel repeatedly to determine the minimal set of
# dependencies of a LaTeX document, using a binary searching approach.
# This may be useful when creating Bazel targets for packages.

import hashlib
import subprocess
import sys

# Obtain full list of texmf externals provided by TeXLive.
with subprocess.Popen(
    ["bazel", "query", "//external:*"], stdout=subprocess.PIPE
) as proc:
    all_externals = frozenset(
        "@" + external[11:].strip().decode("ascii")
        for external in proc.stdout.readlines()
        if external.startswith(b"//external:texlive_texmf__")
    )


def build(externals):
    """Build a document with given externals and return its checksum."""
    with open("BUILD.bazel", "wb") as f:
        with subprocess.Popen(
            ["buildifier"], stdin=subprocess.PIPE, stdout=f, encoding="ascii"
        ) as proc:
            proc.stdin.write(
                """load("//:latex.bzl", "latex_document")

latex_document(
    name = "output",
    main = "input.tex",
    srcs = %s,
)"""
                % repr(sorted(externals))
            )
    if subprocess.call(["bazel", "build", ":output"]) != 0:
        return None
    checksum = hashlib.sha256()
    with open("../../bazel-bin/tools/compute_dependencies/output.pdf", "rb") as f:
        while True:
            data = f.read(4096)
            if not data:
                break
            checksum.update(data)
    return checksum.digest()


# Perform an initial build with all dependencies to determine what the
# resulting document should look like.
desired_checksum = build(all_externals)
if desired_checksum is None:
    print("Document doesn't even build with all TeXLive packages in place")
    sys.exit(1)

# Prune unnecessary dependencies using binary searching.
necessary = set(all_externals)
to_check = [all_externals]
while to_check:
    l = to_check.pop(0)
    print(len(l))
    if build(necessary - l) == desired_checksum:
        # Removing the externals did not affect output, meaning these
        # aren't actual dependencies.
        necessary -= l
    elif len(l) > 1:
        # Removing the externals broke the build or changed the output.
        # Decompose the sets to see which externals caused this.
        sl = sorted(l)
        to_check.append(frozenset(sl[: len(l) // 2]))
        to_check.append(frozenset(sl[len(l) // 2 :]))

# Emit a final copy of BUILD.bazel with the definitive list of
# dependencies.
if build(necessary) != desired_checksum:
    print("Final build yielded a different checksum")
