# Create a venv with `activate`

```console
$ activate  # there's also an alias: a8
> creating -> ~/.local/share/venvs/f43…/venv :: ~/newproj
(venv) $
```

Congrats, you've created a virtual environment and activated it for your current shell!

The project folder remains empty, with the venv tucked away
at a location determined by a hash of the absolute path of the project.
The home for all of these (`~/.local/share/venvs`) may be overridden
by setting the environment variable `ZPY_VENVS_HOME` or `XDG_DATA_HOME`.

If you want to access it as `./venv` (e.g. for another tool to easily find),
run:

```console
(venv) $ ln -s $VIRTUAL_ENV
```

There's a bit more to `activate` if you need it;
like all `zpy` commands,
it's documented via a `--help` flag as well as
what aims to be *thorough* tab completion assistance.

```console
$ activate --help
```
```shell
# Activate the venv for the current folder or specified project, if it exists.
# Otherwise create, activate, sync.
# Pass -i to interactively choose the project.
# Pass --py to use another interpreter and named venv.
activate [--py 2|pypy|current] [-i|<proj-dir>]
```
