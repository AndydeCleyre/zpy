#!/bin/sh
trap "cd $PWD" EXIT
cd "$(dirname "$0")"

./help.sh

pyratemp_tool.py \
    -f "vars_readme.json" \
    "../README.rst.t" \
> "../README.rst"
