#!/bin/sh -e
gitroot="$(git -C "$(dirname "$0")" rev-parse --show-toplevel)"

[ $VIRTUAL_ENV ] \
    || echo -e "You may want to activate a venv first in order to install and use the build tools.\nTrying anyway . . ."
pip install -qr "${gitroot}/doc/doc-requirements.txt"

./help.zsh

pyratemp_tool.py \
    -f "${gitroot}/build/vars.json" \
    -d include_toc= \
    "${gitroot}/README.rst.t" \
> "${gitroot}/doc/index.rst"

rm -rf "${gitroot}/doc/site"
sphinx-build "${gitroot}/doc" "${gitroot}/doc/site"
