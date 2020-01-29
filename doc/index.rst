=================================================
zpy: Zsh helpers for Python venvs, with pip-tools
=================================================

|repo| |docsite| |container| |container-ci| |contact|

In a hurry? Jump to Installation_.

Here are Zsh convenience functions to manage Python venvs and packages,
with the excellent pip-tools__. At least a few are very handy.
None of them should get in your way.

__ https://github.com/jazzband/pip-tools

They can generally replace pipenv, poetry [#]_, pipx, pipsi, virtualenvwrapper, etc.

.. [#] when used with flit__

__ https://flit.readthedocs.io/en/latest/

.. image:: https://gist.github.com/AndydeCleyre/34fd63abe8954957590224e85edf6476/raw/28ba8c4a77f17f56fdb83726733e89ac01e2a068/demo_intro.svg?sanitize=true


Guiding Ideas
-------------

- Your workflow should be yours (as you want it) and yours (alone)
- You should not have to manually specify the dependencies anywhere other than
  ``*requirements.in`` files
- Folks who want to use your code shouldn't have to install any new-fangled
  less-standard tools (pipenv, poetry, pip-tools, zpy, etc.);
  ``pip install -r *requirements.txt`` ought to be sufficient
- It's nice to keep the venv folder *outside* of the project itself

- These functions **don't**:

  - need to be used continuously, contiguously, exclusively, unanimously, or comprehensively
  - require homogeneous workflows among developers
  - do what pyenv__ or flit__ do best (but do work with them if you choose)
  - *conflict* with anything else your team cares to do with your code;
    If they can be a friendlier neighbor to your workflows, file an issue__

__ https://github.com/pyenv/pyenv

__ https://flit.readthedocs.io/en/latest/

__ https://github.com/AndydeCleyre/zpy/issues

Preview
-------

Try it in isolation with docker, podman, or buildah if you like:

.. code-block:: bash

  docker run --net=host -it quay.io/andykluger/zpy-alpine:latest
  podman run --net=host -it quay.io/andykluger/zpy-alpine:latest
  buildah run -t $(buildah from quay.io/andykluger/zpy-alpine:latest) zsh

Run ``zpy`` to see a full reference of `Functions & Aliases`_.

.. note:: You may need to install extra system packages if your pip packages need
          compilation.

          For example, before installing ``numpy`` you'll need to run
          ``sudo apk add gcc {musl,python3}-dev``;
          before installing ``pillow``, run
          ``sudo apk add gcc {jpeg,musl,python3,zlib}-dev``.

.. image:: https://gist.github.com/AndydeCleyre/aa9dc4d86c43903a0350def66fa62af0/raw/05f61ae09b16ef77c2eaac39ab3f3f17c60c30f0/demo_pipz_install.svg?sanitize=true

Wording
-------

There are just a handful of things you probably wish to do to your dependency
specifications and virtual environments, and it may be helpful to enumerate them before
introducing the included helper functions.

Dependency Specification Actions
````````````````````````````````

add
  add a package to your list of loosely-versioned requirements (*reqs-in*)

compile
  (re)generate a lockfile of strictly-versioned requirements (*reqs-txt*)

upgrade-compile
  recompile the lockfile, upgrading versions as allowed by any restrictions in *reqs-in*

This project expects *reqs-in*\ s to be named as ``*requirements.in`` and
*reqs-txt*\ s ``*requirements.txt``.

Virtual Environment Actions
```````````````````````````

create
  i.e. ``python -m venv <path/to/venv>``

activate
  i.e. ``. <path/to/venv>/bin/activate``

deactivate
  i.e. ``deactivate``

sync
  install and uninstall packages to exactly match your specifications in *reqs-txt*

Basic Operations
----------------

``envin [reqs-txt...]``
  - *create* a new venv for the current *project* (folder), if it doesn't already exist
  - *activate* the venv
  - ensure pip-tools is installed in the venv
  - *sync* venv's installed packages to exactly match those specified in all
    *reqs-txt*\ s in the folder

  You may also pass as many specific *reqs-txt*\ s as you want to ``envin``,
  in which case it will ensure your environment matches those and only those.

``activate [-i|proj-dir]``
  If you know your venv is already in a good state, and just want to activate it
  without all that installing and uninstalling, you can save a second by running
  ``activate`` (or alias ``a8``) instead of ``envin``.

  If the venv doesn't already exist, this will fall back to ``envin``-like behavior
  (create, activate, *sync*).

  You may pass a *project* to ``activate``, in order to activate a specific venv
  regardless of your current folder.

  Pass ``-i`` to interactively select an existing *project*.

``envout``
  a totally unnecessary alias for ``deactivate``

Add, Compile, Sync
``````````````````

``pipa <req...>``
  append one or more new ``requirements.txt``-syntax__ line into ``requirements.in``,
  or a categorized ``<category>-requirements.in``

  Helpers that work the same way are provided for some categorized ``*-requirements.in``
  files as well (like ``pipadev``, ``pipadoc``, and ``pipatest``).
  You can also add special constraints__ for layered requirements workflows, or add
  "include" lines like ``-r prod-requirements.in``.

__ https://pip.pypa.io/en/stable/reference/pip_install/#requirements-file-format

__ https://github.com/jazzband/pip-tools#workflow-for-layered-requirements

``pipc [reqs-in...]``
  generate version-locked *reqs-txt*\ s including all dependencies from the
  information in each found *reqs-in* in the current folder

  You may also pass one or more specific *reqs-in*\ s instead.

  If you want hashes included in the output, use ``pipch``.

``pipu [req...]``
  similar to ``pipc``, but ensure dependencies are upgraded as far as they
  can be while matching the specifications in the *reqs-in*\ s

  This and ``pipuh`` (same but with hashes) accept specific packages as arguments,
  if you wish to only upgrade those.

``pips [reqs-txt...]``
  *sync* your environment to match your *reqs-txt*\ s, installing and
  uninstalling packages as necessary

  You may also pass specific *reqs-txt*\ s as arguments to match only those.

Often, you'll want to do a few of these things in sequence. You can do so with
``pipac`` (*add*, *compile*), ``pipacs`` (*add*, *compile*, *sync*), and ``pipus``
(*upgrade-compile*, *sync*).

If you want hashes included in the output, use ``pipach``, ``pipachs``, and ``pipuhs``.

You can see exactly what a command will do with ``which <command>``, and get
explanations and accepted arguments with ``zpy <command>``. Running ``zpy`` alone will
show all descriptions and arguments. The same documentation is also accessible via tab
completion.

For a full, concise list of functions and their descriptions and arguments, see
`Functions & Aliases`_.

Bonus Operations
----------------

Welcome to the bonus round!

``pypc``
  automatically update your flit__-generated ``pyproject.toml``\ 's categorized
  dependencies from the information in your *reqs-in*\ s

__ https://flit.readthedocs.io/en/latest/

``vpy <script.py>``
  launch a Python script using its project's venv, from outside the venv

``vpyshebang <script.py>``
  alter a Python script so that it's always launched using its project's venv, from
  outside the venv

``vpyfrom </path/to/project> <script>``
  launch a Python script that's installed in its project's venv's ``bin`` folder, from
  outside the venv

``vpylauncherfrom </path/to/project> <script-name> <destination>``
  generate a launcher script that runs a venv-installed script (in the ``bin`` folder)
  from outside the venv

``pipz``
  install and manage isolated apps (pipx clone)

But wait, there's more! Find it all at `Functions & Aliases`_.

Functions & Aliases
-------------------

.. code-block:: bash

  
  # Print description and arguments for all or specified functions.
  # To see actual function contents, use `which <funcname>`.
  zpy [zpy-function...]
  
  # Get path of folder containing all venvs for the current folder or specified proj-dir.
  # Pass -i to interactively choose the project.
  venvs_path [-i|proj-dir]
  
  # Install and upgrade packages.
  pipi <req...>
  
  # Install packages according to all found or specified requirements.txt files (sync).
  pips [reqs-txt...]
  
  # Compile requirements.txt files from all found or specified requirements.in files (compile).
  pipc [reqs-in...]
  # Compile with hashes.
  pipch [reqs-in...]
  #
  # Compile, then sync.
  pipcs [reqs-in...]
  # Compile with hashes, then sync.
  pipchs [reqs-in...]
  
  # Add loose requirements to [<category>-]requirements.in (add).
  # pipa(|build|dev|doc|publish|test) <req...>
  pipa <req...>
  
  # Add loose requirements to [<category>-]requirements.in (add).
  pipabuild <req...>
  pipadev <req...>
  pipadoc <req...>
  pipapublish <req...>
  pipatest <req...>
  
  # Add to requirements.in, then compile it to requirements.txt (add, compile).
  pipac <req...>
  # Add to requirements.in, then compile it with hashes to requirements.txt.
  pipach <req...>
  #
  # Add to requirements.in, compile it to requirements.txt, then sync to that (add, compile, sync).
  pipacs <req...>
  # Add, compile with hashes, sync.
  pipachs <req...>
  
  # Recompile *requirements.txt with upgraded versions of all or specified packages (upgrade).
  pipu [req...]
  # Upgrade with hashes.
  pipuh [req...]
  #
  # Upgrade, then sync.
  pipus [req...]
  # Upgrade with hashes, then sync.
  pipuhs [req...]
  
  # Activate venv 'venv' (creating if needed) for the current folder, and sync its
  # installed package set according to all found or specified requirements.txt files.
  # In other words: [create, ]activate, sync.
  # The interpreter will be whatever `python3` refers to at time of venv creation.
  envin [reqs-txt...]
  # Also available for 'venv2'/`python2`, 'venv-pypy'/`pypy3`, 'venv-<current pyver>'/`python`:
  # envin(2|py|current) [reqs-txt...]
  
  # Like envin, but with venv 'venv2' and command `python2`.
  envin2 [reqs-txt...]
  
  # Like envin, but with venv 'venv-pypy' and command `pypy3`.
  envinpy [reqs-txt...]
  
  # Like envin, but with venv 'venv-<current pyver>' and command `python`.
  # Useful if you use pyenv or similar for multiple py3 versions on the same project.
  envincurrent [reqs-txt...]
  
  # If `venvs_path`/venv exists for the current or specified project folder,
  # activate it without installing anything.
  # Otherwise, act as `envin` (create, activate, sync).
  # Pass -i to interactively choose the project.
  activate [-i|proj-dir]
  a8 [-i|proj-dir]
  #
  # Deactivate.
  envout  
  
  # Run script with its folder's associated venv 'venv'.
  vpy <script> [script-arg...]
  # Also available for 'venv2', 'venv-pypy', 'venv-<current pyver>':
  # vpy(2|py|current) <script> [script-arg...]
  
  # Like vpy, but with venv 'venv2'.
  vpy2 <script> [script-arg...]
  
  # Like vpy, but with venv 'venv-pypy'.
  vpypy <script> [script-arg...]
  
  # Like vpy, but with venv 'venv-<current pyver>'.
  vpycurrent <script> [script-arg...]
  
  # Get path of project for the activated venv.
  whichpyproj
  
  # Prepend each script with a shebang for its folder's associated venv interpreter.
  # If `vpy` exists in the PATH, #!/path/to/vpy will be used instead.
  # Also ensure the script is executable.
  vpyshebang <script...>
  # Also available for 'venv2', 'venv-pypy', 'venv-<current pyver>':
  # vpy(2|py|current)shebang <script...>
  
  # Like vpyshebang, but with venv 'venv2'.
  vpy2shebang <script...>
  
  # Like vpyshebang, but with venv 'venv-pypy'.
  vpypyshebang <script...>
  
  # Like vpyshebang, but with venv 'venv-<current pyver>'.
  vpycurrentshebang <script...>
  
  # Run script from a given project folder's associated venv's bin folder.
  vpyfrom <proj-dir> <script-name> [script-arg...]
  # Also available for 'venv2', 'venv-pypy', 'venv-<current pyver>':
  # vpy(2|py|current)from <proj-dir> <script-name> [script-arg...]
  
  # Like vpyfrom, but with venv 'venv2'.
  vpy2from <proj-dir> <script-name> [script-arg...]
  
  # Like vpyfrom, but with venv 'venv-pypy'.
  vpypyfrom <proj-dir> <script-name> [script-arg...]
  
  # Like vpyfrom, but with venv 'venv-<current pyver>'.
  vpycurrentfrom <proj-dir> <script-name> [script-arg...]
  
  # Generate an external launcher for a script in a given project folder's associated venv's bin folder.
  vpylauncherfrom <proj-dir> <script-name> <launcher-dest>
  
  # Delete venvs for project folders which no longer exist.
  prunevenvs
  
  # `pip list -o` for all or specified projects.
  pipcheckold [proj-dir...]
  
  # `pipus` (upgrade-compile, sync) for all or specified projects.
  pipusall [proj-dir...]
  
  # Inject loose requirements.in dependencies into pyproject.toml.
  # Run either from the folder housing pyproject.toml, or one below.
  # To categorize, name files <category>-requirements.in.
  pypc
  
  # Specify the venv interpreter in a new or existing Sublime Text project file for the working folder.
  vpysublp
  
  # Launch a new or existing Sublime Text project, setting venv interpreter.
  sublp [subl-arg...]
  
  # A basic pipx clone (py3 only).
  # Package manager for venv-isolated scripts.
  #
  # pipz list [pkgname...]  ## If no pkg is provided, list all installed.
  # pipz install [--bins <bin-name>[,<bin-name>...]] <pkgspec...>    ## If no bin-names are provided and the correct one isn't obvious, interactively choose.
  # pipz inject [--bins <bin-name>[,<bin-name>...]] <installed-pkgname> <extra-pkgspec...>    ## If no bin-names are provided and the correct one isn't obvious, interactively choose.
  # pipz (upgrade|uninstall|reinstall)-all
  # pipz (upgrade|uninstall|reinstall) [pkspec...]    ## If no pkg is provided, interactively choose.
  # pipz runpip <pkgname> <pip-arg...>
  # pipz runpkg <pkgspec> <cmd> [cmd-arg...]
  pipz [list|install|(uninstall|upgrade|reinstall)(|-all)|inject|runpip|runpkg] [subcmd-arg...]
  

Installation
------------

Install dependencies as appropriate for your platform, then source ``python.zshrc``:

.. code-block:: bash

  git clone https://github.com/andydecleyre/zpy
  echo ". $PWD/zpy/python.zshrc" >> ~/.zshrc

If you use a fancy Zsh plugin tool, you can instead use a command like one of these:

.. code-block:: bash

  antigen bundle andydecleyre/zpy python.zshrc
  antibody bundle andydecleyre/zpy path:python.zshrc
  zgen load andydecleyre/zpy python.zshrc
  zmodule andydecleyre/zpy -s python.zshrc

If you want completions, make sure to load ``compinit`` beforehand:

.. code-block:: bash

  autoload -U compinit
  compinit

Dependencies for Popular Platforms
``````````````````````````````````

To make any use of this project, you'll need ``zsh``, ``python``, and
``busybox``/``coreutils`` or similar.

``pcregrep`` is needed for the ``zpy`` function (and completions), and is already a
dependency of ``zsh`` on Arch Linux and MacOS (via Homebrew__).

__ https://brew.sh/

``fzf`` is only needed for ``pipz``, ``activate -i``, and ``venvs_path -i``.

You can enable pretty syntax highlighting by installing either highlight__ or bat__.

__ http://www.andre-simon.de/doku/highlight/highlight.html

__ https://github.com/sharkdp/bat

``jq`` will be used if present for more reliable parsing, but is not necessary.

Alpine
~~~~~~

.. code-block:: bash

  sudo apk add fzf git highlight jq pcre-tools python3 zsh

Arch
~~~~

.. code-block:: bash

  sudo pacman -S fzf git highlight jq python zsh

Debian
~~~~~~

.. code-block:: bash

  sudo apt install fzf git highlight jq pcregrep python3{,-venv} zsh

Fedora
~~~~~~

.. code-block:: bash

  sudo dnf install fzf git-core highlight jq pcre-tools python3 zsh

MacOS
~~~~~

.. code-block:: bash

  brew install fzf git highlight jq python zsh

OpenSUSE
~~~~~~~~

.. code-block:: bash

  sudo zypper in fzf git highlight jq pcre-tools python3 zsh

Extra Scripts
`````````````

The ``vpy`` and ``vpyfrom`` functions are also available as standalone scripts, if you'd
like some handy launchers accessible outside your interactive Zsh environment. To use,
put them somewhere in your ``PATH``.

For example:

.. code-block:: bash

  ln -s $PWD/zpy/bin/vpy* ~/.local/bin/

Paths & More Wording
--------------------

- A *project* (or *proj-dir*) is any folder containing one or more
  ``*requirements.{in,txt}`` files, and usually some Python code.
- Each *project* is associated with an external *venvs_path* folder,
  at ``$VENVS_WORLD/<project path hash>``.
- ``VENVS_WORLD`` is by default ``$XDG_DATA_HOME/venvs`` or ``~/.local/share/venvs``,
  but can be overridden by ``export``\ ing after sourcing ``python.zshrc``.
- Within each *venvs_path* will be generated:

  + one or more named venv folders (``venv``, ``venv2``, ``venv-pypy``,
    ``venv-<pyver>``) based on the desired Python
  + a symlink back to the *project*

.. |repo| image:: https://img.shields.io/github/size/andydecleyre/zpy/python.zshrc?logo=github&label=Code&color=blueviolet
   :alt: GitHub file size in bytes
   :target: https://github.com/andydecleyre/zpy

.. |container| image:: https://img.shields.io/badge/Container-Quay.io-green?logo=red-hat
   :alt: Demo container
   :target: https://quay.io/repository/andykluger/zpy-alpine

.. |container-ci| image:: https://andydecleyre.semaphoreci.com/badges/zpy/branches/develop.svg
   :alt: Demo container - Semaphore CI
   :target: https://andydecleyre.semaphoreci.com/projects/zpy

.. |contact| image:: https://img.shields.io/badge/Contact-Telegram-blue?logo=telegram
   :alt: Contact developer on Telegram
   :target: https://t.me/andykluger

.. |docsite| image:: https://readthedocs.org/projects/zpy/badge/
   :alt: Documentation Status
   :target: https://zpy.readthedocs.io/en/latest/
