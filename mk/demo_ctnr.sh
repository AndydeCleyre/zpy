#!/bin/sh -e
zpy_branch=${1:-develop}
ctnr=zpy-alpine
user=dev

alias bldr="buildah run --user root $ctnr"
alias bldru="buildah run --user $user $ctnr"
alias bldcu="buildah copy --chown $user $ctnr"
alias bldfrom="buildah from --name $ctnr"
alias bldpress="buildah commit --rm $ctnr"

# Start with a daily build of alpine:3.11.x + git + Zsh + Zim + $user
today="$(date +%Y.%j)"
if ! bldfrom quay.io/andykluger/zim-alpine:$today; then
    bldfrom alpine:3.11
    bldr apk upgrade --no-progress -q

    # Regular user, with sudo power
    bldr apk add --no-progress -q sudo
    bldr adduser -G wheel -D -s /bin/zsh $user
    bldr sh -c 'echo "%wheel ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers.d/wheel_sudo'

    # git, Zsh, Zim
    bldr apk add --no-progress -q git zsh{,-vcs}
    bldcu https://raw.githubusercontent.com/zimfw/install/master/install.zsh /tmp/install-zim.zsh
    bldru zsh /tmp/install-zim.zsh
    bldr rm /tmp/install-zim.zsh
    bldru zsh -ic 'echo "zmodule gitster" >> ~/.zimrc; zimfw install'
    bldru zsh -ic 'sed -i "/steeef/d" ~/.zimrc; zimfw uninstall'
    bldru sh -c 'cat >> ~/.zshrc <<-EOF
        path=(~/.local/bin \$path)
        precmd () { rehash }
        export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE=fg=7
EOF'

    buildah config \
        --user $user \
        --workingdir /home/$user \
        --env TERM=xterm-256color \
        --cmd zsh \
        $ctnr

    buildah tag "$(bldpress quay.io/andykluger/zim-alpine)" \
                           "quay.io/andykluger/zim-alpine:$today"
    bldfrom quay.io/andykluger/zim-alpine:$today
fi

# zpy
bldr apk add --no-progress -q fzf highlight jq nano pcre-tools python3
bldru zsh -ic "echo 'zmodule andydecleyre/zpy -s python.zshrc -b $zpy_branch' >> .zimrc; zimfw install"
bldr ln -s /home/$user/.zim/modules/zpy/bin/vpy{,from} /usr/local/bin

bldr find /var/cache/apk -type f -delete

buildah config \
    --user $user \
    --workingdir /home/$user \
    --env TERM=xterm-256color \
    --cmd zsh \
    $ctnr

zpy_version="$(bldru git -C /home/$user/.zim/modules/zpy describe)"
buildah tag "$(bldpress quay.io/andykluger/zpy-alpine)" \
                       "quay.io/andykluger/zpy-alpine:$zpy_version" \
                       "quay.io/andykluger/zpy-alpine:$zpy_branch"
