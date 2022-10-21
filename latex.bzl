"""
Rules to compile LaTeX documents.
"""

LatexOutputInfo = provider(
    "Information about the result of a LaTeX compilation.",
    fields = {
        "file": "string, e.g. 'foo/bar.pdf'",
        "format": "string, e.g. 'pdf'",
    },
)

def _latex_impl(ctx):
    toolchain = ctx.toolchains["@bazel_latex//:latex_toolchain_type"].latexinfo
    custom_dependencies = []
    for srcs in ctx.attr.srcs:
        for file in srcs.files.to_list():
            if file.dirname not in custom_dependencies:
                custom_dependencies.append(file.dirname)
    custom_dependencies = ",".join(custom_dependencies)

    flags = [
        "--flag=--latex-args=--progname=lualatex --debug-format --output-format={} --shell-escape --jobname={}"
            .format(ctx.attr.format, ctx.label.name),
    ]
    for value in ctx.attr.cmd_flags:
        if "output-format" in value and ctx.attr.format not in value:
            fail("Value of attr format ({}) conflicts with value of flag {}".format(ctx.attr.format, value))
        flags.append("--flag=" + value)

    ctx.actions.run(
        mnemonic = "LuaLatex",
        use_default_shell_env = True,
        executable = ctx.executable._tool,
        arguments = [
            "--dep-tool=" + toolchain.biber.files.to_list()[0].path,
            "--dep-tool=" + toolchain.bibtex.files.to_list()[0].path,
            "--dep-tool=" + toolchain.gsftopk.files.to_list()[0].path,
            "--dep-tool=" + toolchain.kpsewhich.files.to_list()[0].path,
            "--dep-tool=" + toolchain.luahbtex.files.to_list()[0].path,
            "--dep-tool=" + toolchain.luatex.files.to_list()[0].path,
            "--tool=" + ctx.files._latexrun[0].path,
            "--flag=--latex-cmd=luahbtex",
            "--flag=-Wall",
            "--flag=--debug",
            "--input=" + ctx.file.main.path,
            "--tool-output=" + ctx.label.name + ".{}".format(ctx.attr.format),
            "--output=" + ctx.outputs.out.path,
            "--inputs=" + custom_dependencies,
        ] + flags,
        inputs = depset(
            direct = ctx.files.main + ctx.files.srcs + ctx.files._latexrun,
            transitive = [
                toolchain.biber.files,
                toolchain.bibtex.files,
                toolchain.gsftopk.files,
                toolchain.kpsewhich.files,
                toolchain.luahbtex.files,
                toolchain.luatex.files,
            ],
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
        "format": attr.string(
            doc = "Output file format",
            default = "pdf",
            values = ["dvi", "pdf"],
        ),
        "main": attr.label(
            allow_single_file = [".tex"],
            mandatory = True,
        ),
        "srcs": attr.label_list(allow_files = True),
        "_latexrun": attr.label(
            allow_files = True,
            default = "@bazel_latex_latexrun//:latexrun",
        ),
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
