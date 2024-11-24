====
News
====

Unreleased
==========

Changed
-------

- Use reverse-list layout for fzf/skim instead of reverse
- pypc: don't add '.' to any dependency list
- Add optional syntax highlighter backend: gat
- Ensure to use ``python3`` instead of ``python`` for out-of-venv internal uses

0.3.11
======

Changed
-------

- Use uv for pipcheckold instead of installing pip (requires uv >=0.5.0)
- Replace Zsh-text-parsing fallbacks with Python-json-parsing (slower but more reliable)
- Remove jello for JSON handling, as it's slower than the Python fallbacks
- Auto create a temporary venv for pypc's tomlkit needs
- Add diffr as optional diff-highlighter
- Show pypc's pyproject.toml diff BEFORE asking to replace it
- Remove useless double-zsh-invocation during fzf/skim preview
- Exclude wheel from pipcheckold listings
- Use new wheezy.template feature (``__args__``) to reduce shell-manipulation of JSON
  - If using the wheezy.template JSON-reading backend, upgrade it (``pipz upgrade wheezy.template``)!

0.3.10
======

Changed
-------

- More caching on the doc site (and no longer connect user to Google Fonts)
- Increase uniformity between uv and pip-tools alternative backends
- Silence some new noise from uv during ``pipz list``

0.3.9
=====

Changed
-------

- vpy and vpyshebang now resolve any symlinks in the script path
  before determining the projdir and venv path.
- ``sk`` (skim) may now be used instead of ``fzf``

0.3.8
=====

Changed
-------

- Add alternative documentation parsing backend: ugrep
- Small improvements to docs and error messages
- Updated Alpine demo container base image
- Use localtraps option everywhere we TRAP
- Document zsh-autoenv and direnv zpy-friendly configuration
- Increase uniformity of behavior between uv pip sync and pip-sync

0.3.7
=====

Changed
-------

- Strictly require activated venvs for some operations
- Reduce double-warnings about non-activated venvs
- Make all completion function return codes accurate,
  complying with the shell's internal expectations
- Don't append lines which are already present (pipa, pipac, pipacs)
- Use zsh/mapfile to avoid six more subshells
- Make some docs and logging clearer

0.3.6
=====

Changed
-------

- Use uv completion rather than pip or pip-compile completion
  when uv is installed, affecting:
  ``pipc``, ``pipcs``, ``pipacs``, ``pipac``, and ``pipi``
  -- currently a bit limited by astral-sh/uv#3249
- Document installation of uv completion
- Restore ``highlight`` to top detected syntax highlighter,
  since confirming Linux Mint renamed their ``highlight`` to ``highlight-mint``
- Re-add ``highlight`` to the demo container images
- Double ``ZPY_PROCS``, considering how zargs batches processes, and how fast ``uv`` is
- Remove some irrelevant flags when using uv,
  avoiding some warnings
- Bump Fedora demo container to 40
- Spruce up README, though GitHub rendering is partially broken -- https://github.com/github/markup/issues/1798

0.3.5
=====

Changed
-------

- Stop passing --resolver=backtracking
  -- It's been pip-tools' default for while already,
  and it's irrelevant to uv
- Update container build scripts:
    - use newer base images
    - install uv and rich-cli
    - don't bother installing highlight and corresponding alias

Fixed
-----

- Fix pipz animation link in readme

0.3.4
=====

Fixed
-----

- Documentation/readthedocs fixes

0.3.3
=====

Changed
-------

- Use uv, if present, rather than pip or pip-tools (tip: `pipz install uv`)
- Some documentation updates, mostly reflecting the new optional uv backend
- Require some actions to have an activated venv first
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
