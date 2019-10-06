#!/bin/sh
grep -P \
    '(^#[^!])|(^(alias|local))|(^$)|(^\S+ \(\) {(.*})?(  # .+)?$)' \
    "${1:-$(dirname "$0")/python.zshrc}" | \
    uniq | \
    sed -E 's/(local )?(.+) \(\) \{([^\}]*\})?(.*)/\2\4/g' | \
    sed -E 's/^alias ([^=]+).+(  # .+)/\1\2/g'

# select leading comments, aliases & function openers, and empty lines
# squeeze repeats (newlines)
# drop any function content other than name and comment
# drop any commented alias content other than name and comment
