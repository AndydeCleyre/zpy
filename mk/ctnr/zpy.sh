#!/bin/sh -e
# --local|<branch> [<base-distro>=fedora]

zpy_branch=$1
shift
if [ ! $zpy_branch ] || [ $zpy_branch = -h ] || [ $zpy_branch = --help ]; then
  printf '%s\n' \
    'Args: --local|<branch> [<base-distro>]' \
    'Accepted distros:' \
    'fedora (default)' alpine ubuntu
  exit 1
fi
distro=${1:-fedora}

ctnr=zpy-$distro
img=quay.io/andykluger/$ctnr
user=dev

base_img=quay.io/andykluger/zim-$distro
today="$(date +%Y.%j)"
gitroot="$(git -C "$(dirname "$0")" rev-parse --show-toplevel)"

alias ctnr_run="buildah run --user root $ctnr"
alias ctnr_urun="buildah run --user $user $ctnr"
case $distro in
  fedora)
    pkgs='diffutils fzf highlight micro pcre-tools python3'
    fat='/var/cache/* /var/log/* /usr/lib64/python3.8/__pycache__'
    alias ctnr_pkg="ctnr_run dnf -yq --setopt=install_weak_deps=False"
    alias ctnr_pkg_upgrade="ctnr_pkg distro-sync"
    alias ctnr_pkg_add="ctnr_pkg install"
  ;;
  alpine)
    pkgs='fzf highlight pcre2-tools python3'
    micro_version="2.0.6"
    fat='/var/cache/apk/*'
    alias ctnr_pkg="ctnr_run apk -q --no-progress"
    alias ctnr_pkg_upgrade="ctnr_pkg upgrade"
    alias ctnr_pkg_add="ctnr_pkg add"
  ;;
  ubuntu)
    pkgs='fzf highlight micro pcre2-utils python3 python3-venv'
    fat='/var/cache/* /var/lib/apt/lists/*'
    alias ctnr_pkg="ctnr_run apt -yqq --no-install-recommends"
    alias ctnr_pkg_upgrade="ctnr_pkg update && ctnr_pkg full-upgrade"
    alias ctnr_pkg_add="ctnr_pkg install"
  ;;
  *)
    printf '%s\n' \
      'Args: --local|<branch> [<base-distro>]' \
      'Accepted distros:' \
      'fedora (default)' alpine ubuntu
    exit 1
  ;;
esac

# Start fresh
buildah rm $ctnr 2>/dev/null || true
if ! buildah from -q --name $ctnr "$base_img:$today" 2>/dev/null; then
  "${gitroot}/mk/ctnr/zim.sh" $distro
  buildah from -q --name $ctnr "$base_img:$today"
fi

# Upgrade and install packages
ctnr_pkg_upgrade
ctnr_pkg_add $pkgs

# Set EDITOR and convenient alias
ctnr_urun sh -c 'printf "%s=micro\n" \
  EDITOR "alias e" \
>> ~/.zshrc'

# Install zpy
if [ "$zpy_branch" = --local ]; then
  zpy_branch="$(
    read -r host </etc/hostname || true;
    printf '%s-local-working' "$host"
  )"
  zpy_version="$(git -C "$gitroot" describe --dirty)"
  buildah copy --chown $user $ctnr "${gitroot}/zpy.plugin.zsh" /home/$user/
  ctnr_urun sh -c 'printf "%s\n" \
    ". ~/zpy.plugin.zsh" \
  >> ~/.zshrc'
else
  ctnr_urun zsh -ic "print -l \
    'zmodule andydecleyre/zpy -b $zpy_branch' \
  >> ~/.zimrc; zimfw install"
  zpy_version="$(ctnr_urun git -C /home/$user/.zim/modules/zpy describe --dirty)"
fi
printf 'zpy_branch: %s\n' "$zpy_branch"
printf 'zpy_version: %s\n' "$zpy_version"

# Install standalone vpy script, for simpler shebangs
ctnr_urun mkdir -p /home/$user/.local/bin
ctnr_urun zsh -ic '.zpy_mkbin vpy ~/.local/bin/vpy'

# Inform user about potential PyPI package build deps, Py2 support, EDITOR
case $distro in
  fedora)
    ctnr_urun sh -c 'printf "print %s\n" \
      "-P \"%F{blue}# For python2 support:%f\"" \
      "sudo dnf --setopt=install_weak_deps=False install python2 python3-virtualenv" \
      "-P \"%F{blue}# For pip to successfully install some packages like numpy, pandas:%f\"" \
      "sudo dnf --setopt=install_weak_deps=False install gcc python3-devel" \
      "-P \"%F{blue}# micro editor is installed, and aliased as e%f\"" \
    >> ~/.zshrc'
  ;;
  alpine)
    ctnr_run sh -c "wget -O - \
      https://github.com/zyedidia/micro/releases/download/v${micro_version}/micro-${micro_version}-linux64-static.tar.gz \
      | tar x -z -O -f - micro-${micro_version}/micro \
    > /usr/local/bin/micro; chmod +x /usr/local/bin/micro"
    ctnr_urun sh -c 'printf "print %s\n" \
      "-P \"%F{blue}# For python2 support:%f\"" \
      "sudo apk add python2" \
      "sudo python2 -m ensurepip" \
      "sudo pip2 install virtualenv" \
      "-P \"%F{blue}# For pip to successfully install some packages like numpy, pandas:%f\"" \
      "sudo apk add gcc {python3,musl}-dev" \
      "-P \"%F{blue}# For pillow, additionally:%f\"" \
      "sudo apk add {jpeg,zlib}-dev" \
      "-P \"%F{blue}# micro editor is installed, and aliased as e%f\"" \
    >> ~/.zshrc'
  ;;
  ubuntu)
    ctnr_urun sh -c 'printf "print %s\n" \
      "-P \"%F{blue}# For python2 support:%f\"" \
      "sudo apt --no-install-recommends install python2 virtualenv" \
      "-P \"%F{blue}# micro editor is installed, and aliased as e%f\"" \
    >> ~/.zshrc'
  ;;
esac

# Remind user of a few useful commands
ctnr_urun sh -c 'printf "%s\n" \
  "zpy zpy envin pipacs pipz" \
>> ~/.zshrc'

# Cut some fat
ctnr_run sh -c "rm -rf $fat"

# Press container as an image, tagged with zpy version and branch
buildah tag "$(buildah commit --quiet --rm $ctnr $img)" "$img:$zpy_version" "$img:$zpy_branch"
