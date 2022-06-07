# Install a dependency

The `acs` in `pipacs` is for "add, compile, sync."

Instead of using `pip install` directly to add a library,
beautifulsoup4,
to our new project,
we'll use `pipacs` to:

- *add* a new line "`beautifulsoup4`" to `./requirements.in`
- *compile* (as [pip-tools](https://github.com/jazzband/pip-tools) uses the term)
  our `./requirements.in` into a fully version-locked, line-oriented `./requirements.txt`
- *sync* (again, the pip-tools term) our current environment to the compiled lockfile --
  install everything as listed in `requirements.txt` *and* uninstall everything else

```console
[venv] % pipacs beautifulsoup4
```

![Animated demo: pipacs](https://gist.githubusercontent.com/AndydeCleyre/b422097e220806b31c4d1c80ed0ed6b5/raw/ee65dd02265b3e5e7b85996bc6dfd22175a3b78c/guide_pipacs.svg?sanitize=true)

Being such a popular package,
we were able to tab-complete the name `beautifulsoup4`,
reducing the risk of mistyping.
The complete-able package list comes from
[hugovk/top-pypi-packages](https://github.com/hugovk/top-pypi-packages).

## When `pipacs` does too much

You won't always want to add, compile, and sync all at once.
Some closely related `zpy` functions are
`pipa`, `pipc`, `pips`, `pipac`, and `pipcs`.

All of their `--help` outputs,
as for any set of `zpy` functions, can be viewed at once,
by providing them as arguments to the `zpy help` subcommand:

```console
% zpy help pipa pipc pips pipac pipcs
```

Without any arguments, running `zpy help` displays help for *all* `zpy` functions.

---

```console
% zpy help pipacs
```
```shell
# Add to requirements.in, compile it to requirements.txt, then sync to that (add, compile, sync).
# Use -c to affect categorized requirements, and -h to include hashes.
pipacs [-c <category>] [-h] <pkgspec>... [-- <pip-compile-arg>...]
```

---

!!! tip

    When a zpy function internally calls `pip-compile`,
    it provides these flags by default:
    ```shell
    --no-header --annotation-style=line --strip-extras --allow-unsafe
    ```
    You can *add* `pip-compile` flags in a particular instance using the double dash syntax, like:
    ```console
    % pipc -- --no-annotate --verbose
    ```
    You can also *replace* those default flags for the current shell (or in your `~/.zshrc`) using `zstyle`, like:
    ```console
    % zstyle ':zpy:*' pip-compile-args --header --annotation-style=split
    ```
