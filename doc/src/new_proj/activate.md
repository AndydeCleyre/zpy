# Create a venv

```console
% activate  # there's also an alias: a8
```

Congrats, you've created a virtual environment and activated it for your current shell!

!!! tip

    Like all `zpy` commands, it can alternatively be invoked as a subcommand:

    ```shell
    % zpy activate
    ```

The project folder remains empty, with the venv tucked away
at a location determined by a hash of the absolute path of the project.
The home for all of these (`~/.local/share/venvs`) may be overridden
by setting the environment variable `ZPY_VENVS_HOME` or `XDG_DATA_HOME`.

If you want to access it as `./venv` (e.g. for another tool to easily find),
run:

```console
[venv] % ln -s $VIRTUAL_ENV
```

There's a bit more to `activate` if you need it;
like all `zpy` commands,
it's documented via a `--help` flag as well as
what aims to be *thorough* tab completion assistance.

---

```console
% # These are all equivalent:
% activate --help
% zpy activate --help
% zpy help activate
```
```shell
# Activate the venv for the current folder or specified project, if it exists.
# Otherwise create, activate, sync.
# Pass -i to interactively choose the project.
# Pass --py to use another interpreter and named venv.
activate [--py pypy|current] [-i|<proj-dir>]
```

---
