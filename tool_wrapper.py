#!/usr/bin/env python

import argparse
import glob
import os
import shutil
import subprocess
import sys
from pathlib import Path


def setup_env(args_env):
    env = {}
    for en in args_env:
        key, value = en.split("=")
        env[key] = value
    return env


def setup_argparse():
    parser = argparse.ArgumentParser()
    parser.add_argument('--dep-tool', default=[], action='append')
    parser.add_argument('--tool')
    parser.add_argument('--env', default=[], action='append')
    parser.add_argument('--input')
    parser.add_argument('--tool-output')
    parser.add_argument('--output')
    parser.add_argument('--flag', default=[], action='append')

    file_parser = argparse.ArgumentParser()
    file_parser.add_argument('--file', default=[], action='append')
    return file_parser, parser


def main():
    file_parser, parser = setup_argparse()
    files = file_parser.parse_args().file
    i = 0
    for args_file in files:
        with open(args_file) as fd:
            args = parser.parse_args(fd.read().splitlines())
        tools = args.dep_tool + [args.tool]

        env = setup_env(args.env)
        cmd_args = [args.tool] + args.flag + [args.input]
        returncode = 0
        output = None
        res = ""
        if not args.input:
            cmd_args = cmd_args[:-1]

        try:
            res = subprocess.check_output(
                args=cmd_args,
                env=env,
                cwd=".",
                stderr=subprocess.STDOUT,
                shell=False,
                universal_newlines=True,
            )
        except subprocess.CalledProcessError as exc:
            output = exc.output
            returncode = exc.returncode

        if (args.tool_output and not os.path.exists(args.tool_output)) or returncode != 0:
            raise SystemExit(
                    """{} exited ({}) with:
std out:
'''
{}
'''
std err:
'''
{}
'''
The following arguments were provided:
{}
content in dir:
    {}
texlive dist bin:
    {}
""".format(
                args.tool,
                returncode,
                res,
                output,
                cmd_args,
                os.listdir("."),
                env["PATH"]
                )
            )
        i = i + 1
        if args.output:
            os.rename(args.tool_output, args.output)


if __name__ == "__main__":
    main()
