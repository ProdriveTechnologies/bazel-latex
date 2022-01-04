# How to contribute to Bazel LaTeX

## Bugs

#### Did you find a bug?
Ensure the bug was not already reported by searching the open and closed issues. 

If you are unable to find an issue addressing the problem, then open a new one. Make sure to include a title, clear description, and as much relevant information as possible.

#### Did you fix a bug?
Open a new pull request with your fix. Ensure the PR description clearly describes the problem and solution. Include the relevant issue number if applicable.

## Features

#### Do you intend to add a new feature or change an existing one?
Suggest your change by opening an issue.

#### Do you want to expose another TeX Live package?
If the desired package to use is not available through bazel-latex, but it is available in TeX Live, then it is possible to patch `BUILD.bazel` to add support for the desired packages locally. 

If that does not suffice, please feel free to open a PR adding the package to `/packages/BUILD.bazel`, including proper tests.

## Questions

#### Do you have questions about the source code or usage?
Ask any question about how to use Bazel LaTeX by opening a blank issue.
