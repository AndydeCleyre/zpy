#!/bin/sh -e
# [fedora|alpine|ubuntu=fedora [<base-tag>]]

distro=${1:-fedora}

ctnr=zcomet-$distro
img=quay.io/andykluger/$ctnr
user=dev

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

pkgs=zsh  # ca-certificates git less sudo wget
fat="/home/${user}/.zcomet/repos/*/*/.git"
case $distro in
  fedora)
    basetag=${2:-36}
    pkgs="$pkgs git-core"
    fat="$fat /var/cache/* /var/log/* /usr/lib*/python3.*/__pycache__"
    alias ctnr_pkg="ctnr_run dnf -yq --setopt=install_weak_deps=False"
    alias ctnr_pkg_upgrade="ctnr_pkg distro-sync"
    alias ctnr_pkg_add="ctnr_pkg install"
    alias ctnr_mkuser="ctnr_run useradd -m -s /bin/zsh"
  ;;
  alpine)
    basetag=${2:-3.15}
    pkgs="$pkgs git sudo"
    fat="$fat /var/cache/apk/*"
    alias ctnr_pkg="ctnr_run apk -q --no-progress"
    alias ctnr_pkg_upgrade="ctnr_pkg upgrade"
    alias ctnr_pkg_add="ctnr_pkg add"
    alias ctnr_mkuser="ctnr_run adduser -D -s /bin/zsh"
  ;;
  ubuntu)
    basetag=${2:-22.04}
    pkgs="$pkgs ca-certificates less git sudo wget"
    fat="$fat /var/cache/* /var/lib/apt/lists/*"
    alias ctnr_pkg="ctnr_run apt -yqq --no-install-recommends"
    alias ctnr_pkg_upgrade="ctnr_pkg update && ctnr_pkg full-upgrade"
    alias ctnr_pkg_add="ctnr_pkg install"
    alias ctnr_mkuser="ctnr_run useradd -m -s /bin/zsh"
  ;;
  *)
    printf '%s\n' 'Args: [fedora|alpine|ubuntu=fedora [<base-tag>]]'
    exit 1
  ;;
esac

# Start fresh
buildah rm "$ctnr" 2>/dev/null || true
buildah from -q --name "$ctnr" "docker.io/library/$distro:$basetag"

# Configure package manager
case $distro in
  fedora)
    printf '%s\n' 'fastestmirror=1' 'max_parallel_downloads=10' \
    | ctnr_append /etc/dnf/dnf.conf
  ;;
  *)
    # sometimes defaults are faster than taking time to find the fastest mirror
    printf '%s\n' "Using default repos for $distro"
  ;;
esac

# Upgrade and install packages
ctnr_pkg_upgrade
# shellcheck disable=SC2086
ctnr_pkg_add $pkgs

# Add user with sudo powers
ctnr_mkuser $user
printf '%s\n' "$user ALL=(ALL) NOPASSWD: ALL" \
| ctnr_append /etc/sudoers.d/$user

# Install zcomet
ctnr_run -u git clone -q --depth 1 https://github.com/agkozak/zcomet /home/$user/.zcomet/bin

# Add settings and plugins to .zshrc:
ctnr_run -u rm -f /home/$user/.zshrc
<<EOF ctnr_append -u /home/$user/.zshrc
typeset -U path=(~/.local/bin \$path)
precmd () { rehash }
zstyle ':completion:*:*:*:*:*' menu select

# Plugins:
. ~/.zcomet/bin/zcomet.zsh
() {
  local plugin
  for plugin (
    agkozak/agkozak-zsh-prompt
    zdharma-continuum/fast-syntax-highlighting
    zimfw/environment
    zimfw/input
    zsh-users/zsh-completions
  ) zcomet load \$plugin
}
zcomet compinit

# Shell vars:
AGKOZAK_BLANK_LINES=1
AGKOZAK_LEFT_PROMPT_ONLY=1
AGKOZAK_PROMPT_DIRTRIM=4
AGKOZAK_PROMPT_DIRTRIM_STRING=…
WORDCHARS=\${WORDCHARS//[\/]}

# History:
setopt HIST_IGNORE_ALL_DUPS
autoload -Uz history-search-end
zle -N history-beginning-search-backward-end history-search-end
zle -N history-beginning-search-forward-end  history-search-end
bindkey '^[[A' history-beginning-search-backward-end
bindkey '^[[B' history-beginning-search-forward-end
if [[ \${terminfo[kcuu1]} && \${terminfo[kcud1]} ]] {
  bindkey \${terminfo[kcuu1]} history-beginning-search-backward-end
  bindkey \${terminfo[kcud1]} history-beginning-search-forward-end
}

EOF

# Fetch plugins
ctnr_run -u zsh -ic exit

# Cut some fat
ctnr_run sh -c "rm -rf $fat"

# Set default user, working dir, TERM, and command
buildah config \
  --user $user \
  --workingdir /home/$user \
  --env TERM=xterm-256color \
  --cmd zsh \
  "$ctnr"

# Press container as an image, tagged with today's date
buildah tag "$(buildah commit -q --rm "$ctnr" "$img")" "$img:$(date +%Y.%j)"
