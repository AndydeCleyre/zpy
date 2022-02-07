# Dependencies

The primary requirements are Zsh, Python, and [`fzf`](https://github.com/junegunn/fzf),
with optional additions for minor enhancements or Python2 support.

## Suggested Dependencies by Platform

In all cases, `highlight` is optional.

=== "Alpine"

    ```console
    $ sudo apk add fzf highlight pcre2-tools python3 zsh
    ```

=== "Arch"

    ```console
    $ sudo pacman -S --needed fzf highlight python zsh
    ```

=== "Debian/Ubuntu"

    ```console
    $ sudo apt --no-install-recommends install fzf highlight python3{,-venv} wget zsh
    ```

=== "Fedora"

    ```console
    $ sudo dnf --setopt=install_weak_deps=False install diffutils fzf highlight python3 zsh
    ```

=== "MacOS"

    ```console
    $ brew install fzf highlight pcre2 python zsh
    ```

=== "OpenSUSE"

    ```console
    $ sudo zypper in curl diffutils fzf highlight python3 zsh
    ```

## All Dependencies

=== "The big ones"

    - [Zsh](https://repology.org/project/zsh/versions)
    - [Python](https://repology.org/project/python/versions)
    - [`fzf`](https://github.com/junegunn/fzf)

=== "The ones you already have anyway, probably"

    - `du`, `mktemp`, `md5sum` *or* `md5`, and `nproc` *or* `sysctl` -- provided by
      [coreutils](https://repology.org/project/coreutils/versions),
      [busybox](https://repology.org/project/busybox/versions),
      [toybox](https://repology.org/project/toybox/versions),
      BSD,
      or macOS
    - `diff` -- provided by
      [diffutils](https://repology.org/project/diffutils/versions),
      [busybox](https://repology.org/project/busybox/versions),
      BSD,
      or macOS
    - `wget` *or* `curl` -- provided by
      [wget](https://repology.org/project/wget/versions),
      [curl](https://repology.org/project/curl/versions),
      [busybox](https://repology.org/project/busybox/versions),
      or macOS
    - a pcre tool -- provided by
      pcregrep/pcre-tools,
      pcre2grep/pcre2-tools,
      [ripgrep](https://repology.org/project/ripgrep/versions),
      or Zsh with pcre enabled

=== "The optional ones"

    - [highlight](https://repology.org/project/highlight/versions)
      *or* [bat](https://repology.org/project/bat/versions)
      -- for pretty syntax highlighting
    - [delta](https://github.com/dandavison/delta)
      *or* [diff-so-fancy](https://github.com/so-fancy/diff-so-fancy)
      *or* [riff](https://github.com/walles/riff)
      *or* [colordiff](https://repology.org/project/colordiff/versions)
      -- for more pretty syntax highlighting
    - [jq](https://repology.org/project/jq/versions)
      *or* [jello](https://pypi.org/project/jello/)
      -- for theoretically more reliable parsing
    - Python2 *and* [virtualenv](https://repology.org/project/python:virtualenv/versions)
      -- for Python2 support (such as it is)
    - [Git](https://git-scm.com/)
      -- for easy installation of zpy itself
