# Installation

After checking out the [dependencies](deps.md),
download `zpy.plugin.zsh` and source it in your `.zshrc`.

You might use `git`, `wget`, or `curl`:

/// tab | `git`

```console
% git clone https://github.com/andydecleyre/zpy ~/.zpy
% print ". ~/.zpy/zpy.plugin.zsh" >>~/.zshrc
```

///

/// tab | `wget`

```console
% wget -O ~/.zpy.plugin.zsh https://github.com/AndydeCleyre/zpy/raw/master/zpy.plugin.zsh
% print ". ~/.zpy.plugin.zsh" >>~/.zshrc
```

///

/// tab | `curl`

```console
% curl -Lo ~/.zpy.plugin.zsh https://github.com/AndydeCleyre/zpy/raw/master/zpy.plugin.zsh
% print ". ~/.zpy.plugin.zsh" >>~/.zshrc
```

///

or install it with a plugin manager:

/// tab | Oh My Zsh

Add `zpy` to your `plugins` array in `~/.zshrc`, and

```console
% git clone https://github.com/andydecleyre/zpy $ZSH_CUSTOM/plugins/zpy
```

///

/// tab | zcomet

Put `zcomet load andydecleyre/zpy` in `~/.zshrc` (between `. /path/to/zcomet.zsh` and `zcomet compinit`)

///

/// tab | Zim

```console
% print zmodule andydecleyre/zpy >>~/.zimrc
% zimfw install
```

///

/// tab | yadm

```console
% yadm submodule add git@github.com:andydecleyre/zpy ~/.zpy
% print ". ~/.zpy/zpy.plugin.zsh" >>~/.zshrc
```

///

/// tab | Zinit

```console
% print zinit light andydecleyre/zpy >>~/.zshrc
```

///

/// tab | Zsh for Humans

Add to `~/.zshrc`:

- `z4h install AndydeCleyre/zpy` (before `z4h init`)
- `z4h load AndydeCleyre/zpy` (after `z4h init`)

///

/// tab | antibody

```console
% print antibody bundle andydecleyre/zpy >>~/.zshrc
```

///

/// tab | antidote

```console
% print andydecleyre/zpy >>~/.zsh_plugins.txt
```

///

/// tab | Antigen

Put `antigen bundle andydecleyre/zpy` in your `~/.zshrc`, before `antigen apply`.

///

/// tab | Prezto

Add `zpy` to your pmodule list in `~/.zpreztorc`, and

```console
% git clone https://github.com/andydecleyre/zpy $ZPREZTODIR/modules/zpy
```

///

/// tab | Sheldon

```console
$ sheldon add zpy --github andydecleyre/zpy
```

///

/// tab | zgen

Put `zgen load andydecleyre/zpy` in the plugin section of your `~/.zshrc`, then

```console
% zgen reset
```

///

/// tab | zgenom

Put `zgenom load andydecleyre/zpy` in the plugin section of your `~/.zshrc`, then

```console
% zgenom reset
```

///

/// tab | znap

```console
% print znap source andydecleyre/zpy >>~/.zshrc
```

///

/// tab | zplug

Put `zplug "andydecleyre/zpy"` in `~/.zshrc` (between `. ~/.zplug/init.zsh` and `zplug load`), then

```console
% zplug install; zplug load
```

///

/// tab | zpm

```console
% print zpm load andydecleyre/zpy >>~/.zshrc
% zpm clean
```

///

/// tip

Don't use a plugin manager but want to try one now?
I suggest [zcomet](https://github.com/agkozak/zcomet).

///

After restarting your shell,
it is recommended to install [uv](https://github.com/astral-sh/uv/):

```console
% exec zsh
% pipz install uv
```
