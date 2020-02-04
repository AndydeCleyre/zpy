#!/bin/sh -e
trap "cd $PWD" EXIT
cd "$(dirname "$0")"

[[ $VIRTUAL_ENV ]] \
    || echo -e "You may want to activate a venv first in order to install and use the build tools.\nTrying anyway . . ."
pip install -qr ../doc/doc-requirements.txt

./help.sh

pyratemp_tool.py \
    -f "vars_readme.json" \
    -d include_toc= \
    "../README.rst.t" \
> "../doc/index.rst"

rm -rf ../doc/site
sphinx-build ../doc ../doc/site
