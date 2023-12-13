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
1. [Open an issue](https://github.com/Pharaoh-Framework/pharaoh/issues/new/choose) for the bug you want to fix or the feature that you want to add.

2. Fork the repo to your GitHub Account, then clone the code to your local machine. If you are not sure how to do this, GitHub's [Fork a repo](https://docs.github.com/en/get-started/quickstart/fork-a-repo) documentation has a great step by step guide for that.

3. Set up the workspace by running the following commands

```shell
dart pub global activate melos
```

and this

```
 melos bootstrap
```

## Coding Guidelines

It's good practice to create a branch for each new issue you work on, although not compulsory. 
- All dart analysis checks must pass before you submit your code. Ensure your code is linted by running 
```
melos run analyze
```

- You must write tests for your bug-fix/feature and all tests must pass. You can verify by running
```
run melos run all tests.
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
app you are writing. Please double check the docs and other references before reporting an issue or posting a question.

Things that will help get your issue looked at:

- Full and runnable Dart code.

- Clear description of the problem or unexpected behavior.

- Clear description of the expected result.

- Steps you have taken to debug it yourself.

- If you post a question and do not outline the above items or make it easy for us to understand and reproduce your issue, it will be closed.

## PRs and Code contributions
When you've got your contribution working, all test and lint style passed, and committed to your branch it's time to create a Pull Request (PR). If you are unsure how to do this GitHub's [Creating a pull request from a fork](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/proposing-changes-to-your-work-with-pull-requests/creating-a-pull-request-from-a-fork) documentation will help you with that. Once you create your PR you will be presented with a template in the PR's description that looks like this:

```md
<!--
  Thanks for contributing!

  Provide a description of your changes below and a general summary in the title

  Please look at the following checklist to ensure that your PR can be accepted quickly:
-->

## Description
<!-- Please describe what you added, and add a screenshot if possible.
     That makes it easier to understand the change so we can :shipit: faster. -->

## Type of Change

<!--- Put an `x` in all the boxes that apply: -->

- [ ] ✨ New feature (non-breaking change which adds functionality)
- [ ] 🛠️ Bug fix (non-breaking change which fixes an issue)
- [ ] ❌ Breaking change (fix or feature that would cause existing functionality to change)
- [ ] 🧹 Code refactor
- [ ] ✅ Build configuration change
- [ ] 📝 Documentation
- [ ] 🗑️ Chore

All you need to do is fill in the information as requested by the template. Please do not remove this as it helps both you and the reviewers confirm that the various tasks have been completed.
```

Here is an examples of good PR descriptions:

- <https://github.com/Pharaoh-Framework/pharaoh/pull/70>



