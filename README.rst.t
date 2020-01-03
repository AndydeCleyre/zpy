=================================================
zpy: Zsh helpers for Python venvs, with pip-tools
=================================================

|repo| |container| |contact|

Here are ~50 Zsh convenience functions to manage Python venvs and packages,
with the excellent pip-tools__. At least a few are very handy.
None of them should get in your way.

__ https://github.com/jazzband/pip-tools

They can generally replace pipenv, poetry [#]_, pipx, pipsi, virtualenvwrapper, etc.

.. [#] when used with flit__

__ https://flit.readthedocs.io/en/latest/

.. image:: https://i.imgur.com/EkXzucP.png

<!--(if default("include_toc", True))-->
.. contents::
   :depth: 1
<!--(end)-->

Guiding Ideas
-------------

- Your workflow should be yours (as you want it) and yours (alone)
- You should not have to manually specify the dependencies anywhere other than
  ``*requirements.in`` files
- Folks who want to use your code shouldn't have to install any new-fangled
  less-standard tools (pipenv, poetry, pip-tools, zpy, etc.);
  ``pip install -r requirements.txt`` ought to be sufficient

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

.. image:: https://s5.gifyu.com/images/1578089177.gif

Try it in isolation with docker, podman, or buildah if you like:

.. code-block:: bash

    docker run --net=host -it quay.io/andykluger/zpy-alpine:latest
    podman run --net=host -it quay.io/andykluger/zpy-alpine:latest
    buildah run -t $(buildah from quay.io/andykluger/zpy-alpine:latest) zsh

Run ``zpy`` to see a full reference of `Functions & Aliases`_.

Basic Operations
----------------

In and Out
``````````

The primary commands for managing whether you're inside or outside a venv are ``envin``
and ``envout``. Extra helpers are available for alternate Python interpreters.

``envin`` will:

- create a new venv for the current *project* (folder), if it doesn't already exist
- activate the venv
- ensure pip-tools is installed in the venv
- install and uninstall packages as necessary to exactly match those specified in all
  *reqs-txt*\ s in the folder (*sync*)

You may also pass as many specific *reqs-txt*\ s as you want to ``envin``,
in which case it will ensure your environment matches those and only those.

If you know your venv is already in a good state, and just want to activate it
without all that installing and uninstalling, you can save a second by running
``activate`` instead.

You may pass a *project* to ``activate``, in order to activate a specific venv
regardless of your current folder.

You can use ``activatefzf`` to interactively select the *project* whose venv you wish to
activate.

.. image:: https://s5.gifyu.com/images/1574711269.gif

``envout`` is a totally unnecessary alias for ``deactivate``, and you can use either one
to deactivate a venv.

Add, Compile, Sync
``````````````````

The basic operations are *add*, *compile*, and *sync* (``pipa``, ``pipc``, ``pips``).

Adding a requirement is simply putting a new ``requirements.txt``-syntax__ line into
``requirements.in``, or a categorized ``<category>-requirements.in``.

__ https://pip.pypa.io/en/stable/reference/pip_install/#requirements-file-format

You may pass one or more requirements to ``pipa`` to add lines to your
``requirements.in``. Helpers that work the same way are provided for some categorized
``*-requirements.in`` files as well (like ``pipadev``, ``pipadoc``, and ``pipatest``).
You can also add special constraints__ for layered requirements workflows, or add
"include" lines like ``-r prod-requirements.in``.

__ https://github.com/jazzband/pip-tools#workflow-for-layered-requirements

``pipc`` will generate version-locked *reqs-txt*\ s including all dependencies from the
information in each found *reqs-in* in the current folder. You may also pass one or more
specific *reqs-in*\ s instead. If you want hashes included in the output, use ``pipch``.

``pipu`` and ``pipuh`` are similar, but ensure dependencies are upgraded as far as they
can be while matching the specifications in the *reqs-in*\ s. These commands accept
specific packages as arguments, if you wish to only upgrade those.

``pips`` will *sync* your environment to match your *reqs-txt*\ s, installing and
uninstalling packages as necessary. You may also pass specific *reqs-txt*\ s as
arguments to match only those.

Often, you'll want to do a few of these things in sequence. You can do so with
``pipac`` (*add*, *compile*), ``pipacs`` (*add*, *compile*, *sync*), and ``pipus``
(*upgrade-compile*, *sync*). If you want hashes included in the output, use ``pipach``,
``pipachs``, and ``pipuhs``.

You can see exactly what a command will do with ``which <command>``, and get
explanations and accepted arguments with ``zpy <command>``. Running ``zpy`` alone will
show all descriptions and arguments.

For a full, concise list of functions and their descriptions and arguments, see
`Functions & Aliases`_.

Bonus Operations
----------------

Welcome to the bonus round!

If you use flit__ to package your code for PyPI, and I recommend you do, you can
automatically update your ``pyproject.toml``\ 's categorized dependencies from the
information in your *reqs-in*\ s with ``pypc``.

__ https://flit.readthedocs.io/en/latest/

Launch a Python script using its project's venv, from outside the venv, with
``vpy <script.py>``.

Alter a Python script so that it's always launched using its project's venv, from
outside the venv, with ``vpyshebang <script.py>``.

Launch a Python script that's installed in its project's venv's ``bin`` folder, from
outside the venv, with ``vpyfrom </path/to/project> <script>``.

Generate a launcher script that runs a venv-installed script (in the ``bin`` folder)
from outside the venv, with
``vpylauncherfrom </path/to/project> <script-name> <destination>``.

Oh, and there's a mini pipx clone, ``pipz``, for installing and managing isolated apps.

But wait, there's more! Find it all at `Functions & Aliases`_.

Functions & Aliases
-------------------

.. code-block:: bash

<!--(for line in help.splitlines())-->
    $! line !$
<!--(end)-->

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

If you want completions, make sure to load ``compinit`` beforehand:

.. code-block:: bash

    autoload -U compinit
    compinit

Dependencies for Popular Platforms
``````````````````````````````````

To make any use of this project, you'll need ``zsh``, ``python``, and
``busybox``/``coreutils`` or similar.

``pcregrep`` is needed for the ``zpy`` function(and completions), and is already a
dependency of ``zsh`` on Arch Linux and MacOS (via Homebrew__).

__ https://brew.sh/

``fzf`` is only needed for the ``activatefzf`` and ``pipz`` functions.

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

Paths & Wording
---------------

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

- As this project thinly wraps pip-tools__, *compile* means to generate version-locked
  ``*requirements.txt``\ s (*reqs-txt*\ s) from manually maintained
  ``*requirements.in``\ s (*reqs-in*\ s), and *sync* means to ensure your current
  environment matches a set of *reqs-txt*\ s.
- *add* means to insert a new requirement into a *reqs-in* file.

__ https://github.com/jazzband/pip-tools


.. |repo| image:: https://img.shields.io/github/size/andydecleyre/zpy/python.zshrc?logo=github&label=Code
   :alt: GitHub file size in bytes
   :target: https://github.com/andydecleyre/zpy

.. |container| image:: https://img.shields.io/badge/Container-Quay.io-blue?logo=red-hat
   :alt: Demo container
   :target: https://quay.io/repository/andykluger/zpy-alpine

.. |contact| image:: https://img.shields.io/badge/Contact-Telegram-blue?logo=telegram
   :alt: Contact developer on Telegram
   :target: https://t.me/andykluger
