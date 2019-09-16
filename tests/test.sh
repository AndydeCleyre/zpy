#!/bin/sh -e

username="zpyuser"
ctnr=`buildah from alpine:edge`
alias bldr="buildah run $ctnr --"
alias bldru="buildah run -t --user $username $ctnr --"

# copy app into container:
app="$(dirname "$(dirname "$(realpath "$0")")")"
bldr adduser -D $username
buildah add --chown $username:$username $ctnr "$app" /home/$username

# upgrade packages; install dependencies:
bldr apk upgrade
bldr apk add zsh python3

bldru /home/$username/tests/test.zsh
