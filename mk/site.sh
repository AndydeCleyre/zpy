#!/bin/sh
trap "cd $PWD" EXIT
cd "$(dirname "$0")"

./help.sh

pyratemp_tool.py \
    -f "vars_readme.json" \
    -d include_toc= \
    "../README.rst.t" \
> "../docs/index.rst"

# cd ../docs
# make html
