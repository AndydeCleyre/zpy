================================================
zpy: Zsh helpers for Python venvs with pip-tools
================================================

These functions aim to help with your workflows, without being restrictive.

They can generally replace usage of pipenv, poetry [#]_, pipx, virtualenvwrapper, etc.

.. [#] when used with flit__

__ https://flit.readthedocs.io/en/latest/

.. code-block:: bash

    envin
    pipacs requests pendulum

Guiding Ideas
-------------

- You should not have to manually specify the requirements anywhere other than ``*requirements.in`` files.
- Folks who want to use your code shouldn't have to install any new-fangled less-standard tools (pipenv, poetry, pip-tools, zpy, etc.). ``pip install -r requirements.txt`` ought to be sufficient.
- Your workflow should be transparent and personal. Run ``zpy <function>`` to see its documentation, and ``which <function>`` to see its entire content. Modify it. Add your own.
- Each project folder is associated with an external ``venvs`` folder (``$XDG_DATA_HOME/venvs/<project path hash>`` or ``~/.local/share/venvs/<project path hash>``).
- Within each ``venvs`` folder we have:

  + one or more named venv folders (``venv``, ``venv2``, ``venvPyPy``) based on the desired Python
  + a symlink back to the project folder

Preview
-------

.. image:: https://s3.gifyu.com/images/previewee81b820d6596f2f.gif

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

You can see exactly what a command will do with ``which <command>``, and get explanations and accepted arguments with ``zpy <command>``. Running ``zpy`` alone will show all descriptions and arguments.

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

Oh, and there's a mini pipx clone, ``pipz``.

But wait, there's more! Find it all down at `Functions & Aliases`_.

Installation
------------

- Put ``python.zshrc`` somewhere, like ``~/.python.zshrc``, or just clone this repo.
- Source it in your main ``~/.zshrc``, like ``. /path/to/python.zshrc``.

Or if you use a fancy Zsh plugin tool, you can install with a command like one of these:

.. code-block:: bash

    antigen bundle andydecleyre/zpy python.zshrc
    antibody bundle andydecleyre/zpy path:python.zshrc

If you'd like some handy venv-python script launchers accessible outside your interactive Zsh environment, put the included ``vpy`` and ``vpyfrom`` scripts somewhere in your ``PATH`` (e.g. ``~/bin``, ``~/.local/bin``, ``/usr/local/bin``).

Some functions (``activatefzf`` and ``pipz``) require fzf__.

__ https://github.com/junegunn/fzf

The ``zpy`` function currently uses ``pcregrep`` [#]_, which is a dependency of ``zsh`` on some distributions, but not others. If you don't like this dependency, please submit an issue.

.. [#] provided by: ``pcregrep`` on Debian; ``pcre-tools`` on Alpine/Fedora/OpenSUSE

You can optionally enable pretty syntax highlighting by installing either highlight__ or bat__.

__ http://www.andre-simon.de/doku/highlight/highlight.html

__ https://github.com/sharkdp/bat

Functions & Aliases
-------------------

.. code-block:: bash

    # path of folder containing all project-venvs (venvs_path) folders
    # each project is linked to one or more of:
    # <VENVS_WORLD>/<`venvs_path proj-dir`>/{venv,venv2,venvPyPy}
    
    # syntax highlighter, reading stdin
    _hlt  # <syntax>
    # pipe pythonish syntax through this to make it colorful
    hpype  
    
    # print description and arguments for all or specified functions
    # to see actual function contents, use `which <funcname>`
    zpy  # [zpy-function [python.zshrc]]
    
    # get path of folder containing all venvs for the current folder or specified project path
    venvs_path  # [proj-dir]
    
    # start REPL
    i  
    i2  
    
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
    activate  # [proj-dir]
    activatefzf
    # deactivate
    envout  
    
    # get path of python for the given script's folder's associated venv
    _whichvpy  # <venv-name> <script>
    whichvpy  # <script>
    
    # run script with its folder's associated venv
    _vpy  # <venv-name> <script> [script-arg...]
    vpy  # <script> [script-arg...]
    vpy2  # <script> [script-arg...]
    vpypy  # <script> [script-arg...]
    
    # get path of project for the activated venv
    whichpyproj
    
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
    
    # delete venvs for project folders which no longer exist
    prunevenvs
    
    # pip list -o for all projects
    pipcheckold
    
    # pipus for all or specified projects
    pipusall  # [proj-dir...]
    
    # inject loose requirements.in dependencies into pyproject.toml
    # run either from the folder housing pyproject.toml, or one below
    # to categorize, name files <category>-requirements.in
    pypc
    
    # get a new or existing sublime text project file for the working folder
    _get_sublp
    
    # specify the venv interpreter in a new or existing sublime text project file for the working folder
    vpysublp
    
    # launch a new or existing sublime text project, setting venv interpreter
    sublp  # [subl-arg...]
    
    # a basic pipx clone
    # supported commands:
    # pipz install <pkg> [pkg...]
    # pipz uninstall <pkg> [pkg...]
    # pipz upgrade <pkg> [pkg...]
    # pipz upgrade-all
    # pipz list
    # pipz uninstall-all
    # pipz reinstall-all
    # pipz inject <pkg> <extra-pkg> [extra-pkg...]
    # pipz runpip <pkg> <pip-arg...>
    # pipz runfrom <pkg> <cmd> [cmd-arg...]
    # not implemented: run (use runfrom); ensurepath; completions
    pipz

Feedback welcome! Submit an issue here or reach me on Telegram__.

__ https://t.me/andykluger
