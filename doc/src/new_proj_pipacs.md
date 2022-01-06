# Install a dependency with `pipacs`

The `acs` in `pipacs` is for "add, compile, sync."

Instead of using `pip install` to add a library,
beautifulsoup4,
to our new project,
we'll use `pipacs` to:

- *add* a new line "`beautifulsoup4`" to `./requirements.in`
- *compile* (as [pip-tools](https://github.com/jazzband/pip-tools) uses the term)
  our `./requirements.in` into a fully version-locked, line-oriented `./requirements.txt`
- *sync* (again, the pip-tools term) our current environment to the compiled lockfile --
  install everything as listed in `requirements.txt` *and* uninstall everything else

```console
(venv) $ pipacs beautifulsoup4
> appending -> requirements.in :: ~/newproj
beautifulsoup4
> compiling requirements.in -> requirements.txt :: ~/newproj
```
```ini
beautifulsoup4==4.10.0    # via -r requirements.in
soupsieve==2.2.1          # via beautifulsoup4
```
```console
> syncing requirements.txt -> env :: ~/newproj
```

Being such a popular package,
we were able to tab-complete the name `beautifulsoup4`,
reducing the risk of mistyping.
The complete-able package list comes from
[hugovk/top-pypi-packages](https://github.com/hugovk/top-pypi-packages).

Then, the active venv's installed packages are synced to match that lockfile.

## When `pipacs` does too much

You won't always want to add, compile, and sync all at once.
Some closely related `zpy` functions are
`pipa`, `pipc`, `pips`, `pipac`, and `pipcs`.

All of their `--help` outputs,
as for any set of `zpy` functions, can be viewed at once,
by providing them as arguments to the `zpy` function:

```console
$ zpy pipa pipc pips pipac pipcs
```

Without any arguments, running `zpy` displays help for *all* `zpy` functions.

```console
$ zpy pipacs
```
```shell
# Add to requirements.in, compile it to requirements.txt, then sync to that (add, compile, sync).
# Use -c to affect categorized requirements, and -h to include hashes.
pipacs [-c <category>] [-h] <pkgspec>... [-- <pip-compile-arg>...]
```
