# Contributing to Pharaoh

Pharaoh is a backend framework, inspired by the likes of ExpressJS, to empower developers in building comprehensive server-side applications using Dart. The driving force behind Pharaoh's creation is a strong belief in the potential of Dart to serve as the primary language for developing the entire architecture of a company's product. Just as the JavaScript ecosystem has evolved, Pharaoh aims to contribute to the Dart ecosystem, providing a foundation for building scalable and feature-rich server-side applications.

## Table of contents

- [Get Started!](#get-started)
- [Coding Guidelines](#coding-guidelines)
- [Reporting an Issue](#reporting-an-issue)
- [PR and Code Contributions](#PRs-and-Code-contributions)

## Get Started!

ready to contribute ... 👋🏽 Let's go 🚀

### Steps for contributing
1. [Open an issue](https://github.com/codekeyz/pharaoh/issues/new/choose) for the bug you want to fix or the feature that you want to add.

2. Fork repo to your GitHub Account, then clone the code to your local machine. If you are not sure how to do this, GitHub's [Fork a repo](https://docs.github.com/en/get-started/quickstart/fork-a-repo) documentation has a great step by step guide for that.

3. Set up the development by running the following commands

```
dart pub global activate melos
 melos bootstrap
```
## Coding Guidelines

Write your code on your local machine. It's good practice to create a branch for
each new issue you work on, although not compulsory.

To run the test suite,
```
run melos run all tests.
``` 

Ensure your code is linted by running 
```
melos run lint:all
```

If the tests pass, you can commit your changes to your fork and then create
a pull request from there. Make sure to reference your issue from the pull request comments by including the issue number e.g. Resolves: #123.

### Branches
Use the main branch for bug fixes or minor work that is intended for the
current release stream.

Use the correspondingly named branch, e.g. 2.0, for anything intended for
a future release of Pharaoh.

## Reporting an Issue

We will typically close any vague issues or questions that are specific to some
app you are writing. Please double check the docs and other references before
being trigger happy with posting a question issue.

Things that will help get your question issue looked at:

- Full and runnable Dart code.

- Clear description of the problem or unexpected behavior.

- Clear description of the expected result.

- Steps you have taken to debug it yourself.

- If you post a question and do not outline the above items or make it easy for us to understand and reproduce your issue, it will be closed.

## PRs and Code contributions
- All Tests must pass.

- Follow the Dart Lint Style and `melos run lint:all`.

- If you fix a bug, add a test.

- Include a description to your PR and a



