""" Replace absolute font paths with relative paths in dvi files.

The absolute font paths point back into the prevous sandbox
in which the dvi was created.
Resulting in problems finding the font in e.g. svg grneration.

By using relative paths we make sure that, at least in our Bazel workflow,
font can referenced.
"""

import argparse
import re


def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument("in_file")
    parser.add_argument("out_file")
    args = parser.parse_args()
    return args


def sub(in_file, out_file):
    with open(in_file, 'rb') as fd:
        old_data = fd.read()
    # TODO: This function could be parameterized
    #       in respect to font type and regex pattern
    path_root_pattern = re.compile(b"\[(.*?)external")
    ext_pattern = re.compile(b"\[.*\.(.*?)]")
    result = path_root_pattern.findall(old_data)
    unique_ext = set(ext_pattern.findall(old_data))
    if result and unique_ext:
        sub_string = result[0]
        short_data = re.sub(sub_string, b'./', old_data)
        path_len_diff = len(sub_string) - len(b'./')
        new_data = short_data
        for ext in unique_ext:
            new_data = re.sub(
                b'\.' + ext+ b']',
                b'.' + ext + (b'\x00' * path_len_diff) + b']',
                new_data
            )
        assert len(old_data) == len(new_data), f"{len(old_data)} {len(new_data)}"
    else:
        new_data = old_data
    with open(out_file, 'wb') as fd:
        fd.write(new_data)


def main():
    args = parse_args()
    sub(args.in_file, args.out_file)


if __name__ == "__main__":
    main()
