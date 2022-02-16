=================================================
zpy: Zsh helpers for Python venvs, with pip-tools
=================================================

|repo| |docsite| |contact|

|ghpages| |reqs-ci| |container-ci| 

|container-alpine| |container-fedora| |container-ubuntu|

``zpy`` is a set of Zsh functions,
mostly wrapping
pip-tools__,
for the simple and practical management of
Python virtual environments,
dependency specifications,
and isolated Python app installation.

At least a few are very handy.
None of them should get in your way.
All have thorough tab completion.

__ https://github.com/jazzband/pip-tools

They can generally replace pipenv, poetry, pipx, pipsi, virtualenvwrapper, etc.

Check out zpy.rtfd.io__ for installation, explanation, and usage docs!

__ https://zpy.rtfd.io

The short version of installation:

- Install Python, Zsh, fzf__
- Source this repo's ``zpy.plugin.zsh`` in your ``.zshrc``, or use a Zsh plugin manager to add ``andydecleyre/zpy``

__ https://github.com/junegunn/fzf

.. contents::

Examples
--------

.. code:: console

  % envin                       # create venv if necessary, activate it, and (un)install pkgs to match all found requirements.txt files
  % envin dev-requirements.txt  # as above, but match the env's pkgs to only the given file(s)

.. code:: console

  [venv] % pipacs beautifulsoup4  # add pkg to requirements.in, compile locked dep tree to requirements.txt, install to match

.. code:: console

  [venv] % pips requirements.txt      # install regular deps, uninstall others
  [venv] % pips dev-requirements.txt  # install dev deps, uninstall others
  [venv] % pips dev-requirements.txt requirements.txt  # install multiple dep groups
  [venv] % pips                       # install all dep groups

.. code:: console

  [venv] % pipz install tldr visidata jello lice rich-cli subdl yt-dlp  # install tools from PyPI with isolated venvs and locked versions

Basic usage of ``envin`` and ``pipacs``:

.. image:: https://gist.githubusercontent.com/AndydeCleyre/306d250c59a754b9a3399251b4ca0c65/raw/0ae1d1a9e8f5b72dbf78aba4a5ef138909932851/envin_pipacs.svg?sanitize=true
   :alt: Animated envin and pipacs demo

Basic usage of ``pipz``:

.. image:: https://gist.github.com/AndydeCleyre/de117a9aec8360413b8547e1a5ab3484/raw/c58e242b36b6ca721ffae89463554e09b79f7a9c/pipz.svg?sanitize=true
   :alt: Animated pipz demo

There are about 25 user-facing functions in total.
For details,
see the reference__ and the short guide__.

__ https://zpy.readthedocs.io/en/latest/help_all/

__ https://zpy.readthedocs.io/en/latest/start/

Guiding Ideas
-------------

.. image:: https://github.com/AndydeCleyre/zpy/raw/master/doc/src/img/flow.svg
   :alt: Information flow diagram

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
  - do what pyenv__/asdf-vm__ or flit__ do best (but do work with them if you choose)
  - *conflict* with anything else your team cares to do with your code;
    If they can be a friendlier neighbor to your workflows, file an issue__

__ https://github.com/pyenv/pyenv

__ https://asdf-vm.com

__ https://flit.readthedocs.io/en/latest/

__ https://github.com/AndydeCleyre/zpy/issues

Try it in a Container
---------------------

Try it in isolation with docker or podman with one of these commands:

.. code:: console

  $ docker run --net=host -it --rm quay.io/andykluger/zpy-alpine:master
  $ podman run -it --rm quay.io/andykluger/zpy-alpine:master

Replace "alpine" with "ubuntu" or "fedora" if you prefer.

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
