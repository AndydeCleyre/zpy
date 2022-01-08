# Existing Projects

Let's clone [`fastapi`](https://github.com/tiangolo/fastapi),
which uses a `pyproject.toml` without `setup.py` or `requirements.txt`:

```console
% git clone https://github.com/tiangolo/fastapi
% cd fastapi
% envin
```

Since no `(*-)requirements.txt` files were found,
`envin` has not installed the project's dependencies.

You *may* compile a `requirements.txt` directly from `pyproject.toml`:

```console
[venv] % pipcs pyproject.toml -- -o requirements.txt --extra dev,test
```

But the resulting lockfile doesn't include `fastapi` itself.

It's recommended to instead create a `requirements.in`,
referencing the current project:

```console
[venv] % pipacs '-e .[dev,test]'
```

If a project uses a `requirements.txt` already,
you can use `pips` or `envin` to "sync" to that specification
(without any `requirements.in` file).
While using pip-tools' `pip-sync` on a non-`pip-compile`d `requirements.txt` is
[not currently recommended](https://github.com/jazzband/pip-tools/issues/896),
`zpy`'s version of "syncing" ensures the dependencies of each needed package are installed,
even if not directly present in `requirements.txt`.
