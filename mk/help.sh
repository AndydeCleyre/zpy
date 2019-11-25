#!/bin/sh
pcregrep '^(alias|([^ \n]+ \(\))|#|$)' "${1:-$(dirname "$0")/../python.zshrc}" \
| uniq \
| sed -E 's/(^[^ ]+) \(\) \{(.*\})?(.*)/\1\3/g' \
| sed -E 's/^alias ([^=]+)[^#]+(# .+)?/\1  \2/g'
# select leading comments, aliases & function openers, and empty lines
# squeeze repeats (newlines)
# drop any function content other than name and comment
# drop any commented alias content other than name and comment