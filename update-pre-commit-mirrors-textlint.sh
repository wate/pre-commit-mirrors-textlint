#!/usr/bin/env bash
# Update this mirror repository to the published textlint versions.
#
# For every version published after the one recorded in .version:
#   1. rewrite .pre-commit-hooks.yaml with the pinned textlint version
#   2. update .version
#   3. commit the two files and tag the commit as v<version>
#
# Only git is required (no pre-commit-mirror dependency).
set -eu

cd "$(dirname "$0")"

package=textlint
hooks_file=.pre-commit-hooks.yaml
version_file=.version

command -v npm >/dev/null 2>&1 || {
    echo 'error: npm is required' >&2
    exit 1
}

current=$(cat "$version_file")

# Published versions in release order (works with both npm 11 and npm 12).
versions=$(
    npm view "$package" versions --json |
        sed -e 's/[][]//g' -e 's/"//g' -e 's/[[:space:]]//g' |
        tr ',' '\n'
)

[ -n "$versions" ] || {
    echo "error: failed to fetch published versions of $package" >&2
    exit 1
}

write_hooks() {
    cat > "$hooks_file" <<EOF
-   id: textlint
    name: textlint
    description: ''
    entry: textlint
    language: node
    types: [markdown]
    additional_dependencies: ["textlint@$1"]
EOF
}

found=0
applied=0
while IFS= read -r version; do
    [ -n "$version" ] || continue

    if [ "$found" -eq 0 ]; then
        if [ "$version" = "$current" ]; then
            found=1
        fi
        continue
    fi

    if git rev-parse -q --verify "refs/tags/v$version" >/dev/null 2>&1; then
        echo "error: tag v$version already exists" >&2
        exit 1
    fi

    printf '%s\n' "$version" > "$version_file"
    write_hooks "$version"
    git add -- "$version_file" "$hooks_file"
    git commit -q -m "Mirror: $version"
    git tag "v$version"
    applied=$((applied + 1))
    echo "Mirror: $version"
done <<EOF
$versions
EOF

if [ "$found" -eq 0 ]; then
    echo "error: $current is not a published version of $package" >&2
    exit 1
fi

if [ "$applied" -eq 0 ]; then
    echo "$package is up to date ($current)"
fi
