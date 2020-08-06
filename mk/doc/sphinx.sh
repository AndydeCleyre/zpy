#!/bin/sh -e
gitroot="$(git -C "$(dirname "$0")" rev-parse --show-toplevel)"

[ $VIRTUAL_ENV ] \
|| printf '%s\n' \
  'You may want to activate a venv first in order to install and use the build tools.' \
  'Trying anyway . . .'
pip install -qr "${gitroot}/doc/sphinx/requirements.txt"

rm -f "${gitroot}/build/vars.json"
"${gitroot}/mk/var/help.zsh"

pyratemp_tool.py \
  -f "${gitroot}/build/vars.json" \
  -d include_toc= \
  "${gitroot}/README.rst.t" \
> "${gitroot}/doc/sphinx/index.rst"

rm -rf "${gitroot}/build/sphinx"
sphinx-build "${gitroot}/doc/sphinx" "${gitroot}/build/sphinx"
