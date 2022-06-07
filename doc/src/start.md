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

!!! tip

    You can flip through these docs with `n` and `p`, or `.` and `,`.
