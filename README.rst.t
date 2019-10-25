================================================
zpy: Zsh helpers for Python venvs with pip-tools
================================================

These functions aim to help with your workflows, without being restrictive.

.. image:: https://s3.gifyu.com/images/previewee81b820d6596f2f.gif

Guiding Ideas
-------------

- You should not have to manually specify the requirements anywhere other than ``*requirements.in`` files.
- Folks who want to use your code shouldn't have to install any new-fangled less-standard tools (pipenv, poetry, pip-tools, zpy, etc.). ``pip install -r requirements.txt`` ought to be sufficient.
- Your workflow should be transparent and personal. Run ``zpy <function>`` to see what it does. Modify it. Add your own.
- Each project folder is associated with an external ``venvs`` folder (``$XDG_DATA_HOME/venvs/<project path hash>`` or ``~/.local/share/venvs/<project path hash>``).
- Within each ``venvs`` folder we have:

  + one or more named venv folders (``venv``, ``venv2``, ``venvPyPy``) based on the desired Python
  + a symlink back to the project folder

Basic Operations
----------------

In and Out
``````````

The commands for managing whether you're inside or outside a venv are ``envin``, ``activate``, ``activatefzf``, and ``envout``.

``envin`` will:

- create a new venv for the current folder, if it doesn't already exist
- activate the venv
- ensure pip-tools__ is installed in the venv
- install and uninstall packages as necessary to exactly match those specified in all ``*requirements.txt`` files in the folder ("sync")

__ https://github.com/jazzband/pip-tools

.. image:: https://i.imgur.com/4vz8huE.png

You may also pass as many specific ``*requirements.txt`` files as you want to ``envin``, in which case it will ensure your environment matches those and only those.

If you know your environment is already in a good state, and just want to activate it without all that installing and uninstalling, you can save a second by running ``activate`` instead.

You may also pass a project folder to ``activate``, in order to activate a specific venv regardless of your current folder.

If you have ``fzf`` installed, you can use ``activatefzf`` to interactively select the project whose venv you wish to activate.

.. image:: https://i.imgur.com/0VPQWtF.png

``envout`` is a totally unnecessary equivalent of ``deactivate``, and you can use either one to deactivate a venv.

Add, Compile, Sync
``````````````````

The basic operations are *add*, *compile*, and *sync* (``pipa``, ``pipc``, ``pips``).

Adding a requirement is simply putting a new ``requirements.txt``-syntax__ line into ``requirements.in``, or a categorized ``<category>-requirements.in``.

You may pass one or more requirements to ``pipa`` to add lines to your ``requirements.in``. Helpers that work the same way are provided for some categorized ``*-requirements.in`` files as well: ``pipabuild``, ``pipadev``, ``pipadoc``, ``pipapublish``, and ``pipatest``. You can also add special constraints__ for layered requirements workflows, or add "include" lines like ``-r prod-requirements.in``.

__ https://pip.pypa.io/en/stable/reference/pip_install/#requirements-file-format

__ https://github.com/jazzband/pip-tools#workflow-for-layered-requirements

``pipc`` will generate version-locked ``*requirements.txt`` files including all dependencies from the information in each found ``*requirements.in`` in the current folder. You may also pass one or more specific in-files instead. If you want hashes included in the output, use ``pipch``.

``pipu`` and ``pipuh`` are similar, but ensure dependencies are upgraded as far as they can be while matching the specifications in the in-files. These commands accept specific packages as arguments, if you wish to only upgrade those.

``pips`` will "sync" your environment to match your ``*requirements.txt`` files, installing and uninstalling packages as necessary. You may also pass specific ``*requirements.txt`` files as arguments to match only those.

Often, you'll want to do a few of these things at a time. You can do so with ``pipac``, ``pipach``, ``pipacs``, ``pipachs``, ``pipus``, and ``pipuhs``.

.. image:: https://i.imgur.com/GcWPIFA.png

You can always see exactly what a command will do, with explanations and accepted arguments, by running ``zpy <command>``. Running ``zpy`` alone will show all descriptions and arguments, while omitting implementation details.

For a full, concise list of functions and their descriptions and arguments, see `Functions & Aliases`_.

Bonus Operations
----------------

Welcome to the bonus round!

If you use flit__ to package your code for PyPI, and I recommend you do, you can automatically update your ``pyproject.toml``'s categorized dependencies from the information in your ``*requirements.in`` files with ``pypc``.

__ https://flit.readthedocs.io/en/latest/

Launch a Python script using its project's venv, from outside the venv, with ``vpy <script.py>``.

Alter a Python script so that it's always launched using its project's venv, from outside the venv, with ``vpyshebang <script.py>``.

Launch a Python script that's installed in its project's venv's ``bin`` folder, from outside the venv, with ``vpyfrom </path/to/project> <script>``.

Generate a launcher script that runs a venv-installed script (in the ``bin`` folder) from outside the venv, with ``vpylauncherfrom </path/to/project> <script-name> <destination>``.

But wait, there's more! Find it all down at `Functions & Aliases`_.

Installation
------------

- Put ``python.zshrc`` somewhere, like ``~/.python.zshrc``, or just clone this repo.
- Source it in your main ``~/.zshrc``, like ``. /path/to/python.zshrc``.

Or if you use a fancy Zsh plugin tool, you can install with a command like one of these:

.. code-block:: bash

    antigen bundle andydecleyre/zpy python.zshrc
    antibody bundle andydecleyre/zpy path:python.zshrc

If you'd like some handy venv-python script launchers accessible outside your Zsh environment, put the ``vpy`` and ``vpyfrom`` scripts somewhere in your ``PATH`` (e.g. ``~/bin``, ``~/.local/bin``, ``/usr/local/bin``).

Functions & Aliases
-------------------

.. code-block:: bash

<!--(for line in help.splitlines())-->
  $! line !$
<!--(end)-->

Feedback welcome! Submit an issue here or reach me on Telegram__.

__ https://t.me/andykluger
