#!/usr/bin/env -S buildah unshare -- /bin/sh -e
ctnr=termtosvg-zpy-alpine
user=dev

alias rrun="buildah run --user root $ctnr"
alias urun="buildah run --user $user $ctnr"
alias bldfrom="buildah from --name $ctnr"

# Daily termtosvg-zpy-alpine base:
buildah rm $ctnr 2>/dev/null || true
today="$(date +%Y.%j)"
if ! bldfrom --pull=false localhost/$ctnr:$today; then
    bldfrom quay.io/andykluger/zpy-alpine:latest
    rrun apk upgrade --no-progress -q
    rrun apk add --no-progress -q gcc {libxml2,libxslt,musl,python3}-dev
    urun zsh -ic 'pipz install termtosvg'
    buildah tag "$(buildah commit --rm $ctnr $ctnr)" "localhost/$ctnr:$today"
    bldfrom localhost/$ctnr:$today
fi

# Interactive recording session:
urun zsh -ic "read '?Hit enter when ready to begin recording session . . .'; termtosvg demo.svg -t window_frame -g ${1:-86}x${2:-15} -M 2000 -c 'zsh -i'"
cp "$(buildah mount $ctnr)/home/$user/demo.svg" ./
buildah unmount $ctnr

# Use browser-preferred font:
sed -Ei 's/(font-family: )(.*, )(monospace;)/\1\3/g' demo.svg

# Fix dark-on-dark coloring:
sed -i 's/383830/b8bb26/g' demo.svg
