#!/bin/sh -e
trap "cd $PWD" EXIT
cd "$(dirname "$0")"

pip install -qr ../doc/doc-requirements.txt

./help.sh

pyratemp_tool.py \
    -f "vars_readme.json" \
    -d include_toc= \
    "../README.rst.t" \
> "../doc/index.rst"

rm -rf ../doc/site
sphinx-build ../doc ../doc/site
