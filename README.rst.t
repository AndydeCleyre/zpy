================================================
zpy: Zsh helpers for Python venvs with pip-tools
================================================

These functions aim to help with your workflows, without being restrictive.

.. image:: https://asciinema.org/a/hixMbnxd3fxi4kJxXe5OnBs4n.svg
   :target: https://asciinema.org/a/hixMbnxd3fxi4kJxXe5OnBs4n

Installation
------------

- Put ``python.zshrc`` somewhere, like ``~/.python.zshrc``, or just clone this small repo.
- Source it in your main ``~/.zshrc``, like ``. /path/to/python.zshrc``.
- If you'd like some handy venv-python script launchers accessible outside your Zsh environment, put the ``vpy`` and ``vpyfrom`` scripts somewhere in your ``PATH`` (e.g. ``~/bin``, ``~/.local/bin``, ``/usr/local/bin``).

Guiding Ideas
-------------

- You should not have to manually specify the requirements anywhere other than ``*requirements.in`` files.
- Folks who want to use your code shouldn't have to install any new-fangled less-standard tools (pipenv, poetry, pip-tools, zpy, etc.). ``pip install -r requirements.txt`` ought to be sufficient.
- Your workflow should be transparent and personal. Run ``which <function>`` to see what it does. Modify it. Add your own.
- Any project folder may be associated with an external venvs folder, deterministically generated from the project path.
- Within each venvs folder we have:

  + one or more named venv folders based on the desired Python (i.e. 'venv', 'venv2', 'venvPyPy')
  + a symlink back to the project folder

Usage Examples
--------------

For full, concise list of functions and their descriptions and arguments, see `Functions & Aliases`_.

Create venv; activate venv; install appropriate packages; uninstall inappropriate packages
``````````````````````````````````````````````````````````````````````````````````````````

Without zpy:

.. code-block:: bash

     python -m venv /path/to/project_venv  # if venv not created yet
     . /path/to/project_venv/bin/activate
     pip install -U pip pip-tools
     pip-sync *requirements.txt  # if present
     pip install -r requirements.txt  # if present
     pip install -r dev-requirements.txt  # if present
     pip install -r test-requirements.txt  # if present (etc.)

With zpy:

.. code-block:: bash

    envin

Add regular requirements; generate lockfile; install and uninstall to match regular requirements
````````````````````````````````````````````````````````````````````````````````````````````````

Without zpy:

.. code-block:: bash

    echo 'requests>=2.22.0' >> requirements.in
    echo structlog >> requirements.in
    pip-compile --no-header requirements.in
    pip-sync requirements.txt

With zpy:

.. code-block:: bash

    pipacs 'requests>=2.22.0' structlog

Add categorized requirements; generate lockfiles; install and uninstall to match all categories of requirements
```````````````````````````````````````````````````````````````````````````````````````````````````````````````

Without zpy:

.. code-block:: bash

    echo pytest >> test-requirements.in
    echo ipython >> dev-requirements.in
    pip-compile --no-header test-requirements.in
    pip-compile --no-header dev-requirements.in
    pip-sync *requirements.in

With zpy:

.. code-block:: bash

    pipatest pytest
    pipadev ipython
    pipcs

Add and remove categorized loose requirements in a flit-generated ``pyproject.toml`` file to match your project
```````````````````````````````````````````````````````````````````````````````````````````````````````````````

Without zpy:

- read all the requirements.in files manually,
- look up the appropriate ``pyproject.toml`` syntax,
- which varies a bit depending on whether the reqs are categorized,
- edit the ``pyproject.toml`` file by hand with all the reqs you find,
- and make sure to remove ones you don't find

With zpy:

.. code-block:: bash

    pypc

Update locked requirements to latest available, but constrained by any specs in ``*requirements.in`` files
``````````````````````````````````````````````````````````````````````````````````````````````````````````

Without zpy:

.. code-block:: bash

    pip-compile --no-header -U requirements.in  # if updating ALL requirements
    pip-compile --no-header -U dev-requirements.in  # if present, if updating ALL requirements
    pip-compile --no-header -U test-requirements.in  # if present, if updating ALL requirements (etc.)

    pip-compile --no-header -P requests -P structlog requirements.in  # if updating specific requirements
    pip-compile --no-header -P ipython dev-requirements.in  # if present, if updating specific requirements
    pip-compile --no-header -P pytest test-requirements.in  # if present, if updating specific requirements (etc.)

With zpy:

.. code-block:: bash

    pipu  # if updating ALL requirements
    pipu requests structlog ipython pytest  # if updating specific requirements

Launch Python script using its project's venv, from outside the venv
````````````````````````````````````````````````````````````````````

Without zpy:

.. code-block:: bash

    /path/to/project_venv/bin/python script.py

With zpy:

.. code-block:: bash

    vpy script.py

Alter Python script so that it's always launched using its project's venv, from outside the venv
`````````````````````````````````````````````````````````````````````````````````````````````````

Without zpy:

- manually prepend ``#@!!@!/path/to/project_venv/bin/python`` to ``script.py``

.. code-block:: bash

    chmod +x script.py

With zpy:

.. code-block:: bash

    vpyshebang script.py

Launch Python script that's installed in the project's venv's bin folder, from outside the venv
```````````````````````````````````````````````````````````````````````````````````````````````

Without zpy:

.. code-block:: bash

    /path/to/project_venv/bin/script

With zpy:

.. code-block:: bash

    vpyfrom /path/to/project script

Generate launcher script that runs a venv-installed script (bin folder) from outside the venv
`````````````````````````````````````````````````````````````````````````````````````````````

Without zpy:

- create file ``script``
- manually write into it:

.. code-block:: bash

    #@!!@!/bin/sh
    exec /path/to/project_venv/bin/script "$@"

- then

.. code-block:: bash

    chmod +x script

With zpy:

.. code-block:: bash

    vpylauncherfrom /path/to/project script .

Functions & Aliases
-------------------

.. code-block:: bash

<!--(for line in help.splitlines())-->
  $! line !$
<!--(end)-->

Feedback welcome! Submit an issue here or reach me on Telegram__.

__ https://t.me/andykluger
