# `just --list --unsorted`
[group('default')]
default:
    @just --list --unsorted

ci := env("CI", "")
_ci := if ci != "" { ":ci" } else { "" }

# `npm install` or `npm ci`
[group('setup')]
install:
    {{ if ci != "" { "npm ci" } else { "npm install --legacy-peer-deps" } }}

# Run Oxlint
oxlint: install
    npm run oxlint:ci

# Check formatting with Oxfmt
fmt: install
    npm run fmt:ci

# Type-check the project
typecheck: install
    npm run build

# Package the action
package: install
    npm run package

# Run all pre-commit checks
precommit: oxlint fmt typecheck package
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
