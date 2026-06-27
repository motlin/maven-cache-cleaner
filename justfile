# `just --list --unsorted`
[group('default')]
default:
    @just --list --unsorted

ci := env("CI", "")

# Install dependencies
[group('setup')]
install:
    vp install
    vp fmt AGENTS.md

# Run linter
lint: install
    vp lint {{ if ci != "" { "--format github" } else { "--fix" } }}

# Run formatter
format: install
    vp fmt {{ if ci != "" { "--check" } else { "" } }}

# Run checks (format + lint + typecheck)
check: install
    vp check {{ if ci != "" { "" } else { "--fix" } }}

# Type-check the project
typecheck: install
    vp run typecheck

# Build the project
build: install
    vp run build

# Package the action with ncc
package: install
    npm run package

# Run pre-commit hooks on all files (same as CI's pre-commit job)
pre-commit: install
    pre-commit run --all-files

# Run all pre-commit checks
precommit: check build package pre-commit
    @echo "All pre-commit checks passed!"

# Tag `vX.Y.Z` at HEAD, advance the major `vX` tag, push to upstream, and cut a GitHub release: `just release 2.1.0`
[group('release')]
release version: precommit
    #!/usr/bin/env bash
    set -euo pipefail
    ver="{{ version }}"
    [[ "$ver" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || { echo "version must be X.Y.Z, e.g. just release 2.1.0" >&2; exit 1; }
    tag="v$ver"
    major="${tag%%.*}"
    git diff --quiet && git diff --cached --quiet || { echo "working tree is dirty; commit or stash first" >&2; exit 1; }
    git fetch upstream
    if [[ "$(git rev-parse HEAD)" != "$(git rev-parse upstream/main)" ]]; then
        echo "HEAD is not at upstream/main; push your commits to upstream before releasing" >&2
        exit 1
    fi
    git tag -a "$tag" -m "$tag"
    git tag -f "$major"
    git push upstream "$tag"
    old="$(git ls-remote upstream "refs/tags/$major" | cut -f1)"
    git push upstream --force-with-lease="refs/tags/$major:${old}" "$major:refs/tags/$major"
    gh release create "$tag" --repo twosigma/maven-cache-cleaner --title "$tag" --generate-notes
    echo "Released $tag; $major now points to $(git rev-parse --short HEAD)"
