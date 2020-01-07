#!/bin/sh -e
trap "cd $PWD" EXIT
cd "$(dirname "$0")"

pip install -qr ../docs/doc-requirements.txt

./help.sh

pyratemp_tool.py \
    -f "vars_readme.json" \
    -d include_toc= \
    "../README.rst.t" \
> "../docs/index.rst"

rm -rf ../docs/site
sphinx-build ../docs ../docs/site
