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
load("@bazel_latex//:latex.bzl", "latex_document")
```

You can then use `latex_document()` to declare documents that need to be
built. Commonly reused sources (e.g., templates) can be placed in
[`filegroup()`](https://docs.bazel.build/versions/master/be/general.html#filegroup)
blocks, so that they don't need to be repeated.

```python
latex_document(
    name = "my_report",
    srcs = glob([
        "my_report.tex",
        "chapters/*.tex",
        "figures/*",
    ]) + [":company_style"],
)

filegroup(
    name = "company_style",
    srcs = glob([
        ...
    ]),
)
```

The `latex_document()` function automatically determines the main source
file by choosing the `.tex` file containing a `\documentclass`
directive. As `pdflatex` is effectively invoked as if within the root of
the workspace, all imports of resources (e.g., images) must use the full
path relative to the root.

A PDF can be built by running:

```
bazel build :my_report
```

It can be viewed using your system's PDF viewer by running:

```
bazel run :my_report_view
```
