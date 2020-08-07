#!/bin/sh -ex
# [<base-distro>=fedora [<base-tag>]]

distro=${1:-fedora}

ctnr=zim-$distro
img=quay.io/andykluger/$ctnr
user=dev

alias ctnr_run="buildah run --user root $ctnr"
alias ctnr_urun="buildah run --user $user $ctnr"
case $distro in
  fedora)
    basetag=${2:-32}
    pkgs='git-core zsh'
    fat='/var/cache/* /var/log/* /usr/lib64/python3.8/__pycache__'
    alias ctnr_pkg="ctnr_run dnf -yq --setopt=install_weak_deps=False"
    alias ctnr_pkg_upgrade="ctnr_pkg distro-sync"
    alias ctnr_pkg_add="ctnr_pkg install"
    alias ctnr_mkuser="ctnr_run useradd -m -s /bin/zsh"
    alias ctnr_ufetch="ctnr_urun curl -s -L -o"
  ;;
  alpine)
    basetag=${2:-3.12}
    pkgs='git sudo zsh'
    fat='/var/cache/apk/*'
    alias ctnr_pkg="ctnr_run apk -q --no-progress"
    alias ctnr_pkg_upgrade="ctnr_pkg upgrade"
    alias ctnr_pkg_add="ctnr_pkg add"
    alias ctnr_mkuser="ctnr_run adduser -D -s /bin/zsh"
    alias ctnr_ufetch="ctnr_urun wget -q -O"
  ;;
  ubuntu)
    basetag=${2:-20.04}
    pkgs='ca-certificates git sudo wget zsh'
    fat='/var/cache/* /var/lib/apt/lists/*'
    alias ctnr_pkg="ctnr_run apt -yqq --no-install-recommends"
    alias ctnr_pkg_upgrade="ctnr_pkg update && ctnr_pkg full-upgrade"
    alias ctnr_pkg_add="ctnr_pkg install"
    alias ctnr_mkuser="ctnr_run useradd -m -s /bin/zsh"
    alias ctnr_ufetch="ctnr_urun wget -q -O"
  ;;
  *)
    printf '%s\n' \
      'Args: [<base-distro> [<base-tag>]]' \
      'Accepted distros:' \
      'fedora (default)' alpine ubuntu
    exit 1
  ;;
esac

# Start fresh
buildah rm $ctnr 2>/dev/null || true
buildah from -q --name $ctnr docker.io/library/$distro:$basetag

# Upgrade and install packages
ctnr_pkg_upgrade
ctnr_pkg_add $pkgs

# Add user with sudo powers
ctnr_mkuser $user
ctnr_run sh -c "printf '%s\n' \
	'$user ALL=(ALL) NOPASSWD: ALL' \
>> /etc/sudoers.d/${user}"

# Install zimfw files
ctnr_urun git clone -q --depth 1 https://github.com/zimfw/install /home/$user/zimfw_install
for zfile in zshenv zlogin zimrc zshrc; do
  ctnr_urun mv /home/$user/zimfw_install/src/templates/$zfile /home/$user/.$zfile
done
ctnr_urun rm -rf /home/$user/zimfw_install
ctnr_urun mkdir -p /home/$user/.zim
ctnr_ufetch /home/$user/.zim/zimfw.zsh https://github.com/zimfw/zimfw/releases/latest/download/zimfw.zsh

# Replace zsh-syntax-highlighting with fast-syntax-highlighting
ctnr_urun sed -i 's:zsh-users/zsh-syntax-highlighting:zdharma/fast-syntax-highlighting:g' /home/$user/.zimrc

# In Ubuntu 20.04, of the themes at https://github.com/zimfw/zimfw/wiki/Themes,
# steeef is the only one that doesn't bug out when completing with no matches.
# But it has big blank lines between prompts. gitster is good otherwise.
# Replace steeef prompt with agkozak/agkozak-zsh-prompt
ctnr_urun sed -i 's:steeef:agkozak/agkozak-zsh-prompt:g' /home/$user/.zimrc

# Prepend user bin dir to PATH; Always rehash; Make fish-y suggestions visible
ctnr_urun sh -c 'printf "%s\n" \
  "path=(~/.local/bin \$path)" \
  "precmd () { rehash }" \
  "ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE=fg=4" \
>> ~/.zshrc'

# Get zim to install its managed modules
ctnr_urun zsh -c 'source ~/.zim/zimfw.zsh install'

# Cut some fat
ctnr_run sh -c "rm -rf $fat"

# Set default user, working dir, TERM, and command
buildah config \
  --user $user \
  --workingdir /home/$user \
  --env TERM=xterm-256color \
  --cmd zsh \
  $ctnr

# Press container as an image, tagged with today's date
buildah tag "$(buildah commit --quiet --rm $ctnr $img)" "$img:$(date +%Y.%j)"
