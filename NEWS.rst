====
News
====

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
