# Full Reference

```shell
# Optional launcher for all zpy functions as subcommands
zpy <function> [<function-arg>...]

# Print description and arguments for all or specified functions.
zpy help [<zpy-function>...]
```

## Environment Activation

=== "`envin`"

    ```shell
    # Activate the venv (creating if needed) for the current folder, and sync
    # its installed package set according to all found or specified requirements.txt files.
    # In other words: [create, ]activate, sync.
    # The interpreter will be whatever 'python3' refers to at time of venv creation, by default.
    # Pass --py to use another interpreter and named venv.
    envin [--py pypy|current] [<reqs-txt>...]
    ```

=== "`activate`"

    ```shell
    # Activate the venv for the current folder or specified project, if it exists.
    # Otherwise create, activate, sync.
    # Pass -i to interactively choose the project.
    # Pass --py to use another interpreter and named venv.
    activate [--py pypy|current] [-i|<proj-dir>]
    ```

    ```shell
    # Alias for 'activate'.
    a8 [--py pypy|current] [-i|<proj-dir>]
    ```

=== "`deactivate`"

    ```shell
    # Alias for 'deactivate'.
    envout
    ```

    ```shell
    # Another alias for 'deactivate'.
    da8
    ```

## Add, Compile, Sync

=== "Add[, Compile[, Sync]]"

    ```shell
    # Add loose requirements to [<category>-]requirements.in (add).
    pipa [-c <category>] <pkgspec>...
    ```

    ```shell
    # Add to requirements.in, then compile it to requirements.txt (add, compile).
    # Use -c to affect categorized requirements, and -h to include hashes.
    pipac [-c <category>] [-h] <pkgspec>... [-- <pip-compile-arg>...]
    ```

    ```shell
    # Add to requirements.in, compile it to requirements.txt, then sync to that (add, compile, sync).
    # Use -c to affect categorized requirements, and -h to include hashes.
    pipacs [-c <category>] [-h] <pkgspec>... [-- <pip-compile-arg>...]
    ```

    ```shell
    # Inject loose requirements.in dependencies into a PEP 621 pyproject.toml.
    # Run either from the folder housing pyproject.toml, or one below.
    # To categorize, name files <category>-requirements.in.
    pypc [-y]
    ```

=== "Compile[, Sync]"

    ```shell
    # Compile requirements.txt files from all found or specified requirements.in files (compile).
    # Use -h to include hashes, -u dep1,dep2... to upgrade specific dependencies, and -U to upgrade all.
    pipc [-h] [-U|-u <pkgspec>[,<pkgspec>...]] [<reqs-in>...] [-- <pip-compile-arg>...]
    ```

    ```shell
    # Compile, then sync.
    # Use -h to include hashes, -u dep1,dep2... to upgrade specific dependencies, and -U to upgrade all.
    pipcs [-h] [-U|-u <pkgspec>[,<pkgspec>...]] [--only-sync-if-changed] [<reqs-in>...] [-- <pip-compile-arg>...]
    ```

    ```shell
    # 'pipcs -U' (upgrade-compile, sync) in a venv-activated subshell for the current or specified folders.
    # Use --all to instead act on all known projects, or -i to interactively choose.
    pipup [--py pypy|current] [--only-sync-if-changed] [--all|-i|<proj-dir>...]
    ```

=== "Sync"

    ```shell
    # Install packages according to all found or specified requirements.txt files (sync).
    pips [<reqs-txt>...]
    ```

## Launch Helpers

=== "`vpyshebang`"

    ```shell
    # Prepend each script with a shebang for its folder's associated venv interpreter.
    # If 'vpy' exists in the PATH, '#!/path/to/vpy' will be used instead.
    # Also ensures the script is executable.
    # --py may be used, same as for envin.
    vpyshebang [--py pypy|current] <script>...
    ```

=== "`vrun`"

    ```shell
    # Run command in a subshell with <venv>/bin for the given project folder prepended to the PATH.
    # Use --cd to run the command from within the project folder.
    # --py may be used, same as for envin.
    # With --activate, activate the venv (usually unnecessary, and slower).
    vrun [--py pypy|current] [--cd] [--activate] <proj-dir> <cmd> [<cmd-arg>...]
    ```

=== "`vpy`"

    ```shell
    # Run script with the python from its folder's venv.
    # --py may be used, same as for envin.
    vpy [--py pypy|current] [--activate] <script> [<script-arg>...]
    ```

=== "`vlauncher`"

    ```shell
    # Make a launcher script for a command run in a given project's activated venv.
    # With --link-only, only create a symlink to <venv>/bin/<cmd>,
    # which should already have the venv's python in its shebang line.
    vlauncher [--link-only] [--py pypy|current] <proj-dir> <cmd> <launcher-dest>
    ```

=== "`zpy mkbin`"

    ```shell
    # Make a standalone script for any zpy function.
    zpy mkbin <func> <dest>
    ```

## Informational

=== "`venvs_path`"

    ```shell
    # Get path of folder containing all venvs for the current folder or specified proj-dir.
    # Pass -i to interactively choose the project.
    venvs_path [-i|<proj-dir>]
    ```

=== "`reqshow`"

    ```shell
    # View contents of all *requirements*.{in,txt} files in the current or specified folders.
    reqshow [<folder>...]
    ```

=== "`pipcheckold`"

    ```shell
    # 'pip list -o' (show outdated) for the current or specified folders.
    # Use --all to instead act on all known projects, or -i to interactively choose.
    pipcheckold [--py pypy|current] [--all|-i|<proj-dir>...]
    ```

=== "`whichpyproj`"

    ```shell
    # Display path of project for the activated venv.
    whichpyproj
    ```

## `pipz` Package Manager

```shell
# Package manager for venv-isolated scripts (pipx clone).
pipz [install|uninstall|upgrade|list|inject|reinstall|cd|runpip|runpkg] [<subcmd-arg>...]
```

=== "`install`"

    ```shell
    # Install apps from PyPI or filesystem into isolated venvs
    pipz install [--cmd <cmd>[,<cmd>...]] [--activate] <pkgspec>...
    # Without --cmd, interactively choose.
    # Without --activate, 'vlauncher --link-only' is used.
    ```

=== "`uninstall`"

    ```shell
    # Remove apps
    pipz uninstall [--all|<pkgname>...]
    # Without args, interactively choose.
    ```

=== "`upgrade`"

    ```shell
    # Install newer versions of apps and their dependencies
    pipz upgrade [--all|<pkgname>...]
    # Without args, interactively choose.
    ```

=== "`list`"

    ```shell
    # Show one or more installed app with its version, commands, and Python runtime
    pipz list [--all|<pkgname>...]
    # Without args, interactively choose which installed apps to list.
    ```

=== "`inject`"

    ```shell
    # Add extra packages to an installed app's isolated venv
    pipz inject [--cmd <cmd>[,<cmd>...]] [--activate] <installed-pkgname> <extra-pkgspec>...
    # Without --cmd, interactively choose.
    # Without --activate, 'vlauncher --link-only' is used.
    ```

=== "`reinstall`"

    ```shell
    # Reinstall apps, preserving any version specs and package injections
    pipz reinstall [--cmd <cmd>[,<cmd>...]] [--activate] [--all|<pkgname>...]
    # Without --cmd, interactively choose.
    # Without --activate, 'vlauncher --link-only' is used.
    # Without --all or <pkgname>, interactively choose.
    ```

=== "`cd`"

    ```shell
    # Enter or run a command from an app's project (requirements.{in,txt}) folder
    pipz cd [<installed-pkgname> [<cmd> [<cmd-arg>...]]]
    # Without args (or if pkgname is ''), interactively choose.
    # With cmd, run it in the folder, then return to CWD.
    ```

=== "`runpip`"

    ```shell
    # Run pip from the venv of an installed app
    pipz runpip [--cd] <pkgname> <pip-arg>...
    # With --cd, run pip from within the project folder.
    ```

=== "`runpkg`"

    ```shell
    # Install an app temporarily and run it immediately
    pipz runpkg <pkgspec> <cmd> [<cmd-arg>...]
    ```

## Editor Configuration

=== "Sublime Text"

    ```shell
    # Specify the venv interpreter in a new or existing Sublime Text project file for the working folder.
    vpysublp [--py pypy|current]
    ```

=== "VS Code"

    ```shell
    # Specify the venv interpreter in a new or existing [VS]Code settings file for the working folder.
    vpyvscode [--py pypy|current]
    ```

=== "Pyright (LSP)"

    ```shell
    # Specify the venv interpreter in a new or existing Pyright settings file for the working folder.
    vpypyright [--py pypy|current]
    ```

## Miscellany

```shell
# Install and upgrade packages.
pipi [--no-upgrade] [<pip install arg>...] <pkgspec>...
```

```shell
# Delete venvs for project folders which no longer exist.
prunevenvs [-y]
```

