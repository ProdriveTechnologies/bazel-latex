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

def get_engine_cmds_gen(engine_progname):
    engine_map = {"lualatex": lualatex_engine_cmd_gen}
    return engine_map[engine_progname]

def _latex_impl(ctx):
    toolchain = ctx.toolchains["@bazel_latex//:latex_toolchain_type"].latexinfo

    latex_tool = getattr(toolchain, ctx.attr._engine).files
    dep_tools = [
        toolchain.biber.files,
        toolchain.bibtex.files,
        toolchain.gsftopk.files,
        toolchain.kpsewhich.files,
        toolchain.mktexlsr.files,
        toolchain.kpsestat.files,
        toolchain.kpseaccess.files,
    ]

    engine_cmds_gen = get_engine_cmds_gen(ctx.attr._progname)
    engine_cmds = engine_cmds_gen(ctx, dep_tools, latex_tool)

    ctx.actions.run(
        mnemonic = "LuaLatex",
        use_default_shell_env = True,
        executable = ctx.executable._tool,
        arguments = engine_cmds,
        inputs = depset(
            direct = ctx.files.main + ctx.files.srcs + ctx.files._latexrun + ctx.files.ini_files + ctx.files.font_maps + ctx.files.web2c,
            transitive = [latex_tool] + dep_tools,
        ),
        outputs = [ctx.outputs.out],
        tools = [ctx.executable._tool],
    )
    latex_info = LatexOutputInfo(file = ctx.outputs.out, format = ctx.attr.format)
    return [latex_info]

_latex = rule(
    attrs = {
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
            allow_files = True,
            default = "@bazel_latex_latexrun//:latexrun",
        ),
        "_progname": attr.string(default = "lualatex"),
        "_tool": attr.label(
            default = Label("@bazel_latex//:tool_wrapper_py"),
            executable = True,
            cfg = "exec",
        ),
    },
    outputs = {"out": "%{name}.%{format}"},
    toolchains = ["@bazel_latex//:latex_toolchain_type"],
    implementation = _latex_impl,
)

def latex_document(name, main, srcs = [], tags = [], cmd_flags = [], format = "pdf"):
    _latex(
        name = name,
        # TODO: Add a deps field, for adding external deps such
        #       as core_deps
        srcs = srcs + ["@bazel_latex//:core_dependencies"],
        main = main,
        tags = tags,
        cmd_flags = cmd_flags,
        format = format,
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
