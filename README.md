# Yarn Version Manager written in Fish :fish:

## Quickstart

```shell
fisher add cideM/fish-vym
yvm use latest
```

## Installation

### Fisher

Install with [Fisher](https://github.com/jorgebucaran/fisher) (recommended):

```shell
fisher add cideM/fish-yvm
```

### Manual

This assumes that you're fish config folder is located under `~/.config/fish`

```shell
curl https://raw.githubusercontent.com/cideM/fish-yvm/master/functions/yvm.fish\
  -o ~/.config/fish/functions/yvm.fish
```

## Usage

### `use <version>`

Installs and activates given version of `yarn`. Version needs to exactly match one of the versions returned from `yvm ls`. The only exception to this rule is that `latest` will always install the most recent `yarn` version. Takes an optional `-f` or `--force-fetch` flag, which forces fetching the list of available resources from remote. If not the list is only updated if it's older than 120s.

List of releases is stored under `$XDG_CONFIG_HOME/yvm-fish` (for most people this will be `~/.config/yvm-fish`.

The currently active version is stored under `$XDG_CONFIG_HOME/version`.

Example:

```fish
yvm use 1.19.0
```

### `ls`/`list`

Lists all available `yarn` releases. Takes the same `-f` flag as `use`, with the same caching behavior. If you want to only see the installed versions, just pipe the output into something like `grep`.

Examples:

```shell
yvm ls | grep installed
yvm ls | grep active
```

```fish
$ yvm ls | head -n 5
1.19.1   installed       active
1.19.0   installed
1.18.0
1.17.3
1.17.2
```

### `rm <version>`

Removes specified version from file system and PATH. Same version matching rules as for `use` apply, including `latest`.

Example:

```fish
yvm rm 1.19.0
```
