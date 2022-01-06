# Manage installed apps with pipz, a pipx clone

[pipx](https://pypa.github.io/pipx/#overview-what-is-pipx) is an excellent tool,
written in Python, providing these features (in their words, from the link):

- Expose CLI entrypoints of packages ("apps") installed to isolated environments with the `install` command.
  This guarantees no dependency conflicts and clean uninstalls!
- Easily list, upgrade, and uninstall packages that were installed with pipx
- Run the latest version of a Python application in a temporary environment with the `run` command
- Best of all, pipx runs with regular user permissions, never calling `sudo pip install`

Well `pipz` accomplishes the same, with nearly the same interface,
using Zsh and the other zpy functions.

```console
$ pipz install tldr yt-dlp
```

```console
$ pipz list --all
```
```
projects     @ ~/.local/share/python
venvs        @ ~/.local/share/venvs
apps exposed @ ~/.local/bin

tldr    yt-dlp

Command            Package            Runtime
tldr               tldr 3.0.0         Python 3.9.7
yt-dlp             yt-dlp 2021.12.27  Python 3.9.7
```

The paths printed on the first three lines of output reflect the environment variables
`ZPY_PIPZ_PROJECTS`, 
`ZPY_VENVS_HOME`, and
`$ZPY_PIPZ_BINS`,
respectively.

```console
$ zpy pipz
```
```shell
# Package manager for venv-isolated scripts (pipx clone; py3 only).
pipz [install|uninstall|upgrade|list|inject|reinstall|cd|runpip|runpkg] [<subcmd-arg>...]
```
