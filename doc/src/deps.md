# Dependencies

The primary requirements are Zsh, Python, and
[`fzf`](https://github.com/junegunn/fzf) *or* [`sk` (skim)](https://github.com/skim-rs/skim),
with optional additions for more colorful output, alternative json parsers, and faster performance.

## Suggested Dependencies by Platform

=== "Alpine"

    ```console
    $ sudo apk add fzf pcre2-tools python3 zsh
    ```

=== "Arch"

    ```console
    $ sudo pacman -S --needed fzf python zsh
    ```

=== "Debian/Ubuntu"

    ```console
    $ sudo apt --no-install-recommends install fzf python3{,-venv} wget zsh
    ```

=== "Fedora"

    ```console
    $ sudo dnf --setopt=install_weak_deps=False install diffutils fzf python3 zsh
    ```

=== "MacOS"

    ```console
    $ brew install fzf pcre2 python zsh
    ```

=== "OpenSUSE"

    ```console
    $ sudo zypper in curl diffutils fzf python3 zsh
    ```

## All Dependencies

=== "The big ones"

    - [Zsh](https://repology.org/project/zsh/versions)
    - [Python](https://repology.org/project/python/versions)
    - [`fzf`](https://github.com/junegunn/fzf) *or* [`sk` (skim)](https://github.com/skim-rs/skim)

=== "The optional ones"

    - [uv](https://github.com/astral-sh/uv/)
      -- for faster performance, leaner venvs, and more operational feedback
    - [highlight](https://repology.org/project/highlight/versions)
      *or* [gat](https://github.com/koki-develop/gat/)
      *or* [bat](https://repology.org/project/bat/versions)
      *or* [rich-cli](https://github.com/Textualize/rich-cli)
      -- for pretty syntax highlighting; rich-cli adds fancy tables
    - [riff](https://github.com/walles/riff)
      *or* [diffr](https://github.com/mookid/diffr)
      *or* [delta](https://github.com/dandavison/delta)
      *or* [diff-so-fancy](https://github.com/so-fancy/diff-so-fancy)
      *or* [colordiff](https://repology.org/project/colordiff/versions)
      -- for more pretty syntax highlighting
    - [jq](https://repology.org/project/jq/versions)
      *or* [wheezy.template](https://github.com/akornatskyy/wheezy.template)
      -- for faster JSON parsing
    - [jq](https://repology.org/project/jq/versions)
      *or* [dasel](https://github.com/TomWright/dasel)
      -- for faster JSON writing
    - [zsh-defer](https://github.com/romkatv/zsh-defer)
      -- for caching help content to eliminate a small delay in the first help message

    !!! tip

        Some of these can be installed after installing zpy, with zpy's `pipz` command:

        ```console
        % pipz install uv rich-cli wheezy.template
        ```

=== "The ones you already have anyway, probably"

    - `du`, `mktemp`, `md5sum` *or* `md5`, and `nproc` *or* `sysctl` -- provided by
      [coreutils](https://repology.org/project/coreutils/versions),
      [busybox](https://repology.org/project/busybox/versions),
      [toybox](https://repology.org/project/toybox/versions),
      BSD,
      or macOS
    - `diff` -- provided by
      [diffutils](https://repology.org/project/diffutils/versions),
      [uutils/diffutils](https://github.com/uutils/diffutils),
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
      [ripgrep (>=14.0.0)](https://repology.org/project/ripgrep/versions),
      [ugrep](https://repology.org/project/ugrep/versions),
      or Zsh with pcre enabled
