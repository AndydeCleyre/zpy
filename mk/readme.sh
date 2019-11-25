#!/bin/sh
trap "cd $PWD" EXIT
cd "$(dirname "$0")"
./help.sh > help.txt
python3 -c "
from json import dumps
with open('vars_readme.json', 'w') as varsfile, open('help.txt', 'r') as helpfile:
    varsfile.write(dumps({'help': helpfile.read()}))
"
pyratemp_tool.py -f "vars_readme.json" "../README.rst.t" > "../README.rst"
