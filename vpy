#!/usr/bin/env zsh
venvs_path () {
	local venvs_world=${XDG_DATA_HOME:-$HOME/.local/share}/venvs
    ([[ $(command -v md5sum) ]] && echo "$venvs_world/$(printf "${${1:-$(pwd)}:P}" | md5sum | cut -d ' ' -f 1)") ||
                                   echo "$venvs_world/$(md5 -qs "${${1:-$(pwd)}:P}")"
}
exec $(venvs_path ${1:P:h})/venv/bin/python $@
