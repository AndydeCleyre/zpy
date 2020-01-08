#!/bin/sh -e
ctnr=zpy-alpine
user=dev

alias bldr="buildah run $ctnr"
alias bldru="buildah run --user $user $ctnr"
alias bldcu="buildah copy --chown $user $ctnr"
alias bldfrom="buildah from --name $ctnr"
alias bldpress="buildah commit --rm $ctnr"

# Start with a daily build of alpine:3.11.x + git + Zsh + Zim + $user
today="$(date +%Y.%j)"
if ! bldfrom --pull=false localhost/zim-alpine:$today; then
    bldfrom alpine:3.11
    bldr apk upgrade

    # Regular user, with sudo power
    bldr apk add sudo
    bldr adduser -G wheel -D $user
    bldr sh -c 'echo "%wheel ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers.d/wheel_sudo'

    # git, Zsh, Zim
    bldr apk add git zsh{,-vcs}
    bldcu https://raw.githubusercontent.com/zimfw/install/master/install.zsh /tmp/install-zim.zsh
    bldru zsh /tmp/install-zim.zsh
    bldr rm /tmp/install-zim.zsh
    bldru zsh -ic 'echo "zmodule gitster" >> ~/.zimrc; zimfw install'
    bldru sed -Ei 's/.*steeef.*//g' /home/$user/.zimrc
    bldru zsh -ic 'zimfw uninstall'

    buildah tag "$(bldpress localhost/zim-alpine)" \
        "localhost/zim-alpine:latest" \
        "localhost/zim-alpine:$today"
    bldfrom localhost/zim-alpine:$today
fi

# zpy
bldr apk add fzf highlight jq nano pcre-tools python3
bldru git clone --branch develop https://github.com/andydecleyre/zpy /home/$user/zpy
bldru sh -c 'cat >> ~/.zshrc <<EOF
    path=(~/.local/bin \$path)
    precmd () { rehash }
    export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE=fg=7
    . ~/zpy/python.zshrc
EOF'
bldr ln -s /home/$user/zpy/bin/vpy{,from} /usr/local/bin

bldr find /var/cache/apk -type f -delete

buildah config \
    --user $user \
    --workingdir /home/$user \
    --env TERM=xterm-256color \
    --cmd zsh \
    $ctnr

zpy_version="$(bldru git -C /home/$user/zpy describe)"
buildah tag "$(bldpress localhost/zpy-alpine)" \
    "localhost/zpy-alpine:latest" \
    "localhost/zpy-alpine:$zpy_version" \
    "quay.io/andykluger/zpy-alpine:latest" \
    "quay.io/andykluger/zpy-alpine:$zpy_version"
