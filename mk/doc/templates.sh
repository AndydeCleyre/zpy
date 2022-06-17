#!/bin/sh -e
gitroot="$(git -C "$(dirname "$0")" rev-parse --show-toplevel)"
templates="${gitroot}/doc/templates"
cd "$templates"

if [ ! -d venv ]; then
  python3 -m venv venv
fi
# shellcheck disable=SC1091
. ./venv/bin/activate

pip install -qr requirements.txt

for wz in *.wz; do
  md="$(printf '%s\n' "$wz" | sed -E 's/\.wz$//')"
  PYTHONPATH="$templates" wheezy.template "$wz" '{}' >"../src/${md}"
done
