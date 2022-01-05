# Full Reference

```shell
# Print description and arguments for all or specified functions.
zpy [<zpy-function>...]

# Get path of folder containing all venvs for the current folder or specified proj-dir.
# Pass -i to interactively choose the project.
venvs_path [-i|<proj-dir>]

# Install and upgrade packages.
pipi [--no-upgrade] [<pip install arg>...] <pkgspec>...

# Install packages according to all found or specified requirements.txt files (sync).
pips [<reqs-txt>...]

# Compile requirements.txt files from all found or specified requirements.in files (compile).
# Use -h to include hashes, -u dep1,dep2... to upgrade specific dependencies, and -U to upgrade all.
pipc [-h] [-U|-u <pkgspec>[,<pkgspec>...]] [<reqs-in>...] [-- <pip-compile-arg>...]

# Compile, then sync.
# Use -h to include hashes, -u dep1,dep2... to upgrade specific dependencies, and -U to upgrade all.
pipcs [-h] [-U|-u <pkgspec>[,<pkgspec>...]] [--only-sync-if-changed] [<reqs-in>...] [-- <pip-compile-arg>...]

# Add loose requirements to [<category>-]requirements.in (add).
pipa [-c <category>] <pkgspec>...

# Add to requirements.in, then compile it to requirements.txt (add, compile).
# Use -c to affect categorized requirements, and -h to include hashes.
pipac [-c <category>] [-h] <pkgspec>... [-- <pip-compile-arg>...]

# Add to requirements.in, compile it to requirements.txt, then sync to that (add, compile, sync).
# Use -c to affect categorized requirements, and -h to include hashes.
pipacs [-c <category>] [-h] <pkgspec>... [-- <pip-compile-arg>...]

# View contents of all *requirements*.{in,txt} files in the current or specified folders.
reqshow [<folder>...]

# Activate the venv (creating if needed) for the current folder, and sync its
# installed package set according to all found or specified requirements.txt files.
# In other words: [create, ]activate, sync.
# The interpreter will be whatever 'python3' refers to at time of venv creation, by default.
# Pass --py to use another interpreter and named venv.
envin [--py 2|pypy|current] [<reqs-txt>...]

# Activate the venv for the current folder or specified project, if it exists.
# Otherwise create, activate, sync.
# Pass -i to interactively choose the project.
# Pass --py to use another interpreter and named venv.
activate [--py 2|pypy|current] [-i|<proj-dir>]

# Alias for 'activate'.
a8 [--py 2|pypy|current] [-i|<proj-dir>]

# Alias for 'deactivate'.
envout

# Another alias for 'deactivate'.
da8

# Display path of project for the activated venv.
whichpyproj

# Prepend each script with a shebang for its folder's associated venv interpreter.
# If 'vpy' exists in the PATH, '#!/path/to/vpy' will be used instead.
# Also ensures the script is executable.
# --py may be used, same as for envin.
vpyshebang [--py 2|pypy|current] <script>...

# Run command in a subshell with <venv>/bin for the given project folder prepended to the PATH.
# Use --cd to run the command from within the project folder.
# --py may be used, same as for envin.
# With --activate, activate the venv (usually unnecessary, and slower).
vrun [--py 2|pypy|current] [--cd] [--activate] <proj-dir> <cmd> [<cmd-arg>...]

# Run script with the python from its folder's venv.
# --py may be used, same as for envin.
vpy [--py 2|pypy|current] [--activate] <script> [<script-arg>...]

# Make a launcher script for a command run in a given project's activated venv.
# With --link-only, only create a symlink to <venv>/bin/<cmd>,
# which should already have the venv's python in its shebang line.
vlauncher [--link-only] [--py 2|pypy|current] <proj-dir> <cmd> <launcher-dest>

# Delete venvs for project folders which no longer exist.
prunevenvs [-y]

# 'pip list -o' (show outdated) for the current or specified folders.
# Use --all to instead act on all known projects, or -i to interactively choose.
pipcheckold [--py 2|pypy|current] [--all|-i|<proj-dir>...]

# 'pipcs -U' (upgrade-compile, sync) in a venv-activated subshell for the current or specified folders.
# Use --all to instead act on all known projects, or -i to interactively choose.
pipup [--py 2|pypy|current] [--only-sync-if-changed] [--all|-i|<proj-dir>...]

# Inject loose requirements.in dependencies into a PEP 621 pyproject.toml.
# Run either from the folder housing pyproject.toml, or one below.
# To categorize, name files <category>-requirements.in.
pypc

# Specify the venv interpreter in a new or existing Sublime Text project file for the working folder.
vpysublp [--py 2|pypy|current]

# Specify the venv interpreter in a new or existing [VS]Code settings file for the working folder.
vpyvscode [--py 2|pypy|current]

# Specify the venv interpreter in a new or existing Pyright settings file for the working folder.
vpypyright [--py 2|pypy|current]

# Package manager for venv-isolated scripts (pipx clone; py3 only).
pipz [install|uninstall|upgrade|list|inject|reinstall|cd|runpip|runpkg] [<subcmd-arg>...]

# Install apps from PyPI or filesystem into isolated venvs
pipz install [--cmd <cmd>[,<cmd>...]] [--activate] <pkgspec>...
# Without --cmd, interactively choose.
# Without --activate, 'vlauncher --link-only' is used.

# Remove apps
pipz uninstall [--all|<pkgname>...]
# Without args, interactively choose.

# Install newer versions of apps and their dependencies
pipz upgrade [--all|<pkgname>...]
# Without args, interactively choose.

# Show one or more installed app with its version, commands, and Python runtime
pipz list [--all|<pkgname>...]
# Without args, interactively choose which installed apps to list.

# Add extra packages to an installed app's isolated venv
pipz inject [--cmd <cmd>[,<cmd>...]] [--activate] <installed-pkgname> <extra-pkgspec>...
# Without --cmd, interactively choose.
# Without --activate, 'vlauncher --link-only' is used.

# Reinstall apps, preserving any version specs and package injections
pipz reinstall [--cmd <cmd>[,<cmd>...]] [--activate] [--all|<pkgname>...]
# Without --cmd, interactively choose.
# Without --activate, 'vlauncher --link-only' is used.
# Without --all or <pkgname>, interactively choose.

# Enter or run a command from an app's project (requirements.{in,txt}) folder
pipz cd [<installed-pkgname> [<cmd> [<cmd-arg>...]]]
# Without args (or if pkgname is ''), interactively choose.
# With cmd, run it in the folder, then return to CWD.

# Run pip from the venv of an installed app
pipz runpip [--cd] <pkgname> <pip-arg>...
# With --cd, run pip from within the project folder.

# Install an app temporarily and run it immediately
pipz runpkg <pkgspec> <cmd> [<cmd-arg>...]
```
