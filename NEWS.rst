====
News
====

Unreleased
==========

Changed
-------

- Use uv, if present, to create venvs
- When using rich as syntax highlighter,
  never truncate lines, but wrap them
- The minimum version of pip-tools is bumped to 7.1.0
- Since Linux Mint shadows the ``highlight`` command,
  demote it in the search order in ``.zpy_hlt``, for now.
- Stop abbreviating diffs during pipz upgrade,
  as it was breaking some highlighters (riff at least)

Fixed
-----

- Don't complain if the installed version of highlight is too old to know TOML

0.3.2
=====

Added
-----

- Requirements category completions now additionally suggest ``ops``
- A little more info about category completion in the docs

Changed
-------

- The minimum version of pip-tools is bumped to 6.9.0
- The shell parameter ``PIP_TOOLS_RESOLVER`` is replaced by
  a new default option passed to ``pip-compile``: ``--resolver=backtracking``
- ``pypc``: When parsing '``-r ...txt``' lines, use the corresponding ``.in`` file
  contents if available, instead. This more consistently injects *loose* requirements.
- Doc site de-integrates local TOC, in favor of right hand side local TOC
- ``pipz``: unless installing the ``build`` package explicitly, don't install ``pyproject-build`` script

Fixed
-----

- Bug in ``pypc`` where an empty string could get added to reqs list

0.3.1
=====

Added
-----

- When zsh-defer is present,
  pre-cache PyPI package list when plugin loads,
  if not yet cached at all

Changed
-------

- Minor documentation edits and ordering for readability
- The "Full Reference" document is now generated from a template for easier updating

0.3.0
=====

Added
-----

- This changelog
- Optional dependency zsh-defer__,
  for pre-caching help messages
- Option to control which functions are "exposed" as top-level in the shell
- ``zpy`` "supercommand" can run all zpy functions as subcommands,
  with great tab completion

__ https://github.com/romkatv/zsh-defer

Changed
-------

- The default ``pip-compile`` options gain ``--allow-unsafe``
- The help function, formerly ``zpy``, is now the subcommand ``zpy help``
- ``.zpy_mkbin`` is now ``zpy mkbin``
- Updated docs with new features and tips
