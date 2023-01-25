"""
Rules to compile LaTeX documents.
"""

load("@bazel_latex//:latex_engine_cmds.bzl", "lualatex_engine_cmd_gen")

LatexOutputInfo = provider(
    "Information about the result of a LaTeX compilation.",
    fields = {
        "file": "string, e.g. 'foo/bar.pdf'",
        "format": "string, e.g. 'pdf'",
    },
)

def get_env(ctx, toolchain, files):
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
      toolchain: The latex toolchain.
      files: all files that might be needed as part of the build.

    Returns:
      A list of commands to provide to the ctx.actions.run invocation
    """

    def list_unique_folders_from_file_ext(files, exts):
        directories = []
        for inp in files:
            dirname = inp.dirname
            valid = False
            if not exts:
                valid = True
            else:
                for ext in exts:
                    if inp.path.endswith(ext):
                        valid = True
            if valid and dirname not in directories:
                directories.append(dirname)
        return directories

    def setup_env_for(
            type_env_dict,
            env_var,
            files,
            extensions = [],
            post_additions = ""):
        search_folders = list_unique_folders_from_file_ext(
            files,
            extensions,
        )
        type_env_dict[env_var] = ".:{}{}".format(
            ":".join(search_folders),
            post_additions,
        )

    type_env = {}
    setup_env_for(type_env, "AFMFONTS", files, [".afm"])
    setup_env_for(type_env, "BIBINPUTS", files, [".bib"])
    setup_env_for(type_env, "ENCFONTS", files, [".enc"])
    setup_env_for(
        type_env,
        "LUAINPUTS",
        files,
        [".lua" or ".luc"],
        ":$TEXINPUTS:",
    )
    setup_env_for(type_env, "OPENTYPEFONTS", files)
    setup_env_for(type_env, "T1FONTS", files, [".pfa", ".pfb"])
    setup_env_for(type_env, "TEXFONTMAPS", files, [".map"], ":")
    setup_env_for(type_env, "TEXINPUTS", files)
    setup_env_for(type_env, "TFMFONTS", files, [".tfm"])
    setup_env_for(type_env, "TTFONTS", files, [".ttf", ".ttc"])
    setup_env_for(type_env, "VFFONTS", files, [".vf"])

    env = {
        "PATH": ":".join(
            [
                toolchain.kpsewhich.files.to_list()[0].dirname,  # latex bin folder
                toolchain.mktexlsr.files.to_list()[0].dirname,  # script folder
                "/bin",  # sed, rm, etc. needed by mktexlsr
                "/usr/bin",  # needed to find python
                # NOTE: ctx.configuration.default_shell_env returns {}
                # So the default shell env provided by bazel can't
                # be updated by the rules.
                # Supplying the env argument overwrites bazel's env
                # resulting in python not being found.
            ],
        ),
        "SOURCE_DATE_EPOCH": "0",
        "TEXMF": ".",
        "TEXMFCNF": ctx.files.web2c[0].dirname,
        "TEXMFDBS": ".:$TEXMFHOME:$TEXMF",
        "TEXMFHOME": ".",
        "TEXMFROOT": ".",
    }
    env.update(type_env)
    return env

def get_engine_cmds_gen(engine_progname):
    engine_map = {"lualatex": lualatex_engine_cmd_gen}
    return engine_map[engine_progname]

def _latex_impl(ctx):
    toolchain = ctx.toolchains["@bazel_latex//:latex_toolchain_type"].latexinfo

    latex_tool = getattr(toolchain, ctx.attr._engine)
    dep_tools = [
        toolchain.biber.files,
        toolchain.bibtex.files,
        toolchain.gsftopk.files,
        toolchain.kpsewhich.files,
        toolchain.mktexlsr.files,
        toolchain.kpsestat.files,
        toolchain.kpseaccess.files,
    ]

    bib_tool = {
        "biber": toolchain.biber.files.to_list()[0],
        "bibtex": toolchain.bibtex.files.to_list()[0],
    }[ctx.attr.bib_tool]

    engine_cmds_gen = get_engine_cmds_gen(ctx.attr._progname)
    engine_cmds = engine_cmds_gen(ctx, bib_tool, latex_tool)

    files = (
        ctx.files.srcs +
        ctx.files.main +
        ctx.files.ini_files +
        ctx.files.font_maps +
        ctx.files.web2c
    )

    env = get_env(ctx, toolchain, files)
    for engine_cmd in engine_cmds:
        ctx.actions.run(
            mnemonic = "LuaLatex",
            executable = engine_cmd["tool"],
            arguments = engine_cmd["cmd"],
            inputs = depset(
                direct = files +
                         ctx.files._latexrun +
                         engine_cmd["in"],
                transitive = [latex_tool.files] + dep_tools,
            ),
            outputs = engine_cmd["out"],
            tools = [latex_tool.files.to_list()[0]],
            env = env,
        )
    latex_info = LatexOutputInfo(
        file = ctx.outputs.out,
        format = ctx.attr.format,
    )
    return [latex_info]

_latex = rule(
    attrs = {
        "bib_tool": attr.string(
            default = "biber",
            values = ["biber", "bibtex"],
        ),
        "cmd_flags": attr.string_list(
            allow_empty = True,
            default = [],
        ),
        "font_maps": attr.label_list(
            allow_files = True,
            default = [
                "@texlive_texmf__texmf-dist__fonts__map__dvips__updmap",
                "@texlive_texmf__texmf-dist__fonts__map__pdftex__updmap",
            ],
        ),
        "format": attr.string(
            doc = "Output file format",
            default = "pdf",
            values = ["dvi", "pdf"],
        ),
        "ini_files": attr.label(
            allow_files = True,
            default = "@texlive_texmf__texmf-dist__tex__generic__tex-ini-files",
        ),
        "main": attr.label(
            allow_single_file = [".tex"],
            mandatory = True,
        ),
        "srcs": attr.label_list(allow_files = True),
        "web2c": attr.label(
            allow_files = True,
            default = "@texlive_texmf__texmf-dist__web2c",
        ),
        # TODO: Suggestion to make _engine public so that the
        #       user can set their engine of choice
        "_engine": attr.string(default = "luahbtex"),
        "_latexrun": attr.label(
            default = "@bazel_latex_latexrun//:latexrun",
            executable = True,
            cfg = "exec",
        ),
        "_progname": attr.string(default = "lualatex"),
    },
    outputs = {"out": "%{name}.%{format}"},
    toolchains = ["@bazel_latex//:latex_toolchain_type"],
    implementation = _latex_impl,
)

def latex_document(
        name,
        main,
        srcs = [],
        tags = [],
        cmd_flags = [],
        format = "pdf",
        bib_tool = "biber"):
    _latex(
        name = name,
        # TODO: Add a deps field, for adding external deps such
        #       as core_deps
        srcs = srcs + ["@bazel_latex//:core_dependencies"],
        main = main,
        tags = tags,
        cmd_flags = cmd_flags,
        format = format,
        bib_tool = bib_tool,
    )

    # Convenience rule for viewing outputs.
    native.sh_binary(
        name = "{}_view_output".format(name),
        srcs = ["@bazel_latex//:view_output.sh"],
        data = [":{}.{}".format(name, format)],
        args = ["$(location :{}.{})".format(name, format)],
        tags = tags,
    )

    # Convenience rule for viewing outputs, silencing stderr.
    native.sh_binary(
        name = "{}_view".format(name),
        srcs = ["@bazel_latex//:view_output.sh"],
        data = [":{}.{}".format(name, format)],
        args = [
            "$(location :{}.{})".format(name, format),
            "None",
        ],
        tags = tags,
    )
