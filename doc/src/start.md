# Get started

!!! tip

    You can flip through these docs with `n` and `p`, or `.` and `,`.

## Install locally

Aside from Zsh and Python, the only dependency you're likely to *need* is
[`fzf`](https://github.com/junegunn/fzf) *or* [`sk` (skim)](https://github.com/lotabout/skim).
For more details and recommended package manager commands, see [Dependencies](deps.md).

To install `zpy` itself, you only need to source the file `zpy.plugin.zsh`
in your Zsh startup (`~/.zshrc`, or sometimes `~/.config/zsh/.zshrc`).
When using a plugin manager, you'll likely need to feed it the
"`GitHub User`/`Repo Name`" format, which is "`andydecleyre/zpy`".
For more details and recommended plugin manager commands, see [Installation](install.md).

For now, let's just source it in the current session:

```console
% git clone https://github.com/andydecleyre/zpy ~/.zpy
% . ~/.zpy/zpy.plugin.zsh
```

!!! tip

    Everything zpy does will generally be much faster if uv is installed.
    You can now install it with zpy's `pipz` command:

    ```console
    % pipz install uv
    ```

## Try it in a container, instead

Using either podman or docker, launch a temporary container based on Ubuntu, Alpine, or Fedora:

=== "Ubuntu"

    ```console
    $ podman run --net=host -it --rm -e TERM=$TERM quay.io/andykluger/zpy-ubuntu:master
    $ docker run --net=host -it --rm -e TERM=$TERM quay.io/andykluger/zpy-ubuntu:master
    ```

=== "Alpine"

    ```console
    $ podman run --net=host -it --rm -e TERM=$TERM quay.io/andykluger/zpy-alpine:master
    $ docker run --net=host -it --rm -e TERM=$TERM quay.io/andykluger/zpy-alpine:master
    ```

=== "Fedora"

    ```console
    $ podman run --net=host -it --rm -e TERM=$TERM quay.io/andykluger/zpy-fedora:master
    $ docker run --net=host -it --rm -e TERM=$TERM quay.io/andykluger/zpy-fedora:master
    ```

## Functions or Subcommands

The user-facing functions are all available as subcommands to `zpy`.
Try typing `zpy`, then a space, then tab.

By default, each function is *also* available directly, as a "top-level" command[^1].
This can be **prevented** by explicitly specifying a list of functions to expose,
*before* sourcing the plugin.
This example will expose only the `pipz` and `zpy` functions
(the rest remaining available as subcommands):

```console
% zstyle ':zpy:*' exposed-funcs pipz zpy
```

[^1]: Well, except for `zpy mkbin` and `zpy help`.

## Moving on

From here, you may want to:

- continue to the [next page](new_proj.md), for an idea of how these tools can help manage a project
- jump to the [full reference](help_all.md)
- jump to [`pipz`](pipz.md), a [pipx](https://pypa.github.io/pipx/) alternative
