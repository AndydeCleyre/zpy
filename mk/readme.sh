#!/bin/sh -e
trap "cd $PWD" EXIT
cd "$(dirname "$0")"

pip install -qr ../docs/doc-requirements.txt

./help.sh

pyratemp_tool.py \
    -f "vars_readme.json" \
    "../README.rst.t" \
> "../README.rst"
