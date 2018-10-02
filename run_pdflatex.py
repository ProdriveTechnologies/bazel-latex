#!/usr/bin/env python

import filecmp
import glob
import os
import shutil
import subprocess
import sys

# Walk through all externals. If they start with the special prefix
# texlive_{extra,texmf}__ prefix, it means they should be part of the
# texmf directory. LaTeX utilities don't seem to like the use of
# symlinks, so move the externals into the texmf directory.
#
# Externals that do not start with the special prefix should be added to
# TEXINPUTS, so that inclusions of external resources works.
texinputs = [""] + glob.glob("bazel-out/*/bin")
for external in sorted(os.listdir("external")):
    src = os.path.abspath(os.path.join("external", external))
    if external.startswith("texlive_extra__") or external.startswith("texlive_texmf__"):
        dst = os.path.join("texmf", "/".join(external.split("__")[1:]))
        try:
            os.makedirs(os.path.dirname(dst))
        except OSError:
            pass
        os.rename(src, dst)
    else:
        texinputs.append(src)

kpsewhich_file, pdftex_file, job_name, main_file, output_file = sys.argv[1:]

comparison_file = job_name + ".pdf.compare"
intermediate_file = job_name + ".pdf"
log_file = "log"

env = dict(os.environ)
env["PATH"] = "%s:%s" % (os.path.abspath("bin"), env["PATH"])
env["SOURCE_DATE_EPOCH"] = "0"
env["TEXINPUTS"] = ":".join(texinputs)
env["TEXMF"] = os.path.abspath("texmf/texmf-dist")
env["TEXMFCNF"] = os.path.abspath("texmf/texmf-dist/web2c")
env["TEXMFROOT"] = os.path.abspath("texmf")

os.mkdir("bin")
os.link(kpsewhich_file, "bin/kpsewhich")
os.link(pdftex_file, "bin/pdflatex")
os.link(pdftex_file, "bin/pdftex")
os.link("texmf/texmf-dist/scripts/texlive/fmtutil.pl", "bin/mktexfmt")

for i in range(10):
    # Call pdflatex.
    with open(log_file, "wb") as f:
        return_code = subprocess.Popen(
            args=["pdflatex", "-file-line-error", "-jobname=" + job_name, main_file],
            stdout=f,
            stderr=f,
            env=env,
        ).wait()
    if return_code != 0:
        # Print error log on failure.
        with open(log_file, "r") as f:
            shutil.copyfileobj(f, sys.stdout)
        sys.exit(return_code)

    # Emit PDF when two successive runs yield the same PDF.
    if i != 0:
        if filecmp.cmp(intermediate_file, comparison_file):
            os.rename(intermediate_file, output_file)
            sys.exit(0)
    os.rename(intermediate_file, comparison_file)

print("Number of pdflatex runs insufficient to obtain definitive output")
sys.exit(1)
