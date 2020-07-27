#!/bin/zsh -fe

gitroot="$(git -C "$(dirname "$0")" rev-parse --show-toplevel)"
buildroot="${gitroot}/build"
mkdir -p "$buildroot"

. "${gitroot}/zpy.plugin.zsh" || true
.zpy > "${buildroot}/help.txt"

python3 -c "
from json import loads, dumps


try:
    data = loads(open('''${buildroot}/vars.json''').read())
except FileNotFoundError:
    data = {}

with open('''${buildroot}/help.txt''') as helpfile:
    data.update({'help': helpfile.read()})

with open('''${buildroot}/vars.json''', 'w') as varsfile:
    varsfile.write(dumps(data))
"

rm "${buildroot}/help.txt"
