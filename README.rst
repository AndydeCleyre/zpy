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
- Folks who want to use your code shouldn't have to install any new-fangled less-standard tools (pipenv, poetry, zpy, etc.). ``pip install -r requirements.txt`` ought to be sufficient.
- Any project folder may be associated with an external venvs folder, deterministically generated from the project path.
- Within each venvs folder we have:

  + one or more named venv folders based on the desired Python (i.e. 'venv', 'venv2', 'venvPyPy')
  + a symlink back to the project folder

Functions & Aliases
-------------------

.. code-block:: bash

  # get path of folder containing all venvs for the current folder or specified project path
  venvs_path  # [proj-dir]
  
  # pipe pythonish syntax through this to make it colorful
  hpype
  
  # start REPL
  alias i="ipython"
  alias i2="ipython2"
  
  # install packages
  pipi  # <req> [req...]
  
  # compile requirements.txt files from all found or specified requirements.in files (compile)
  pipc  # [reqs-in...]
  # compile with hashes
  pipch  # [reqs-in...]
  
  # install packages according to all found or specified requirements.txt files (sync)
  pips  # [reqs-txt...]
  
  # compile, then sync
  pipcs  # [reqs-in...]
  # compile with hashes, then sync
  pipchs  # [reqs-in...]
  
  # add loose requirements to [<category>-]requirements.in (add)
  _pipa  # <category> <req> [req...]
  pipa  # <req> [req...]
  pipabuild  # <req> [req...]
  pipadev  # <req> [req...]
  pipadoc  # <req> [req...]
  pipapublish  # <req> [req...]
  pipatest  # <req> [req...]
  
  # add to requirements.in and compile it to requirements.txt
  pipac  # <req> [req...]
  # add to requirements.in and compile it with hashes to requirements.txt
  pipach  # <req> [req...]
  # add to requirements.in and compile it to requirements.txt, then sync to that
  pipacs  # <req> [req...]
  # add to requirements.in and compile it with hashes to requirements.txt, then sync to that
  pipachs  # <req> [req...]
  
  # recompile *requirements.txt with upgraded versions of all or specified packages (upgrade)
  pipu  # [req...]
  # upgrade with hashes
  pipuh  # [req...]
  
  # upgrade, then sync
  pipus  # [req...]
  pipuhs  # [req...]
  
  # activate venv for the current folder and install requirements, creating venv if necessary
  _envin  # <venv-name> <venv-init-cmd> [reqs-txt...]
  envin  # [reqs-txt...]
  envin2  # [reqs-txt...]
  envinpypy  # [reqs-txt...]
  
  # activate without installing anything
  activate
  # deactivate
  envout
  
  # get path of python for the given script's folder's associated venv
  _whichpy  # <venv-name> <script>
  
  # run script with its folder's associated venv
  _vpy  # <venv-name> <script> [script-arg...]
  vpy  # <script> [script-arg...]
  vpy2  # <script> [script-arg...]
  vpypy  # <script> [script-arg...]
  
  # prepend each script with a shebang for its folder's associated venv python
  # if vpy exists in the PATH, #!/path/to/vpy will be used instead
  # also ensure the script is executable
  _vpyshebang  # <venv-name> <script> [script...]
  vpyshebang  # <script> [script...]
  vpy2shebang  # <script> [script...]
  vpypyshebang  # <script> [script...]
  
  # run script from a given project folder's associated venv's bin folder
  _vpyfrom  # <venv-name> <proj-dir> <script-name> [script-arg...]
  vpyfrom  # <proj-dir> <script-name> [script-arg...]
  vpy2from  # <proj-dir> <script-name> [script-arg...]
  vpypyfrom  # <proj-dir> <script-name> [script-arg...]
  
  # generate an external launcher for a script in a given project folder's associated venv's bin folder
  vpylauncherfrom  # <proj-dir> <script-name> <launcher-dest>
  
  # inject loose requirements.in dependencies into pyproject.toml
  # run either from the folder housing pyproject.toml, or one below
  # to categorize, name files <category>-requirements.in
  pypc
  
  # get a new or existing sublime text project file for the working folder
  _get_sublp
  
  # specify the venv interpreter in a new or existing sublime text project file
  vpysublp
  
  # launch a new or existing sublime text project, setting venv interpreter
  sublp  # [subl-arg...]

Workflow Example Equivalents
----------------------------

How do you use pipenv/poetry/whatever? Send me examples, and I'll add them here with their zpy equivalents.

Feedback welcome! Submit an issue here or reach me on Telegram__.

__ https://t.me/andykluger
