# textlint mirror

Mirror of textlint package for pre-commit.

For pre-commit: see https://github.com/pre-commit/pre-commit

For textlint: see https://github.com/textlint/textlint

## Using textlint with pre-commit

Add this to your `.pre-commit-config.yaml`:

```yml
- repo: https://github.com/wate/pre-commit-mirrors-textlint
  rev: ''  # Use the sha / tag you want to point at
  hooks:
    - id: textlint
```
