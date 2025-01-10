# Completions

If you've been using Zsh, you probably have completions already set up,
either manually or with a framework.

If not, at a minimum you'll want this line in your `~/.zshrc`,
somewhere before loading zpy:

```shell {title=".zshrc"}
autoload -Uz compinit && compinit
```

I'll also recommend:

```shell {title=".zshrc"}
zstyle ':completion:*' menu select
```

Some functions allow you to pass arguments through to other tools,
like `pip`, `pip-compile`, and `uv`.
Completion will work for those if you install their own completion definitions.

If using `uv`, neither `pip` nor `pip-compile` will be relevant.

`uv` completion is installed by creating a `_uv` file
in one of your `$fpath` folders (usually `~/.local/share/zsh/site-functions`):

```console
% uv generate-shell-completion zsh >~/.local/share/zsh/site-functions/_uv
```

You can check for appropriate `$fpath` folders with:

```console
% print -rl -- ${(M)fpath:#*/$USER/*}
```
