# Completions

If you've been using Zsh, you probably have completions already set up,
either manually or with a framework.

If not, at a minimum you'll want this in your `~/.zshrc`,
somewhere before loading zpy:

```shell
autoload -Uz compinit && compinit
```

Some functions allow you to pass arguments through to other tools,
like `pip`, `pip-compile`, and `uv`.
Completion will work for those if you install their own completion definitions.

If using `uv`, neither `pip` nor `pip-compile` will be relevant.

`uv` completion can be installed with something like the following,
depending on your `$fpath`:

```console
% uv generate-shell-completion zsh >~/.local/share/zsh/site-functions/_uv
```

You can check for appropriate folders with:

```console
% print -rl -- $fpath
```

Filter to .../username/... paths for the most likely candidates:

```console
% print -rl -- ${(M)fpath:#*/$USER/*}
```
