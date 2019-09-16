#!/bin/sh
folder="$(dirname "$0")"
"$folder/mkhelp.sh" > help.sh
python3 -c "
from json import dumps
with open('$folder/vars.json', 'w') as varsfile, open('$folder/help.sh', 'r') as helpfile:
    varsfile.write(dumps({'help': helpfile.read()}))
"
pyratemp_tool.py -f "$folder/vars.json" "$folder/README.rst.t" > "$folder/README.rst"
