===
zpy
===
-------------------------------------------------------
Manage Python environments in Zsh, with uv or pip-tools
-------------------------------------------------------

|ghpages| |reqs-ci| |container-ci|

|container-alpine| |container-fedora| |container-ubuntu|

|repo| |docsite| |contact|

|logo|

``zpy`` is a set of Zsh functions
wrapping
or uv__, or
pip-tools__
and Python's venv module,
for the *simple* and *interactive* management of
Python **virtual environments**,
**dependency specifications**,
and **isolated Python app installations**.

None of them should get in your way.
All have **thorough tab completion**.

__ https://github.com/astral-sh/uv

__ https://github.com/jazzband/pip-tools

They can generally replace pipenv, poetry, pipx, pipsi, virtualenvwrapper, etc.

.. contents::

|zpy-completions|

Getting It
----------

The short version of installation:

- Install Python, Zsh, fzf__
- Source this repo's ``zpy.plugin.zsh`` in your ``.zshrc``, or use a Zsh plugin manager to add ``andydecleyre/zpy``

__ https://github.com/junegunn/fzf

Check out `the docs`__ for installation, explanation, and usage docs!

__ https://andydecleyre.github.io/zpy/

Examples
--------

- Install tools from PyPI or git, each with its own isolated venv:

  .. code:: console

    % pipz install uv tldr jello rich-cli yt-dlp 'visidata @ git+https://github.com/saulpw/visidata@develop'

- Create a venv for the current folder (if necessary), activate it, and **sync** installed pkgs to match *all* ``requirements.txt`` lockfiles:

  .. code:: console

    % envin

  . . . or sync packages to *particular* lockfiles:

  .. code:: console

    % envin dev-requirements.txt

- **Add** a pkg to ``requirements.in``, **compile** a locked dep tree as ``requirements.txt``, and **sync** installed packages:

  .. code:: console

    % pipacs beautifulsoup4

- **Compile** all ``(*-)requirements.in`` files, upgrading versions where possible, then **sync** to match:

  .. code:: console

    % pipcs -U

- Inject "loose" requirements (as written in ``requirements.in``) into ``pyproject.toml``:

  .. code:: console

    % pypc

There are about 25 user-facing functions in total.
For details,
see the reference__ and the short guide__.

__ https://andydecleyre.github.io/zpy/help_all/

__ https://andydecleyre.github.io/zpy/start/

They are also available as subcommands to the "supercommand" ``zpy``;
``envin`` is equivalent to ``zpy envin``, etc.

Basic usage of ``envin`` and ``pipacs``:

|envin-pipacs-gif|

Basic usage of ``pipz``:

|pipz-gif|

Try it in a Container
---------------------

Try it in isolation with docker or podman with one of these commands:

.. code:: console

  $ docker run --net=host -it --rm -e TERM=$TERM quay.io/andykluger/zpy-ubuntu:master
  $ podman run --net=host -it --rm -e TERM=$TERM quay.io/andykluger/zpy-ubuntu:master

Replace "ubuntu" with "alpine" or "fedora" if you prefer.

Guiding Ideas
-------------

.. image:: https://github.com/AndydeCleyre/zpy/raw/master/doc/src/img/flow.svg
   :alt: Information flow diagram
   :width: 100%

- You should not have to manually specify the dependencies anywhere other than
  ``*requirements.in`` files
- Folks who want to use your code shouldn't have to install any new-fangled
  less-standard tools (pipenv, poetry, pip-tools, zpy, etc.);
  ``pip install -r *requirements.txt`` ought to be sufficient
- It's nice to keep the venv folder *outside* of the project itself
- Not every manageable project *needs* a ``pyproject.toml`` or to be packaged
- Lockfiles are good
- Tab completion is wonderful

- These functions **don't**:

  - need to be used exclusively
  - need to be used by everyone on the same project
  - do what mise__/pyenv__/asdf-vm__ or flit__ do best (but do work with them if you choose)
  - *conflict* with anything else your team cares to do with your code;
    If they can be a friendlier neighbor to your workflows, file an issue__

__ https://github.com/jdx/mise

__ https://github.com/pyenv/pyenv

__ https://asdf-vm.com

__ https://flit.readthedocs.io/en/latest/

__ https://github.com/AndydeCleyre/zpy/issues

Known Issues
------------

Functions ``pipacs``, ``pipac``, ``pipcs``, and ``pipc`` allow forwarding arguments directly
to ``pip-compile``, or ``uv pip compile`` when ``uv`` is installed.

There are currently two problems with this when ``uv`` is used:

- Tab completion of those arguments, even when ``uv`` tab completions are installed, will fail.
  If it bothers you, please add a 👍 on
  `their existing issue`__.
- When the options passed are intended to override ones already passed internally,
  the command will fail.
  If this bothers you, please add a 👍 on
  `their existing issue`__.

__ https://github.com/astral-sh/uv/issues/3249

__ https://github.com/astral-sh/uv/issues/3248

.. |repo| image:: https://img.shields.io/github/size/andydecleyre/zpy/zpy.plugin.zsh?logo=github&label=Code&color=blueviolet
   :alt: Plugin file size in bytes
   :target: https://github.com/andydecleyre/zpy

.. |container-alpine| image:: https://img.shields.io/badge/Container-Quay.io-green?logo=alpine-linux
   :alt: Demo container - Alpine Linux
   :target: https://quay.io/repository/andykluger/zpy-alpine

.. |container-fedora| image:: https://img.shields.io/badge/Container-Quay.io-green?logo=red-hat
   :alt: Demo container - Fedora
   :target: https://quay.io/repository/andykluger/zpy-fedora

.. |container-ubuntu| image:: https://img.shields.io/badge/Container-Quay.io-green?logo=ubuntu
   :alt: Demo container - Ubuntu
   :target: https://quay.io/repository/andykluger/zpy-ubuntu

.. |container-ci| image:: https://github.com/AndydeCleyre/zpy/actions/workflows/ctnrs.yml/badge.svg?branch=develop
   :alt: Demo containers - GitHub Actions
   :target: https://github.com/AndydeCleyre/zpy/actions/workflows/ctnrs.yml

.. |reqs-ci| image:: https://github.com/AndydeCleyre/zpy/actions/workflows/reqs.yml/badge.svg
   :alt: Bump PyPI requirements - GitHub Actions
   :target: https://github.com/AndydeCleyre/zpy/actions/workflows/reqs.yml

.. |contact| image:: https://img.shields.io/badge/Contact-Telegram-blue?logo=telegram
   :alt: Contact developer on Telegram
   :target: https://t.me/andykluger

.. |docsite| image:: https://readthedocs.org/projects/zpy/badge/
   :alt: Documentation Status
   :target: https://zpy.readthedocs.io/en/latest/

.. |ghpages| image:: https://github.com/AndydeCleyre/zpy/actions/workflows/gh-pages.yml/badge.svg?branch=master
   :alt: Build GitHub Pages
   :target: https://andydecleyre.github.io/zpy/

.. |logo| image:: https://github.com/AndydeCleyre/zpy/blob/assets/zpy-logo.png?raw=true
   :alt: zpy logo
   :width: 160px

.. |zpy-completions| image:: https://user-images.githubusercontent.com/1787385/172661113-7a2c6670-e716-491e-8db4-c005fef8455b.png
   :alt: zpy supercommand completions
   :width: 800px

.. |envin-pipacs-gif| image:: https://github.com/AndydeCleyre/zpy/blob/assets/envin_pipacs.gif?raw=true
   :alt: Animated envin and pipacs demo
   :width: 800px

.. |pipz-gif| image:: https://github.com/AndydeCleyre/zpy/blob/assets/pipz.gif?raw=true
   :alt: Animated pipz demo
   :width: 800px
