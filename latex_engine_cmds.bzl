"""
This module contains the specializations of commands
depending on tool or engine.
"""

def add_flags(ctx, fmt, bib_tool):
    """
    Set flags for supplying arguments to latexrun and the engine.

    Args:
      ctx: For accessing the flags
      fmt: Format file
      bib_tool: bib tool of choice

    Returns:
      Flags for the latexrun command
    """
    cmd = [
        "--latex-args=--progname={}".format(ctx.attr._progname),
        "--output-format={}".format(ctx.attr.format),
        "--shell-escape",
        "--jobname={}".format(ctx.label.name),
        "--fmt={}".format(fmt.path),
    ]

    flags = [
        " ".join(cmd),
    ]

    for value in ctx.attr.cmd_flags:
        if "output-format" in value and ctx.attr.format not in value:
            fail(
                "Value of attr format ({}), ".format(ctx.attr.format) +
                "conflicts with value of flag {}".format(value),
            )
        flags.append(value)
    dir_count = len(ctx.outputs.out.path.split("/")) - 1
    dir_pos = dir_count * "../"
    flags.append("--bibtex-cmd=" + dir_pos + bib_tool.path)
    flags.append("--bibtex-args=" + "--input-directory=" + dir_pos)
    return flags

def lualatex_engine_cmd_gen(ctx, bib_tool, latex_tool):
    """
    Generate commands specific for the lualatex engine.

    This function generates these commands:
    - generate format file
    - call latex to build the document

    Args:
      ctx: For accessing the inputs parameters.
      bib_tool: bib tool of choice.
      latex_tool: The latex engine to use, in this case we make the
        assumption that it is the luahbtex binary (This should be
        enforced more strongly).

    Returns:
      A list of the commands
    """

    fmt = ctx.actions.declare_file(
        ctx.label.name + "/" + ctx.attr._progname + ".fmt",
    )
    ini_args = ctx.actions.args()
    ini_files_path = ctx.files.ini_files[0].dirname
    ini_args.add("-ini")
    ini_args.add(
        "--output-directory",
        ctx.outputs.out.dirname + "/" + ctx.label.name,
    )
    ini_args.add("{}/{}.ini".format(ini_files_path, ctx.attr._progname))

    args = ctx.actions.args()
    args.add(
        "--latex-cmd={}".format(
            latex_tool.files.to_list()[0].path,
        ),
    )
    args.add("-Wall")

    args.add("-O=" + ctx.outputs.out.dirname)
    args.add_all(add_flags(ctx, fmt, bib_tool))
    args.add(ctx.file.main.path)

    return [
        {
            "cmd": [ini_args],
            "in": [],
            "out": [fmt],
            "tool": latex_tool.files.to_list()[0],
        },
        {
            "cmd": [args],
            "in": [fmt],
            "out": [ctx.outputs.out],
            "tool": ctx.executable._latexrun,
        },
    ]
