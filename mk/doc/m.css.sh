#!/bin/sh -e
gitroot="$(git -C "$(dirname "$0")" rev-parse --show-toplevel)"

[ $VIRTUAL_ENV ] \
|| printf '%s\n' \
  'You may want to activate a venv first in order to install and use the build tools.' \
  'Trying anyway . . .'
pip install -qr "${gitroot}/doc/m.css/requirements.txt"
git -C "${gitroot}" submodule update --init --recursive

"${gitroot}/mk/doc/readme.sh"
cp "${gitroot}/README.rst" "${gitroot}/build/index.rst"

rm -rf "${gitroot}/build/m.css"
"${gitroot}/doc/m.css/m.css/documentation/python.py" "${gitroot}/doc/m.css/conf.py"

rm \
	"${gitroot}/build/index.rst" \
	"${gitroot}/build/m.css/classes.html" \
	"${gitroot}/build/m.css/modules.html" \
	"${gitroot}/build/m.css/pages.html"
