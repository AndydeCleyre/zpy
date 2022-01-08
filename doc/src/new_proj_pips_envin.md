# Selectively *sync* with `pips` and `envin`

Now that we've got a combination of plain
and categorized dependencies,
we may wish to *sync* our venv state to match
either or both:

```console
[venv] % pips requirements.txt      # install regular deps, uninstall dev deps
[venv] % pips dev-requirements.txt  # install dev deps, uninstall regular deps
[venv] % pips requirements.txt dev-requirements.txt  # install multiple dep groups
[venv] % pips                                        # install all dep groups
```

You may also use `envin` as a drop-in replacement for `pips` in the above examples,
which will both activate a venv (creating it if necessary)
*and* sync according to all or specified lockfiles.

`pipc` and `pipcs` deal with dependency groups the same way,
as zero or more file arguments,
but expect the respective `requirements.in` files
rather than the `requirements.txt` lockfiles.

## `activate` vs `envin`

The functions `activate` (alias `a8`) and `envin`
are similar; each one activates a venv for your current shell,
first creating it if necessary.

If you were to use `envin` at the beginning of these docs rather than `activate`,
your system would be in exactly the same state.

So how do they differ?

### The project folder:

- `envin` *always* operates on a venv associated with the *current folder*
- `activate` uses the current folder *by default*,
  but *also* accepts a *project path argument*,
  or `-i` to *select the project* folder interactively

### Existing venv behavior:

- `envin` *always* syncs the venv according to `requirements.txt` files
- `activate` *only* syncs when creating a *new venv*;
  otherwise, it's activated *as-is*

### Dependency groups (`<category>-requirements.txt`):

- `activate`, when syncing at all, *always* syncs according to *all* `requirements.txt` files
- `envin` syncs according to *all* `requirements.txt` files *by default*,
  but *also* accepts any number of *lockfile arguments*, just like `pips`

---

```console
% zpy activate envin
```
```shell
# Activate the venv for the current folder or specified project, if it exists.
# Otherwise create, activate, sync.
# Pass -i to interactively choose the project.
# Pass --py to use another interpreter and named venv.
activate [--py 2|pypy|current] [-i|<proj-dir>]

# Activate the venv (creating if needed) for the current folder, and sync its
# installed package set according to all found or specified requirements.txt files.
# In other words: [create, ]activate, sync.
# The interpreter will be whatever 'python3' refers to at time of venv creation, by default.
# Pass --py to use another interpreter and named venv.
envin [--py 2|pypy|current] [<reqs-txt>...]
```

---

# Deactivation

These are standard Python virtual environments,
and so can be deactivated with:

```console
[venv] % deactivate
```

For symmetry with `a8` and `envin`, `zpy` adds two aliases for the same command:
`da8` and `envout`.
