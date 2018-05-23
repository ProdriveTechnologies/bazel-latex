# Bazel rules for LaTeX

This repository provides [Bazel](https://bazel.build/) rules for LaTeX,
strongly inspired by [Klaus Aehlig's blog post](http://www.linta.de/~aehlig/techblog/2017-02-19.html)
on the matter.

These rules are still of pretty low quality. We hope that by placing
them in a publicly accessible repository, their quality will improve
over time.

# Using these rules

Add the following to `WORKSPACE`:

```python
git_repository(
    name = "bazel_latex",
    remote = "https://github.com/ProdriveTechnologies/bazel-latex.git",
    tag = "...",
)
```

And add the following `load()` directive to your `BUILD` files:

```python
load("@bazel_latex//:latex.bzl", "latex_pdf")
```

You can then use the
[`filegroup()`](https://docs.bazel.build/versions/master/be/general.html#filegroup)
function to package files. For example:

```python
filegroup(
    name = "my_report_lib",
    srcs = glob([
        "my_report.tex",
        "chapters/*.tex",
        "figures/*",
    ]) + [":company_style"],
)

filegroup(
    name = "company_style",
    srcs = ...
)
```

After declaring some `filegroup()` targets, you can use the `latex_pdf()`
function to generate PDFs:

```python
latex_pdf(
    name = "my_report",
    srcs = [":my_report_lib"],
)
```

This function automatically invokes `pdflatex` on the source file
containing a `\documentclass` directive.
