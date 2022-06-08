# Get started

Aside from Zsh and Python, the only dependency you're likely to *need* is
[`fzf`](https://github.com/junegunn/fzf).
For more details and recommended package manager commands, see [Dependencies](deps.md).

To install `zpy` itself, you only need to source the file `zpy.plugin.zsh`
in your Zsh startup (`~/.zshrc`).
When using a plugin manager, you'll likely need to feed it the
"`GitHub User`/`Repo Name`" format, which is "`andydecleyre/zpy`".
For more details and recommended plugin manager commands, see [Installation](install.md).

For now, let's just source it in the current session:

```console
% git clone https://github.com/andydecleyre/zpy ~/.zpy
% . ~/.zpy/zpy.plugin.zsh
```

The user-facing functions are all available as subcommands to `zpy`.
Try typing `zpy`, then a space, then tab.

!!! info

    By default, each function is *also* available directly, as a "top-level" command[^1].
    This can be prevented by explicitly specifying a list of functions to expose,
    *before* sourcing the plugin.
    This example will expose only the `pipz` and `zpy` functions
    (the rest remaining available as subcommands):

    ```console
    % zstyle ':zpy:*' exposed-funcs pipz zpy
    ```

[^1]: Well, except for `zpy mkbin` and `zpy help`.

From here, you may want to:

- continue to the [next page](new_proj.md), for an idea of how these tools can help manage a project
- jump to the [full reference](help_all.md)
- jump to [`pipz`](pipz.md), a [pipx](https://pypa.github.io/pipx/) alternative

!!! tip

    You can flip through these docs with `n` and `p`, or `.` and `,`.
