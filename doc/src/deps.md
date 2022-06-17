# Dependencies

The primary requirements are Zsh, Python, and [`fzf`](https://github.com/junegunn/fzf),
with optional additions for more colorful output and alternative json parsers.

## Suggested Dependencies by Platform

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
    $ sudo apt --no-install-recommends install bat fzf python3{,-venv} wget zsh
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

!!! note

    Either `highlight` or `bat` are included in each of these commands, but are strictly optional.

## All Dependencies

=== "The big ones"

    - [Zsh](https://repology.org/project/zsh/versions)
    - [Python](https://repology.org/project/python/versions)
    - [`fzf`](https://github.com/junegunn/fzf)

=== "The optional ones"

    - [highlight](https://repology.org/project/highlight/versions)
      *or* [bat](https://repology.org/project/bat/versions)
      *or* [rich-cli](https://github.com/Textualize/rich-cli)
      -- for pretty syntax highlighting; rich-cli adds fancy tables
    - [riff](https://github.com/walles/riff)
      *or* [delta](https://github.com/dandavison/delta)
      *or* [diff-so-fancy](https://github.com/so-fancy/diff-so-fancy)
      *or* [colordiff](https://repology.org/project/colordiff/versions)
      -- for more pretty syntax highlighting
    - [jq](https://repology.org/project/jq/versions)
      *or* [jello](https://pypi.org/project/jello/)
      -- for theoretically more reliable parsing
    - [zsh-defer](https://github.com/romkatv/zsh-defer)
      -- for caching help content to eliminate a small delay in the first help message

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
