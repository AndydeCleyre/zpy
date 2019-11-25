================================================
zpy: Zsh helpers for Python venvs with pip-tools
================================================

These functions aim to help with your workflows, without being restrictive.

They can generally replace usage of pipenv, poetry [#]_, pipx, virtualenvwrapper, etc.

.. [#] when used with flit__

__ https://flit.readthedocs.io/en/latest/

.. code-block:: bash

    envin
    pipacs requests structlog

Guiding Ideas
-------------

- You should not have to manually specify the requirements anywhere other than
  ``*requirements.in`` files.
- Folks who want to use your code shouldn't have to install any new-fangled
  less-standard tools (pipenv, poetry, pip-tools, zpy, etc.).
  ``pip install -r requirements.txt`` ought to be sufficient.
- Your workflow should be transparent and personal. Run ``zpy <function>`` to see its
  documentation, and ``which <function>`` to see its entire content.
  Modify it. Add your own.

Preview
-------

.. image:: https://s5.gifyu.com/images/1574710326.gif

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

Basic Operations
----------------

In and Out
``````````

The primary commands for managing whether you're inside or outside a venv are ``envin``
and ``envout``. Extra helpers include ``activate``, ``activatefzf``, ``envin2``,
``envinpypy``, and ``envinpy``.

``envin`` will:

- create a new venv for the current folder, if it doesn't already exist
- activate the venv
- ensure pip-tools is installed in the venv
- install and uninstall packages as necessary to exactly match those specified in all
  *reqs-txt*\ s in the folder (*sync*)

.. image:: https://s5.gifyu.com/images/1574710894.gif

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

You may pass one or more requirements to ``pipa`` to add lines to your
``requirements.in``. Helpers that work the same way are provided for some categorized
``*-requirements.in`` files as well: ``pipabuild``, ``pipadev``, ``pipadoc``,
``pipapublish``, and ``pipatest``. You can also add special constraints__ for layered
requirements workflows, or add "include" lines like ``-r prod-requirements.in``.

__ https://pip.pypa.io/en/stable/reference/pip_install/#requirements-file-format

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
``pipac``/``pipach`` (*add*, *compile*), ``pipacs``/``pipachs``
(*add*, *compile*, *sync*), and ``pipus``/``pipuhs`` (*upgrade-compile*, *sync*).

.. image:: https://s5.gifyu.com/images/1574712687.gif

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

Installation
------------

Try it isolation with docker or podman, if you like:

.. code-block:: bash

    docker run --net=host -it andydecleyre/zpy-alpine:latest
    podman run --net=host -it docker.io/andydecleyre/zpy-alpine:latest

Install dependencies as appropriate for your platform, then:

.. code-block:: bash

    git clone https://github.com/andydecleyre/zpy
    ln -s $PWD/zpy/python.zshrc ~/.python.zshrc
    echo '. ~/.python.zshrc' >> ~/.zshrc

It doesn't have to be ``~/.python.zshrc``, it can be anywhere.

If you use a fancy Zsh plugin tool, you can install with a command like one of these:

.. code-block:: bash

    antigen bundle andydecleyre/zpy python.zshrc
    antibody bundle andydecleyre/zpy path:python.zshrc
    zgen load andydecleyre/zpy python.zshrc

Dependencies for Popular Platforms
``````````````````````````````````

To make use of this project, you'll need ``zsh``, ``python``, and
``busybox``/``coreutils`` or similar.

``pcregrep`` is only needed for the ``zpy`` function, and is already a dependency of
``zsh`` on Arch Linux and MacOS (via Homebrew__).

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

Functions & Aliases
-------------------

.. code-block:: bash

    
    # pipe pythonish syntax through this to make it colorful
    hpype  
    
    # print description and arguments for all or specified functions
    # to see actual function contents, use `which <funcname>`
    zpy  # [zpy-function]
    
    # get path of folder containing all venvs for the current folder or specified proj-dir
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
    pipa  # <req> [req...]
    pipabuild  # <req> [req...]
    pipadev  # <req> [req...]
    pipadoc  # <req> [req...]
    pipapublish  # <req> [req...]
    pipatest  # <req> [req...]
    
    # add to requirements.in, then compile it to requirements.txt
    pipac  # <req> [req...]
    # add to requirements.in, then compile it with hashes to requirements.txt
    pipach  # <req> [req...]
    # add to requirements.in, compile it to requirements.txt, then sync to that
    pipacs  # <req> [req...]
    # add to requirements.in, compile it with hashes to requirements.txt, then sync to that
    pipachs  # <req> [req...]
    
    # recompile *requirements.txt with upgraded versions of all or specified packages (upgrade)
    pipu  # [req...]
    # upgrade with hashes
    pipuh  # [req...]
    
    # upgrade, then sync
    pipus  # [req...]
    pipuhs  # [req...]
    
    # activate venv 'venv' for the current folder and install requirements, creating venv if necessary
    # python version will be whatever `python3` refers to at time of venv creation
    envin  # [reqs-txt...]
    # like envin, but with venv 'venv2' and python2
    envin2  # [reqs-txt...]
    # like envin, but with venv 'venv-pypy' and pypy3
    envinpypy  # [reqs-txt...]
    # like envin, but with venv 'venv-<pyver>' and command `python`
    # useful if you use pyenv or similar for multiple py3 versions on the same project
    envinpy  # [reqs-txt...]
    
    # activate without installing anything
    activate  # [proj-dir]
    activatefzf
    # deactivate
    envout  
    
    # get path of python for the given script's folder's associated venv
    whichvpy  # <script>
    
    # run script with its folder's associated venv 'venv'
    vpy  # <script> [script-arg...]
    # like vpy, but with venv 'venv2'
    vpy2  # <script> [script-arg...]
    # like vpy, but with venv 'venv-pypy'
    vpypy  # <script> [script-arg...]
    # like vpy, but with venv 'venv-<pyver>'
    vpyenv  # <script> [script-arg...]
    
    # get path of project for the activated venv
    whichpyproj
    
    # prepend each script with a shebang for its folder's associated venv python
    # if vpy exists in the PATH, #!/path/to/vpy will be used instead
    # also ensure the script is executable
    vpyshebang  # <script> [script...]
    vpy2shebang  # <script> [script...]
    vpypyshebang  # <script> [script...]
    vpyenvshebang  # <script> [script...]
    
    # run script from a given project folder's associated venv's bin folder
    vpyfrom  # <proj-dir> <script-name> [script-arg...]
    vpy2from  # <proj-dir> <script-name> [script-arg...]
    vpypyfrom  # <proj-dir> <script-name> [script-arg...]
    vpyenvfrom  # <proj-dir> <script-name> [script-arg...]
    
    # generate an external launcher for a script in a given project folder's associated venv's bin folder
    vpylauncherfrom  # <proj-dir> <script-name> <launcher-dest>
    
    # delete venvs for project folders which no longer exist
    prunevenvs
    
    # pip list -o for all or specified projects
    pipcheckold  # [proj-dir...]
    
    # pipus for all or specified projects
    pipusall  # [proj-dir...]
    
    # inject loose requirements.in dependencies into pyproject.toml
    # run either from the folder housing pyproject.toml, or one below
    # to categorize, name files <category>-requirements.in
    pypc
    
    # specify the venv interpreter in a new or existing sublime text project file for the working folder
    vpysublp
    
    # launch a new or existing sublime text project, setting venv interpreter
    sublp  # [subl-arg...]
    
    # a basic pipx clone (py3 only)
    # if no pkg is provided to {uninstall,upgrade,reinstall}, *all* pkgs will be affected
    # supported commands (pipx semantics):
    # pipz install <pkg> [pkg...]
    # pipz uninstall [pkg...]
    # pipz upgrade [pkg...]
    # pipz list
    # pipz reinstall [pkg...]
    # pipz inject <pkg> <extra-pkg> [extra-pkg...]
    # pipz runpip <pkg> <pip-arg...>
    # pipz runpkg <pkg> <cmd> [cmd-arg...]
    # pipz  # show usage
    pipz  # [install|uninstall|upgrade|list|reinstall|inject|runpip|runpkg] [subcmd-arg...]

Feedback welcome! Submit an issue here or reach me on Telegram__.

__ https://t.me/andykluger
