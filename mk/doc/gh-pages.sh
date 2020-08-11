#!/bin/sh -e
gitroot="$(git -C "$(dirname "$0")" rev-parse --show-toplevel)"

"${gitroot}/mk/doc/m.css.sh"

rm -rf "${gitroot}/docs"
cp -r "${gitroot}/build/m.css" "${gitroot}/docs"

rm -r "${gitroot}/build/m.css"
