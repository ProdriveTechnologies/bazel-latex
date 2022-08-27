#!/usr/bin/env python

import argparse
import glob
import os
import shutil
import subprocess
import sys

from pathlib import Path


def setup_dependencies():
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
        if external.startswith("texlive_extra__") or external.startswith(
                "texlive_texmf__"):
            dst = os.path.join("texmf", "/".join(external.split("__")[1:]))
            try:
                os.makedirs(os.path.dirname(dst))
            except OSError:
                pass
            os.rename(src, dst)
        else:
            texinputs.append(src)
    return texinputs


def setup_env(env, texinputs, tools):
    env["OPENTYPEFONTS"] = ":".join(texinputs)
    env["PATH"] = "%s:%s" % (os.path.abspath("bin"), env["PATH"])
    env["SOURCE_DATE_EPOCH"] = "0"
    env["TEXINPUTS"] = ":".join(texinputs)
    env["TEXMF"] = os.path.abspath("texmf/texmf-dist")
    env["TEXMFCNF"] = os.path.abspath("texmf/texmf-dist/web2c")
    env["TEXMFROOT"] = os.path.abspath("texmf")
    env["TTFONTS"] = ":".join(texinputs)
    
    os.mkdir("bin")
    for tool in tools:
        if "luatex" in tool:
            shutil.copy(tool, "bin/lualatex")
            os.link("bin/lualatex", "bin/luatex")
        else:
            shutil.copy(tool, "bin/" + os.path.basename(tool))

    shutil.copy("texmf/texmf-dist/scripts/texlive/fmtutil.pl", "bin/mktexfmt")
    return env


def setup_argparse():
    parser = argparse.ArgumentParser()
    parser.add_argument('--dep-tool', default=[], action='append')
    parser.add_argument('--tool')
    parser.add_argument('--env', default=[], action='append')
    parser.add_argument('--input')
    parser.add_argument('--inputs')
    parser.add_argument('--tool-output')
    parser.add_argument('--output')
    parser.add_argument('--flag', default=[], action='append')
    return parser


def main():
    parser = setup_argparse()
    args = parser.parse_args()
    
    tools = args.dep_tool + [args.tool]

    env = dict(os.environ)
    for en in args.env:
        key, value = en.split(":")
        value = os.path.abspath(value)
        env[key] = value
    texinputs = setup_dependencies()
    # Add custom dependencies to TEXINPUTS
    dependency_list = args.inputs.split(',')
    texinputs.extend([os.path.abspath(path) for path in dependency_list])
    env = setup_env(env, texinputs, tools)
    cmd_args = [
        os.path.basename(args.tool),
    ] + args.flag + [args.input]

    return_code = subprocess.call(
        args=cmd_args,
        env=env,
    )
    
    if return_code != 0 or not os.path.exists(args.tool_output):
        raise SystemExit(
                """{} exited with: {}
The following arguments were provided:
{}""".format(args.tool, return_code, cmd_args)
        )

    os.rename(args.tool_output, args.output)


if __name__ == "__main__":
    main()
