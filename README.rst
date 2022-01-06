=================================================
zpy: Zsh helpers for Python venvs, with pip-tools
=================================================

|repo| |docsite| |ghpages| |reqs-ci| |contact|

|container-ci| |container-alpine| |container-fedora| |container-ubuntu|

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

Examples
--------

Basic usage of ``envin`` and ``pipacs``:

.. image:: https://gist.githubusercontent.com/AndydeCleyre/306d250c59a754b9a3399251b4ca0c65/raw/0ae1d1a9e8f5b72dbf78aba4a5ef138909932851/envin_pipacs.svg?sanitize=true
   :alt: Animated envin and pipacs

Basic usage of ``pipz`` (the last frame gets mangled in the SVG only):

.. image:: https://gist.github.com/AndydeCleyre/de117a9aec8360413b8547e1a5ab3484/raw/c58e242b36b6ca721ffae89463554e09b79f7a9c/pipz.svg?sanitize=true
   :alt: Animated pipz

There are about 25 user-facing functions in total:

+-----------------+-----------------+-----------------------------------------------------------------------------------------------------------+
| ``activate/a8`` | ``envin``       | ``envout/da8``                                                                                            |
+-----------------+-----------------+-----------------------------------------------------------------------------------------------------------+
| ``pipa``        | ``pipac``       | ``pipacs``                                                                                                |
+-----------------+-----------------+-----------------------------------------------------------------------------------------------------------+
| ``pipc``        | ``pipcs``       | ``pips``                                                                                                  |
+-----------------+-----------------+-----------------------------------------------------------------------------------------------------------+
| ``pipcheckold`` | ``pipup``       | ``pypc``                                                                                                  |
+-----------------+-----------------+-----------------------------------------------------------------------------------------------------------+
| ``vlauncher``   | ``vpy``         | ``vrun``                                                                                                  |
+-----------------+-----------------+-----------------------------------------------------------------------------------------------------------+
| ``pipi``        | ``prunevenvs``  | ``reqshow``                                                                                               |
+-----------------+-----------------+-----------------------------------------------------------------------------------------------------------+
| ``venvs_path``  | ``whichpyproj`` | ``zpy``                                                                                                   |
+-----------------+-----------------+-----------------------------------------------------------------------------------------------------------+
| ``vpypyright``  | ``vpysublp``    | ``vpyvscode``                                                                                             |
+-----------------+-----------------+-----------------------------------------------------------------------------------------------------------+
| ``vpyshebang``  |                 | ``pipz install``/``uninstall``/``upgrade``/``list``/``inject``/``reinstall``/``cd``/``runpip``/``runpkg`` |
+-----------------+-----------------+-----------------------------------------------------------------------------------------------------------+

For details, either run ``zpy`` (which displays all help text),
see the reference__, or follow the short guide__.

__ https://zpy.readthedocs.io/en/latest/help_all/

__ https://zpy.readthedocs.io/en/latest/start/

Guiding Ideas
-------------

- You should not have to manually specify the dependencies anywhere other than
  ``*requirements.in`` files
- Folks who want to use your code shouldn't have to install any new-fangled
  less-standard tools (pipenv, poetry, pip-tools, zpy, etc.);
  ``pip install -r *requirements.txt`` ought to be sufficient
- It's nice to keep the venv folder *outside* of the project itself
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

Preview
-------

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

.. |reqs-ci| image:: https://github.com/AndydeCleyre/zpy/actions/workflows/reqs.yml/badge.svg?branch=develop
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
