================================================
zpy: ZSH helpers for Python venvs with pip-tools
================================================

These functions aim to help with your workflows, without being restrictive.

.. image:: https://asciinema.org/a/hixMbnxd3fxi4kJxXe5OnBs4n.svg
   :target: https://asciinema.org/a/hixMbnxd3fxi4kJxXe5OnBs4n

Installation
------------

- Put ``python.zshrc`` somewhere, like ``~/.python.zshrc``, or just clone this small repo.
- Source it in your main ``~/.zshrc``, like ``. /path/to/python.zshrc``.
- If you'd like some handy venv-python script launchers accessible outside your ZSH environment, put the ``vpy`` and ``vpyfrom`` scripts somewhere in your ``PATH`` (e.g. ``~/bin``, ``~/.local/bin``, ``/usr/local/bin``).


Guiding Ideas
-------------

- You should not have to manually specify the requirements anywhere other than ``*requirements.in`` files.
- Folks who want to use your code shouldn't have to install any new-fangled less-standard tools (pipenv, poetry, zpy, etc.). ``pip install -r requirements.txt`` ought to be sufficient.
- Any project folder may be associated with an external venvs folder, deterministically generated from the project path.
- Within each venvs folder we have:

  + one or more named venv folders based on the desired Python (i.e. 'venv', 'venv2', 'venvPyPy')
  + a symlink back to the project folder

Functions & Aliases
-------------------

.. code-block:: bash

<!--(for line in help.splitlines())-->
  $! line !$
<!--(end)-->

Workflow Example Equivalents
----------------------------

How do you use pipenv/poetry/whatever? Send me examples, and I'll add them here with their zpy equivalents.

Feedback welcome! Submit an issue here or reach me on Telegram__.

__ https://t.me/andykluger
