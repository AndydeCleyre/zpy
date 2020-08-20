#!/bin/sh -e
gitroot="$(git -C "$(dirname "$0")" rev-parse --show-toplevel)"

"${gitroot}/mk/doc/sphinx.sh"

rm -rf "${gitroot}/docs"
cp -r "${gitroot}/build/sphinx" "${gitroot}/docs"

touch "${gitroot}/docs/.nojekyll"

rm -r "${gitroot}/build/sphinx"
