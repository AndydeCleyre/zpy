#!/bin/sh -e
ctnr=zpy-alpine
user=dev

alias bldr="buildah run $ctnr"
alias bldru="buildah run --user $user $ctnr"

# start with a daily build of alpine:edge with zsh, prezto, micro, and a user
today=$(date +%Y.%j)
if ! buildah from --name $ctnr --pull=false prezto-alpine:$today; then
    buildah from --name $ctnr alpine:edge

    # enable testing repo
    bldr sh -c 'echo "http://dl-cdn.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories'
    bldr apk upgrade

    # non-root user, with sudo power
    bldr apk add sudo
    bldr adduser -G wheel -D $user
    bldr sh -c 'echo "%wheel ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers.d/wheel_sudo'
    bldr sed -Ei 's-(^'$user':.*:)(.*)-\1/bin/zsh-' /etc/passwd

    # practical zsh environment
    bldr apk add git micro zsh{,-vcs}
    bldru git clone --recursive https://github.com/sorin-ionescu/prezto /home/$user/.zprezto
    bldru zsh -c "for rcfile in /home/$user/.zprezto/runcoms/z*; ln -s \$rcfile /home/$user/.\${rcfile:t}"
    bldru sh -c 'echo "unalias ln ls" >> ~/.zshrc'
    bldru sh -c 'echo "export EDITOR=micro" >> ~/.zshrc'
    bldru sh -c 'echo "path=(~/.local/bin \$path)" >> ~/.zshrc'
    img="$(buildah commit $ctnr prezto-alpine)"
    buildah tag "$img" "prezto-alpine:latest" "prezto-alpine:$today"
fi

# zpy
bldr apk add bat fzf jq pcre-tools python3
bldru git clone https://github.com/andydecleyre/zpy /home/$user/zpy
bldru sh -c 'echo ". ~/zpy/python.zshrc" >> ~/.zshrc'
bldr ln -s /home/$user/zpy/bin/vpy{,from} /usr/local/bin

buildah config \
    --user $user \
    --workingdir /home/$user \
    --env TERM=xterm-256color \
    --cmd zsh \
    $ctnr
img="$(buildah commit $ctnr zpy-alpine)"
buildah tag "$img" \
    "zpy-alpine:latest" "zpy-alpine:$(git describe)" \
    "quay.io/andykluger/zpy-alpine:latest" "quay.io/andykluger/zpy-alpine:$(git describe)"
