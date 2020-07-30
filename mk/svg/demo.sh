#!/bin/sh -e
# [<distro>=fedora]

distro=${1:-fedora}
case $distro in
    fedora) ;;
    alpine) ;;
    ubuntu) ;;
    *)
        printf '%s\n' \
            'Args: [<distro>]' \
            'Accepted distros:' \
            'fedora (default)' 'alpine (slow build)' ubuntu
        exit 1
    ;;
esac

printf '%s\n' 'You may wish to use a script from mk/input/ alongside this one.'

ctnr=zpydemo
gitroot="$(git -C "$(dirname "$0")" rev-parse --show-toplevel)"

if ! podman run -it --name $ctnr -e width=$width -e height=$height quay.io/andykluger/termtosvg-zpy-${distro}:latest; then
    "${gitroot}/mk/ctnr/termtosvg-zpy.sh ${distro}"
    podman run -it --name $ctnr -e width=$width -e height=$height quay.io/andykluger/termtosvg-zpy-${distro}:latest
fi

podman cp "$ctnr:/home/dev/demo.svg" "${gitroot}/build/"
podman rm $ctnr

# Use browser-preferred font:
sed -Ei 's/(font-family: )(.*, )(monospace;)/\1\3/g' "${gitroot}/build/demo.svg"

# Fix dark-on-dark coloring:
sed -i 's/383830/b8bb26/g' "${gitroot}/build/demo.svg"
