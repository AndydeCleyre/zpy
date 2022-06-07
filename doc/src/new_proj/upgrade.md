# Upgrade dependencies

If you want to upgrade the locked versions of specific dependencies,
you can pass `-u <comma-separated-list>` to `pipcs` or `pipc`:

```console
[venv] % pipcs -u pre-commit
```

To upgrade *all* dependencies in a group or across groups,
pass `-U`:

```console
[venv] % pipcs -U
```

---

```console
% zpy help pipc pipcs
```
```shell
# Compile requirements.txt files from all found or specified requirements.in files (compile).
# Use -h to include hashes, -u dep1,dep2... to upgrade specific dependencies, and -U to upgrade all.
pipc [-h] [-U|-u <pkgspec>[,<pkgspec>...]] [<reqs-in>...] [-- <pip-compile-arg>...]

# Compile, then sync.
# Use -h to include hashes, -u dep1,dep2... to upgrade specific dependencies, and -U to upgrade all.
pipcs [-h] [-U|-u <pkgspec>[,<pkgspec>...]] [--only-sync-if-changed] [<reqs-in>...] [-- <pip-compile-arg>...]
```

---

## Upgrade in a subshell

Unlike `pipcs`, `pipup` activates a project's venv within a subshell,
without affecting the current user shell. Some examples:

```console
% pipup     # like pipcs -U in a subshell
% pipup -i  # interactively choose one or more projects
```

`pipcheckold` works the same way,
allowing you to check which dependencies are outdated
in any number of projects,
without affecting your shell's environment.

---

```console
% zpy help pipup pipcheckold
```
```shell
# 'pipcs -U' (upgrade-compile, sync) in a venv-activated subshell for the current or specified folders.
# Use --all to instead act on all known projects, or -i to interactively choose.
pipup [--py pypy|current] [--only-sync-if-changed] [--all|-i|<proj-dir>...]

# 'pip list -o' (show outdated) for the current or specified folders.
# Use --all to instead act on all known projects, or -i to interactively choose.
pipcheckold [--py pypy|current] [--all|-i|<proj-dir>...]
```

---
