# Categorize dependencies

The `ac` in `pipac` is for "add, compile."

`pipac` takes the same arguments as `pipacs`,
but does not affect the current venv,
as it *adds* and *compiles* without *syncing*.

Let's add a popular development tool,
[pre-commit](https://pre-commit.com/),
to our project's definition,
without installing it:

```console
[venv] % pipac -c dev pre-commit
```

This time, we used `-c` to specify a *category*.
The effect is that the files written are
`dev-requirements.in` and `dev-requirements.txt`.

Tab completion will suggest the categories `dev`, `doc`, and `test`,
but any arbitrary name can be used.

---

```console
% pipac --help
```
```shell
# Add to requirements.in, then compile it to requirements.txt (add, compile).
# Use -c to affect categorized requirements, and -h to include hashes.
pipac [-c <category>] [-h] <pkgspec>... [-- <pip-compile-arg>...]
```

---

!!! tip "Tips"

    - One input file can "include" another input or output file,
      if one of its lines is `-r PATH/TO/REQSFILE`
    - Similarly, the allowable versions of packages can be "constrained" with
      `-c PATH/TO/REQUIREMENTS.TXT`
