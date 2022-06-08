# Manage installed apps

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
% pipz install tldr yt-dlp
% pipz list --all
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

The paths printed on the first three lines of output may be overridden with the environment variables
`ZPY_PIPZ_PROJECTS`,
`ZPY_VENVS_HOME`, and
`ZPY_PIPZ_BINS`,
respectively.

![Animated demo: pipz install, list](https://gist.github.com/AndydeCleyre/5ad45d78336fc2cc4625b0dc6b450849/raw/777e77607786beb65b2d6e00fb27c507c5e7abfa/pipz_install_list.svg?sanitize=true)

!!! note

    The last frame is mangled in this animation, but not in real usage.

Example installing an app package from git:

```console
% pipz install 'subdl @ git+https://github.com/alexanderwink/subdl'
```

---

If you track your dotfiles, you might include `~/.local/share/python`,
which only has `<pkgname>/requirements.{in,txt}` files.
With those in place, you can run `pipz reinstall` to get the apps back.

---

```console
% zpy help pipz
```
```shell
# Package manager for venv-isolated scripts (pipx clone).
pipz [install|uninstall|upgrade|list|inject|reinstall|cd|runpip|runpkg] [<subcmd-arg>...]
```

---
