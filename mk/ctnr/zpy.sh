#!/bin/sh -e
# --local|<branch> [fedora|alpine|ubuntu=fedora]

# Set branch and distro
zpy_branch=$1
if [ ! "$zpy_branch" ] || [ "$zpy_branch" = -h ] || [ "$zpy_branch" = --help ]; then
  printf '%s\n' 'Args: --local|<branch> [fedora|alpine|ubuntu=fedora]'
  exit 1
fi
shift
distro=${1:-fedora}

ctnr=zpy-$distro
img=quay.io/andykluger/$ctnr
user=dev

base_img=quay.io/andykluger/zcomet-$distro
today="$(date +%Y.%j)"
gitroot="$(git -C "$(dirname "$0")" rev-parse --show-toplevel)"

ctnr_run () {  # [-u] <cmd> [<cmd-arg>...]
  _u=root
  if [ "$1" = -u ]; then _u=$user; shift; fi
  buildah run --user $_u "$ctnr" "$@"
}

ctnr_append () {  # [-u] <dest-path>
  unset _u
  if [ "$1" = -u ]; then _u=-u; shift; fi
  ctnr_run $_u sh -c "cat >>$1"
}

pkgs='fzf python3'            # minimal, common
pkgs="$pkgs highlight micro"  # recommended, common
fat="/home/${user}/.zcomet/repos/*/*/.git /usr/lib*/python3.*/__pycache__"
case $distro in
  fedora)
    pkgs="$pkgs diffutils pcre-tools"  # minimal
    pkgs="$pkgs gcc python3-devel"     # numpy, pandas, etc.
    fat="$fat /var/cache/* /var/log/*"
    alias ctnr_pkg="ctnr_run dnf -yq --setopt=install_weak_deps=False"
    alias ctnr_pkg_upgrade="ctnr_pkg distro-sync"
    alias ctnr_pkg_add="ctnr_pkg install"
  ;;
  alpine)
    pkgs="$pkgs pcre2-tools"               # minimal
    pkgs="$pkgs gcc python3-dev musl-dev"  # numpy, pandas, etc.
    fat="$fat /var/cache/apk/*"
    alias ctnr_pkg="ctnr_run apk -q --no-progress"
    alias ctnr_pkg_upgrade="ctnr_pkg upgrade"
    alias ctnr_pkg_add="ctnr_pkg add"
  ;;
  ubuntu)
    pkgs="$pkgs pcre2-utils python3-venv"  # minimal
    fat="$fat /var/cache/* /var/lib/apt/lists/*"
    alias ctnr_pkg="ctnr_run apt -yqq --no-install-recommends"
    alias ctnr_pkg_upgrade="ctnr_pkg update && ctnr_pkg full-upgrade"
    alias ctnr_pkg_add="ctnr_pkg install"
  ;;
  *)
    printf '%s\n' 'Args: --local|<branch> [fedora|alpine|ubuntu=fedora]'
    exit 1
  ;;
esac

# Start fresh
buildah rm "$ctnr" 2>/dev/null || true
if ! buildah from -q --name "$ctnr" "$base_img:$today" 2>/dev/null; then
  "${gitroot}/mk/ctnr/zcomet.sh" "$distro"
  buildah from -q --name "$ctnr" "$base_img:$today"
fi

# Upgrade and install packages
ctnr_pkg_upgrade
# shellcheck disable=SC2086
ctnr_pkg_add $pkgs

# Set variables
<<EOF ctnr_append -u /home/${user}/.zshenv
export EDITOR='micro'
export HIGHLIGHT_OPTIONS='-O truecolor -s ekvoli -t 4 --force --stdout'
export LESS='ij.3JRWX'
EOF

# Install zpy
if [ "$zpy_branch" = --local ]; then
  zpy_branch="$(
    read -r host </etc/hostname || true;
    printf '%s-local-working' "$host"
  )"
  zpy_version="$(git -C "$gitroot" describe --dirty)"
  buildah copy --chown "$user" "$ctnr" "${gitroot}/zpy.plugin.zsh" /home/${user}/
  printf '%s\n' '. ~/zpy.plugin.zsh' \
  | ctnr_append -u /home/${user}/.zshrc
else
  ctnr_run -u sed -Ei \
    "s:^(zcomet compinit( .*)?)$:zcomet load andydecleyre/zpy@${zpy_branch}\n\1:" \
    /home/${user}/.zshrc
  ctnr_run -u zsh -ic exit
  zpy_version="$(ctnr_run -u git -C /home/${user}/.zcomet/repos/andydecleyre/zpy describe --dirty)"
fi
printf 'zpy_branch: %s\n' "$zpy_branch"
printf 'zpy_version: %s\n' "$zpy_version"

# Install standalone vpy script, for simpler shebangs
ctnr_run -u mkdir -p /home/${user}/.local/bin
ctnr_run -u zsh -ic '.zpy_mkbin vpy ~/.local/bin/vpy'

# Set aliases
<<EOF ctnr_append -u /home/${user}/.zshrc
alias e="\$EDITOR"
alias h="highlight"

EOF

# Print aliases
<<EOF ctnr_append -u /home/${user}/.zshrc
print -rl '' '# Aliases:' | .zpy_hlt zsh
grep '^alias ' \$HOME/.zshrc | .zpy_hlt zsh
EOF

# Inform user about Py2 support
case $distro in
  fedora)
    <<EOF ctnr_append -u /home/${user}/.zshrc
print -rl '# For python2 support:' \\
  'sudo dnf --setopt=install_weak_deps=False install python2 python3-virtualenv' \\
| .zpy_hlt zsh
EOF
  ;;
  alpine)
    <<EOF ctnr_append -u /home/${user}/.zshrc
print -rl '# For python2 support:' \\
  'sudo apk add python2' \\
  'sudo python2 -m ensurepip' \\
  'sudo pip2 install virtualenv' \\
| .zpy_hlt zsh
EOF
  ;;
  ubuntu)
    <<EOF ctnr_append -u /home/${user}/.zshrc
print -rl '# For python2 support:' \\
  'sudo apt --no-install-recommends install python2 virtualenv' \\
| .zpy_hlt zsh
EOF
  ;;
esac

# Remind user of a few useful commands
<<EOF ctnr_append -u /home/${user}/.zshrc
print -l
zpy zpy envin pipacs pipz
EOF

# Cut some fat
ctnr_run sh -c "rm -rf $fat"

# Press container as an image, tagged with zpy version and branch
buildah tag "$(buildah commit --quiet --rm "$ctnr" "$img")" "$img:$zpy_version" "$img:$zpy_branch"
