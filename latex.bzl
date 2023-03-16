"""
Rules to compile LaTeX documents.
"""

load("@bazel_latex//:latex_engine_cmds.bzl", "lualatex_engine_cmd_gen")

LatexOutputInfo = provider(
    "Information about the result of a LaTeX compilation.",
    fields = {
        "deps": "depset of files the document depends on",
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
    setup_env_for(type_env, "TEXPSHEADERS", files, [".pro"])
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
        deps = depset(direct = files),
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
        "_dvi_sub": attr.label(
            default = "@bazel_latex//:dvi_sub",
            executable = True,
            cfg = "exec",
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

def dvisvgm_pdf_specfic_input(ctx, flags, env):
    """
    Handle dvisvgm specific flags for pdf input

    Args:
      ctx: For accessing the inputs parameters.
      flags: dvisvgm arguments to extend with pdf specific flags
      env: Environment variable dict to extend with pdf specific values
    """
    flags.append("--pdf")
    env.update(ctx.attr.ghostscript_envs)
    libgs_path = ""
    for libgs_file in ctx.files.libgs:
        if libgs_file.basename.startswith("libgs.{}".format(ctx.attr.libgs_ext)):
            libgs_path = libgs_file.path
    if libgs_path == "":
        fail("libgs not found, required when input format is pdf")

    # realpath does not exist on mac OS X prior to mac OS 13
    if ctx.attr.libgs_ext == "dylib":
        flags.append("--libgs=$(/usr/local/bin/python3 -c 'import os, sys; print(os.path.realpath(sys.argv[1]))' {})".format(libgs_path))
    else:
        flags.append("--libgs={}".format(libgs_path))

def _latex_to_svg_impl(ctx):
    toolchain = ctx.toolchains["@bazel_latex//:latex_toolchain_type"].latexinfo

    src = ctx.attr.src
    if LatexOutputInfo in src:
        input_file = src[LatexOutputInfo].file
        input_format = src[LatexOutputInfo].format
        files = [src[LatexOutputInfo].deps]
    else:
        input_file = ctx.file.src
        input_format = input_file.extension
        files = []

    tree = ctx.actions.declare_directory(ctx.label.name)
    flags = []
    flags.append("--output={}/{}-%p.svg".format(tree.path, ctx.label.name))
    flags.extend(ctx.attr.args)
    env = get_env(ctx, toolchain, files[0].to_list() + ctx.files.deps)
    if "pdf" in input_format:
        dvisvgm_pdf_specfic_input(ctx, flags, env)
    elif "eps" in input_format:
        flags.append("--eps")

    string_list = []
    for fm in ctx.attr.font_maps:
        for fm_file in fm.files.to_list():
            string_list.append(fm_file.path)

    flags.append("--fontmap={}".format(",".join(string_list)))

    all_dep_files = []
    for dep in files:
        all_dep_files.extend(dep.to_list())

    arguments = [
        toolchain.dvisvgm.files.to_list()[0].path,
    ] + flags + [
        ctx.files.src[0].path,
    ]

    ctx.actions.run_shell(
        mnemonic = "DviSvgM",
        command = " ".join(arguments),
        inputs = depset(
            direct = files[0].to_list() + ctx.files.src +
                     toolchain.kpsewhich.files.to_list() +
                     toolchain.dvisvgm.files.to_list() +
                     ctx.files.libgs +
                     ctx.files.deps +
                     all_dep_files,
        ),
        outputs = [tree],
        env = env,
    )

    return [DefaultInfo(files = depset([tree]))]

_latex_to_svg = rule(
    attrs = {
        "args": attr.string_list(
        ),
        "deps": attr.label_list(),
        "font_maps": attr.label_list(
            allow_files = True,
            default = [
                "@texlive_texmf__texmf-dist__fonts__map__dvips__updmap",
                "@texlive_texmf__texmf-dist__fonts__map__pdftex__updmap",
            ],
        ),
        "ghostscript_envs": attr.string_dict(
            allow_empty = True,
            default = {"GS_OPTIONS": "-dNEWPDF=false"},
        ),
        "libgs": attr.label(
            allow_files = True,
            doc = """File or target of ghostscript shared library.""",
        ),
        "libgs_ext": attr.string(),
        "src": attr.label(allow_single_file = [".dvi", ".pdf", ".eps"]),
        "web2c": attr.label(
            allow_files = True,
            default = "@texlive_texmf__texmf-dist__web2c",
        ),
    },
    toolchains = ["@bazel_latex//:latex_toolchain_type"],
    implementation = _latex_to_svg_impl,
)

def latex_document(
        name,
        main,
        srcs = [],
        tags = [],
        cmd_flags = [],
        format = "pdf",
        bib_tool = "biber",
        **kwargs):
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
        **kwargs
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

def latex_to_svg(
        name,
        src,
        args = [],
        deps = [],
        ghostscript_envs = {"GS_OPTIONS": "-dNEWPDF=false"},
        libgs = None,
        **kwargs):
    _latex_to_svg(
        name = "{}_svg".format(name),
        src = src,
        args = args,
        deps = deps + [
            "@bazel_latex//:core_dependencies",
            "@bazel_latex//:ghostscript_dependencies",
        ],
        ghostscript_envs = ghostscript_envs,
        libgs = libgs,
        libgs_ext = select({
            "@platforms//os:osx": "dylib",
            "@platforms//os:windows": "dll",
            "//conditions:default": "so",
        }),
        **kwargs
    )

    native.filegroup(
        name = name,
        srcs = [":{}_svg".format(name)],
        **kwargs
    )
