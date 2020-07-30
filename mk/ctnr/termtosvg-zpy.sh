#!/bin/sh -ex
# [<distro>=fedora [<zpyctnr-tag>=<host>-local-working]]

distro=${1:-fedora}
read -r host </etc/hostname || true
tag_default="${host}-local-working"
case $distro in
    fedora) ;;
    alpine) ;;
    ubuntu) ;;
    *)
        printf '%s\n' \
            'Args: [<distro> [<zpyctnr-tag>]]' \
            'Accepted distros:' \
            'fedora (default)' 'alpine (slow build)' ubuntu \
            "zpyctnr tag default: $tag_default"
        exit 1
    ;;
esac
tag=${2:-$tag_default}
if [ $tag = --local ]; then
    tag=$tag_default
fi

ctnr=termtosvg-zpy-$distro
img=quay.io/andykluger/$ctnr
user=dev

gitroot="$(git -C "$(dirname "$0")" rev-parse --show-toplevel)"

alias ctnr_run="buildah run --user root $ctnr"
alias ctnr_urun="buildah run --user $user $ctnr"

buildah rm $ctnr 2>/dev/null || true
if ! buildah from -q --name $ctnr quay.io/andykluger/zpy-$distro:$tag; then
    if [ $tag = $tag_default ]; then
        "${gitroot}/mk/ctnr/zpy.sh" --local $distro
    else
        "${gitroot}/mk/ctnr/zpy.sh" $tag $distro
    fi
    buildah from -q --name $ctnr quay.io/andykluger/zpy-$distro:$tag
fi

if [ $distro = alpine ]; then
    ctnr_run apk upgrade
    ctnr_run apk add gcc libxml2-dev libxslt-dev musl-dev python3-dev
fi
ctnr_urun sed -Ei '/^(print|zpy) /d' /home/$user/.zshrc
ctnr_urun zsh -ic 'pipz install termtosvg; .zpy_pypi_pkgs'
ctnr_urun sh -c 'printf "%s\n" \
    "#!/bin/zsh" \
    "print You can override the recording width and height by setting variables width and height" \
    "read -q \"?Hit Enter to begin recording . . .\"" \
    "/home/dev/.local/bin/termtosvg demo.svg -t window_frame -g \${width:-112}x\${height:-15} -M 1500 -c \"zsh -i\"" \
> /home/dev/.local/bin/start.zsh'
ctnr_urun chmod +x /home/$user/.local/bin/start.zsh

ctnr_urun rm -f /home/$user/.zhistory
buildah config \
    --cmd '/home/dev/.local/bin/start.zsh' \
    $ctnr
buildah commit --quiet --rm $ctnr $img
