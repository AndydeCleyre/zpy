#!/bin/sh -e
trap "cd $PWD" EXIT
cd "$(dirname "$0")"

pcregrep \
    '^(alias|([^ \n]+ \(\))|#|$)' "${1:-../python.zshrc}"  `# select leading comments, aliases, function openers, and empty lines`\
    | uniq                                                 `# squeeze repeats (blank lines)`\
    | sed -E 's/(^[^ ]+) \(\) \{(.*\})?(.*)/\1\3/g'        `# drop any function content other than name and comment`\
    | sed -E 's/^alias ([^=]+)[^#]+(# .+)?/\1  \2/g'       `# drop any alias content other than name and comment`\
    | sed 's/  # / /g'                                     `# strip out '  #' separators`\
> help.txt

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
