#!/bin/sh -e
trap "cd $PWD" EXIT
cd "$(dirname "$0")"

pcregrep \
    '^(alias|([^ \n]+ \(\))|#|$)' "${1:-$(dirname "$0")/../python.zshrc}" \
    | uniq \
    | sed -E 's/(^[^ ]+) \(\) \{(.*\})?(.*)/\1\3/g' \
    | sed -E 's/^alias ([^=]+)[^#]+(# .+)?/\1  \2/g' \
    | sed 's/  # / /g' \
> help.txt
# select leading comments, aliases & function openers, and empty lines
# squeeze repeats (newlines)
# drop any function content other than name and comment
# drop any commented alias content other than name and comment
# strip out '  #' separators

python3 -c "
from json import loads, dumps

try: data = loads(open('vars_readme.json').read())
except FileNotFoundError: data = {}

with open('help.txt') as helpfile:
    data.update({'help': helpfile.read()})

with open('vars_readme.json', 'w') as varsfile:
    varsfile.write(dumps(data))
"

rm help.txt
