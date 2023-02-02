"""
This module contains the specializations of commands
depending on tool or engine.
"""

def to_dirname(inp):
    return inp.dirname

def get_common_args(ctx, dep_tools, files):
    """
    Set up environment variables common for all commands.

    Latex and a set of scripts and binaries in the tool suite
    makes use of a library, kpathsea.
    In general latex distributions are encouraged to follow the 'TDS'
    structure. And tools and script might make assumptions that the
    layout of directories respects that structure.

    But from our perspective, trying to shoehorn the partioned
    repositories according
    (E.g. <sandbox>/bazel-latex/external/<ext_texlive_repo>/<files>)
    to the TDS creates an unnecessary complexity.
    Also kpathsea tries to be efficient about looking up files.
    So to derive if a folder is of interest, kpathsea checks if the number
    of files or folders in the current folder being inspected is greater
    than 2.
    Unfortunately symlinks are (currently) not counted. And Bazel makes heavy
    use of symlinks.

    However, kpathsea makes heavy use of environment variables (and
    ls-R database, IIRC).
    So we can work around this limitation. Also, by only adding the
    search paths of the files mapped to the environment variable we can reduce
    the search space, and reduce build times.
    https://tug.org/texinfohtml/kpathsea.html#Supported-file-formats,
    lists all environment variables one can set.

    Args:
      ctx: For accessing the inputs parameters.
      dep_tools: the tools needed by latexrun
      files: all files that might be needed as part of the build.

    Returns:
      A list of commands to provide to the ctx.actions.run invokation
    """

    # TODO: Makes the depencies from the packages even more finergrained
    #       E.g. allow the user to state dependencies on specific fonts?
    # TODO: Do not blindly add all paths as is currently done,
    #       it becomes painful both for bazel and latex.
    # TODO: If we can pass / set the environment variables as env
    #       arguments on the ctx.actions.run, we might eventually
    #       be able to remove tool_wrapper, as it is now currently
    #       only a thin wrapper to latexrun.
    common_args = ctx.actions.args()
    common_args.add_joined(
        "--env",
        files,
        join_with = ":",
        format_joined = "TFMFONTS=%s",
        map_each = to_dirname,
        uniquify = True,
    )
    common_args.add_joined(
        "--env",
        files,
        join_with = ":",
        format_joined = "VFFONTS=%s",
        map_each = to_dirname,
        uniquify = True,
    )
    common_args.add_joined(
        "--env",
        files,
        join_with = ":",
        format_joined = "BIBINPUTS=.:%s",
        map_each = to_dirname,
        uniquify = True,
    )
    common_args.add_joined(
        "--env",
        files,
        join_with = ":",
        format_joined = "AFMFONTS=%s",
        map_each = to_dirname,
        uniquify = True,
    )
    common_args.add_joined(
        "--env",
        files,
        join_with = ":",
        format_joined = "TTFONTS=%s",
        map_each = to_dirname,
        uniquify = True,
    )
    common_args.add_joined(
        "--env",
        files,
        join_with = ":",
        format_joined = "OPENTYPEFONTS=%s",
        map_each = to_dirname,
        uniquify = True,
    )
    common_args.add_joined(
        "--env",
        files,
        join_with = ":",
        format_joined = "TEXINPUTS=%s",
        map_each = to_dirname,
        uniquify = True,
    )
    common_args.add_joined(
        "--env",
        files,
        join_with = ":",
        format_joined = "T1FONTS=%s",
        map_each = to_dirname,
        uniquify = True,
    )
    common_args.add_joined(
        "--env",
        files,
        join_with = ":",
        format_joined = "ENCFONTS=%s",
        map_each = to_dirname,
        uniquify = True,
    )
    common_args.add_joined(
        "--env",
        files,
        join_with = ":",
        format_joined = "LUAINPUTS=%s:",
        map_each = to_dirname,
        uniquify = True,
    )
    common_args.add_joined(
        "--env",
        files,
        join_with = ":",
        format_joined = "TEXFONTMAPS=:%s:",
        map_each = to_dirname,
        uniquify = True,
    )
    common_args.add_joined(
        "--env",
        [
            dep_tools[0].to_list()[0].dirname,  # latex bin folder
            dep_tools[4].to_list()[0].dirname,  # script folder
            "/bin",  # sed, rm, etc. needed by mktexlsr
            "/usr/bin",  # needed to find pytohn
        ],
        join_with = ":",
        format_joined = "PATH=%s:.:",
        uniquify = True,
    )
    tex_env_dict = {
        "SOURCE_DATE_EPOCH": ["0"],
        "TEXMF": ["$PWD/external"],
        "TEXMFCNF": [ctx.files.web2c[0].dirname],
        "TEXMFHOME": ["$PWD"],
        "TEXMFROOT": ["."],
    }
    for k, v in tex_env_dict.items():
        common_args.add_joined(
            "--env",
            v,
            join_with = ":",
            format_joined = "{}=%s".format(k),
        )

    for dep_tool in dep_tools:
        common_args.add_all("--dep-tool", dep_tool)
    return common_args

def add_flags(ctx):
    """
    Set flags for supplying arguments to latexrun and the engine.

    Args:
      ctx: For accessing the flags

    Returns:
      Flags for the latexrun command
    """
    prefix = "--flag="
    cmd = [
        "--latex-args=--progname={}".format(ctx.attr._progname),
        "--output-format={}".format(ctx.attr.format),
        "--shell-escape",
        "--jobname={}".format(ctx.label.name),
        "--fmt={}.fmt".format(ctx.attr._progname),
    ]

    flags = [
        prefix + " ".join(cmd),
    ]

    for value in ctx.attr.cmd_flags:
        if "output-format" in value and ctx.attr.format not in value:
            fail(
                "Value of attr format ({}), ".format(ctx.attr.format) +
                "conflicts with value of flag {}".format(value),
            )
        flags.append(prefix + value)
    return flags

def lualatex_engine_cmd_gen(ctx, dep_tools, latex_tool):
    """
    Generate commands specific for the lualatex engine.

    This function generates three commands:
    - generate format file
    - create ls-R database
    - call latex to build the document

    Args:
      ctx: For accessing the inputs parameters.
      dep_tools: the tools needed by latexrun
      latex_tool: The latex engine to use, in this case we make the
        assumption that it is the luahbtex binary (This should be
        enforced more strongly).

    Returns:
      A list with the three commands
    """

    # TODO: Each command could be its own invokation to ctx.actions.run
    #       this way the artifacts could be cached, it might not help that
    #       much though, as any change to the inputs is likely to re-trigger
    #       a re-build.
    #       However, running each command by ctx.actions.run will off-load
    #       the tool_wrapper, so that it can be removed.
    int_files = ctx.files.font_maps + ctx.files.ini_files + ctx.files.web2c
    files = ctx.files.srcs + int_files

    ini_args = get_common_args(ctx, dep_tools, files)
    ini_files_path = ctx.files.ini_files[0].dirname
    engine_config_args = "{}/{}.ini".format(ini_files_path, ctx.attr._progname)
    ini_args.add("--input", engine_config_args)
    ini_args.add("--tool", latex_tool.to_list()[0])
    ini_args.add("--tool-output", "{}.fmt".format(ctx.attr._progname))
    ini_args.add("--flag=-ini")

    ini_args.use_param_file("--file=%s", use_always = True)
    ini_args.set_param_file_format("multiline")

    env_args = get_common_args(ctx, dep_tools, files)
    env_args.add("--tool", dep_tools[4].to_list()[0].path)
    env_args.add("--input", ".")
    env_args.use_param_file("--file=%s", use_always = True)
    env_args.set_param_file_format("multiline")

    args = get_common_args(ctx, dep_tools + [latex_tool], files)
    args.add("--tool=" + ctx.files._latexrun[0].path)
    args.add(
        "--flag=--latex-cmd={}".format(
            latex_tool.to_list()[0].path,
        ),
    )
    args.add("--flag=-Wall")
    args.add("--flag=--debug")
    args.add("--input=" + ctx.file.main.path)
    args.add("--tool-output=" + ctx.label.name + ".{}".format(ctx.attr.format))
    args.add("--output=" + ctx.outputs.out.path)
    args.add("--flag=-O=.")
    args.add_all(add_flags(ctx))

    args.use_param_file("--file=%s", use_always = True)
    args.set_param_file_format("multiline")

    return [ini_args, env_args, args]
