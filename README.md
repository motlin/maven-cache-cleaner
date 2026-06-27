# maven-cache-cleaner

![CI](https://github.com/twosigma/maven-cache-cleaner/actions/workflows/test.yml/badge.svg)
[![Check dist/](https://github.com/twosigma/maven-cache-cleaner/actions/workflows/check-dist.yml/badge.svg)](https://github.com/actions/typescript-action/actions/workflows/check-dist.yml)

This action cleans up all Maven dependencies not used after calling the cache cleaner action. It is intended to be used after `actions/cache` to clean up the cache right before saving it. It is intended to prevent the cache from growing infinitely large with dependencies that are no longer used.

This action uses `atime` to determine if a dependency was used or not. If a dependency was not used, it will be deleted.

The action cleaning mechanism is inspired by this [StackOverflow answer](https://stackoverflow.com/a/29970448).

## Usage

Add these near the top of the workflow:

```yaml
- uses: actions/cache@v4
  with:
    path: ~/.m2/repository
    key: ${{ runner.os }}-maven-build # Or any other key you want
- uses: twosigma/maven-cache-cleaner@v1
```

Any files not accessed within the `~/.m2` directory after the `twosigma/maven-cache-cleaner` step will be deleted at the end of the action, before `actions/cache` saves the directory.

## Developer Guide

### Setup

```console
just install
```

Run all the pre-commit checks (format, lint, typecheck, build, package, and pre-commit hooks):

```console
just precommit
```

Make sure to run the above before committing changes, or the GitHub action will fail.
