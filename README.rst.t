=================================================
zpy: Zsh helpers for Python venvs, with pip-tools
=================================================

|repo| |docsite| |container-alpine| |container-fedora| |container-ubuntu| |container-ci| |contact|

In a hurry? Jump to Installation_.

Here are Zsh convenience functions to manage Python venvs and packages,
using (the excellent) pip-tools__. At least a few are very handy.
None of them should get in your way.

__ https://github.com/jazzband/pip-tools

They can generally replace pipenv, poetry [#]_, pipx, pipsi, virtualenvwrapper, etc.

.. [#] when used with flit__

__ https://flit.readthedocs.io/en/latest/

.. image:: https://gist.githubusercontent.com/AndydeCleyre/530538f4afde15278cad3411f3d14e24/raw/17aaeb90ef29817c73d5abec81f5b39caef01d7d/demo.svg?sanitize=true

<!--(if default("include_toc", True))-->
.. contents::
   :depth: 1
<!--(end)-->

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

Try it in isolation with docker or podman if you like, with one of these commands:

.. code:: console

  $ docker run --net=host -it --rm quay.io/andykluger/zpy-alpine:master
  $ podman run -it --rm quay.io/andykluger/zpy-alpine:master

Replace "alpine" with "ubuntu" or "fedora" if you prefer.

.. image:: https://gist.githubusercontent.com/AndydeCleyre/4d634829092ca6c1280eaa19914995a3/raw/18629622adc28e563183276c975459f2021c553d/demo.svg?sanitize=true

Run ``zpy`` to see a full reference of `Functions & Aliases`_.

Wording
-------

There are just a handful of things you probably wish to do to your dependency
specifications and virtual environments, and it may be helpful to enumerate them before
introducing the included helper functions.

Dependency Specification Actions
````````````````````````````````

add (``pipa``)
  add a package to your list of loosely-versioned requirements (*reqs-in*)

compile (``pipc``)
  (re)generate a lockfile of strictly-versioned requirements (*reqs-txt*)

This project expects *reqs-in*\ s to be named as ``*requirements.in`` and
*reqs-txt*\ s ``*requirements.txt``, but it's not necessary.

Virtual Environment Actions
```````````````````````````

create + activate (``envin``, ``activate``/``a8``)
  i.e. ``python -m venv <path/to/venv>; . <path/to/venv>/bin/activate``

deactivate (``envout``/``deactivate``/``da8``)
  i.e. ``deactivate``

sync (``pips``)
  install and uninstall packages to exactly match your specifications in one or more *reqs-txt* files

Basic Operations
----------------

``envin [<reqs-txt>...]``
  - *create* a new venv for the current *project* (folder), if it doesn't already exist
  - *activate* the venv
  - ensure pip-tools is installed in the venv
  - *sync* venv's installed packages to exactly match those specified in all
    *reqs-txt*\ s in the folder

  You may also pass as many specific *reqs-txt*\ s as you want to ``envin``,
  in which case it will ensure your environment matches those and only those.

``activate [-i|<proj-dir>]``
  If you know your venv is already in a good state, and just want to activate it
  without all that installing and uninstalling, you can save a second by running
  ``activate`` (or alias ``a8``) instead of ``envin``.

  If the venv doesn't already exist, this will fall back to ``envin``-like behavior
  (*create*, *activate*, *sync*).

  You may pass a *project* to ``activate``, in order to activate a specific venv
  regardless of your current folder.

  Pass ``-i`` to interactively select an existing *project*.

``envout`` and ``da8``
  two totally unnecessary aliases for ``deactivate``

Add, Compile, Sync
``````````````````

``pipa [-c <category>] <pkgspec>...``
  append one or more new ``requirements.txt``-syntax__ lines to ``requirements.in``,
  or ``<category>-requirements.in``

  You can also add special constraints__ for layered requirements workflows, or add
  "include" lines like ``-r prod-requirements.in``.

__ https://pip.pypa.io/en/stable/reference/pip_install/#requirements-file-format

__ https://github.com/jazzband/pip-tools#workflow-for-layered-requirements

``pipc [-h] [-U|-u <pkgspec>[,<pkgspec>...]] [<reqs-in>...]``
  generate version-locked *reqs-txt*\ s including all dependencies from the
  information in each found *reqs-in* in the current folder

  You may also pass one or more specific *reqs-in*\ s instead.

  Use ``-h`` to include hashes in the output.

  You can ensure specific dependencies are upgraded as far as possible
  while matching the specifications in the *reqs-in*\ s by passing them,
  comma-separated, with ``-u``.

  You can do the same for **all** dependencies with ``-U``.

``pips [<reqs-txt>...]``
  *sync* your environment to match your *reqs-txt*\ s, installing and
  uninstalling packages as necessary

  You may also pass specific *reqs-txt*\ s as arguments to match only those.

Often, you'll want to do a few of these things in sequence. You can do so with
``pipac`` (*add*, *compile*), ``pipacs`` (*add*, *compile*, *sync*), and ``pipcs``
(*compile*, *sync*).

Tab completion aims to be thorough.

For a full list of functions and their descriptions and arguments, see
`Functions & Aliases`_.

Bonus Operations
----------------

Welcome to the bonus round!

``pypc``
  automatically update your flit__-generated ``pyproject.toml``\ 's categorized
  dependencies from the information in your *reqs-in*\ s

__ https://flit.readthedocs.io/en/latest/

``vpy <script.py>``
  launch a Python script using ``python`` from its project's venv, from outside the venv

``vpyshebang <script.py>``
  alter a Python script so that it's always launched using ``python`` from its project's
  venv, from outside the venv

``vrun </path/to/project> <cmd>``
  run command in a subshell with ``<venv>/bin`` for the given project folder prepended
  to the PATH, from outside the venv

``pipz``
  install and manage isolated apps (pipx clone)

But wait, there's more! Find it all at `Functions & Aliases`_.

Functions & Aliases
-------------------

.. code:: bash

<!--(for line in help.splitlines())-->
  $! line !$
<!--(end)-->

Installation
------------

Aside from the Dependencies_, ``zpy`` is a single file to be sourced in your ``.zshrc``, and
can be sourced manually or with the help of a Zsh configuration framework or plugin manager.

If you're new to Zsh and want to try a framework, I recommend Zim_.

Manual
``````

.. code:: console

  $ cd /wherever/you/want/to/keep/zpy
  $ git clone https://github.com/andydecleyre/zpy
  $ print ". $PWD/zpy/zpy.plugin.zsh" >> ~/.zshrc

If you want completions, make sure to load ``compinit`` earlier in ``~/.zshrc``:

.. code:: bash

  autoload -Uz compinit
  compinit

If you're using a Zsh framework, that's probably done for you already.

`Oh My Zsh`__
`````````````

__ https://github.com/robbyrussell/oh-my-zsh

.. code:: console

  $ git clone https://github.com/andydecleyre/zpy $ZSH_CUSTOM/plugins/zpy

Then add ``zpy`` to your ``plugins`` array in ``~/.zshrc``.

Prezto__
````````

__ https://github.com/sorin-ionescu/prezto

.. code:: console

  $ git clone https://github.com/andydecleyre/zpy $ZPREZTODIR/modules/zpy

Then add ``zpy`` to your pmodule list in ``~/.zpreztorc``.

Zim__
`````

__ https://github.com/zimfw/zimfw

.. code:: console

  $ print zmodule andydecleyre/zpy >> ~/.zimrc
  $ zimfw install

Antibody__
``````````

__ https://github.com/getantibody/antibody

.. code:: console

  $ print antibody bundle andydecleyre/zpy >> ~/.zshrc

Zinit__
```````

__ https://github.com/zdharma/zinit

.. code:: console

  $ print zinit light andydecleyre/zpy >> ~/.zshrc

Antigen__
`````````

__ https://github.com/zsh-users/antigen

Put ``antigen bundle andydecleyre/zpy`` in your ``~/.zshrc``, before ``antigen apply``.

zgen__
``````

__ https://github.com/tarjoilija/zgen

Put ``zgen load andydecleyre/zpy`` in the plugin section of your ``~/.zshrc``, then

.. code:: console

    $ zgen reset

zplug__
```````

__ https://github.com/zplug/zplug

Put ``zplug "andydecleyre/zpy"`` in ``~/.zshrc`` (after ``source ~/.zplug/init.zsh``,
before ``zplug load``), then

.. code:: console

    $ zplug install; zplug load

Dependencies
------------

Jump to `Dependency Installation`_ for a recommended command for your distro.

The big ones:

- zsh_
- python_
- fzf_

The ones you already have anyway, probably:

diff
  provided by diffutils_, busybox_, BSD, or macOS
du
  provided by coreutils_, busybox_, toybox_, BSD, or macOS
md5sum *or* md5
  provided by coreutils_, busybox_, toybox_, BSD, or macOS
mktemp
  provided by coreutils_, busybox_, toybox_, BSD, or macOS
nproc *or* sysctl
  provided by coreutils_, busybox_, toybox_, BSD, or macOS
wget *or* curl
  provided by wget_, curl_, busybox_, or macOS
a pcre tool
  provided by pcregrep/pcre-tools, pcre2grep/pcre2-tools, ripgrep_, or zsh with pcre enabled

The very optional ones:

highlight_ *or* bat_
  for pretty syntax highlighting
delta_ *or* diff-so-fancy_ *or* diff-highlight (from git + perl)
  for more pretty syntax highlighting
jq_ *or* jello_
  for theoretically more reliable parsing
python2 *and* virtualenv_
  for python2 support
git
  for easy installation of zpy itself

Dependency Installation
```````````````````````

Alpine
~~~~~~

.. code:: console

  $ sudo apk add fzf git highlight pcre2-tools python3 zsh

Arch
~~~~

.. code:: console

  $ sudo pacman -S fzf git highlight python zsh

Debian/Ubuntu
~~~~~~~~~~~~~

.. code:: console

  $ sudo apt --no-install-recommends install fzf git highlight pcre2-utils python3{,-venv} zsh

Fedora
~~~~~~

.. code:: console

  $ sudo dnf --setopt=install_weak_deps=False install diffutils fzf git-core highlight pcre-tools python3 zsh

MacOS
~~~~~

.. code:: console

  $ brew install fzf git highlight pcre2 python zsh

OpenSUSE
~~~~~~~~

.. code:: console

  $ sudo zypper in fzf git highlight pcre2-tools python3 zsh

Extra Scripts
-------------

You may wish to generate some "standalone" scripts for some of the provided functions --
particularly ``vpy``. You can do so with, for example:

.. code:: console

  $ .zpy_mkbin vpy ~/.local/bin

Environment Variables
---------------------

Users may want to override these:

``ZPY_VENVS_WORLD``
  Each project is associated with: ``$ZPY_VENVS_WORLD/<hash of proj-dir>/<venv-name>``.

  ``<venv-name>`` is one or more of: ``venv``, ``venv2``, ``venv-pypy``, ``venv-<pyver>``

  ``$(venvs_path <proj-dir>)`` evaluates to ``$ZPY_VENVS_WORLD/<hash of proj-dir>``.

  This is normally ``~/.local/share/venvs``.

``ZPY_PIPZ_PROJECTS`` and ``ZPY_PIPZ_BINS``
  Installing an app via ``pipz`` puts ``requirements.{in,txt}`` in
  ``$ZPY_PIPZ_PROJECTS/<appname>``, and executables in ``$ZPY_PIPZ_BINS``.

  These are normally ``~/.local/share/python`` and ``~/.local/bin``.

.. |repo| image:: https://img.shields.io/github/size/andydecleyre/zpy/zpy.plugin.zsh?logo=github&label=Code&color=blueviolet
   :alt: GitHub file size in bytes
   :target: https://github.com/andydecleyre/zpy

.. |container-alpine| image:: https://img.shields.io/badge/Container-Quay.io-green?logo=alpine-linux
   :alt: Demo container - Alpine Linux
   :target: https://quay.io/repository/andykluger/zpy-alpine

.. |container-fedora| image:: https://img.shields.io/badge/Container-Quay.io-green?logo=fedora
   :alt: Demo container - Fedora
   :target: https://quay.io/repository/andykluger/zpy-fedora

.. |container-ubuntu| image:: https://img.shields.io/badge/Container-Quay.io-green?logo=ubuntu
   :alt: Demo container - Ubuntu
   :target: https://quay.io/repository/andykluger/zpy-ubuntu

.. |container-ci| image:: https://andydecleyre.semaphoreci.com/badges/zpy/branches/develop.svg
   :alt: Demo container - Semaphore CI
   :target: https://andydecleyre.semaphoreci.com/projects/zpy

.. |contact| image:: https://img.shields.io/badge/Contact-Telegram-blue?logo=telegram
   :alt: Contact developer on Telegram
   :target: https://t.me/andykluger

.. |docsite| image:: https://readthedocs.org/projects/zpy/badge/
   :alt: Documentation Status
   :target: https://zpy.readthedocs.io/en/latest/

.. _bat: https://repology.org/project/bat/versions
.. _busybox: https://repology.org/project/busybox/versions
.. _coreutils: https://repology.org/project/coreutils/versions
.. _curl: https://repology.org/project/curl/versions
.. _delta: https://repology.org/project/git-delta/versions
.. _diff-so-fancy: https://repology.org/project/diff-so-fancy/versions
.. _diffutils: https://repology.org/project/diffutils/versions
.. _fzf: https://repology.org/project/fzf/versions
.. _highlight: https://repology.org/project/highlight/versions
.. _jello: https://pypi.org/project/jello/
.. _jq: https://repology.org/project/jq/versions
.. _python: https://repology.org/project/python/versions
.. _ripgrep: https://repology.org/project/ripgrep/versions
.. _toybox: https://repology.org/project/toybox/versions
.. _virtualenv: https://repology.org/project/python:virtualenv/versions
.. _wget: https://repology.org/project/wget/versions
.. _zsh: https://repology.org/project/zsh/versions
