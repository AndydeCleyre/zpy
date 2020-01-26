 ZPYSRC=${0:P}

 autoload -Uz zargs
 ZPYPROCS="${${$(nproc 2>/dev/null):-$(sysctl -n hw.logicalcpu 2>/dev/null)}:-4}"

 # Folder containing all project-venvs (venvs_path) folders.
 export VENVS_WORLD=${XDG_DATA_HOME:-~/.local/share}/venvs
 # Each project is linked to one or more of:
 # $VENVS_WORLD/<hash of proj-dir>/{venv,venv2,venv-pypy,venv-<pyver>}
 # which is also:
 # $(venvs_path <proj-dir>)/{venv,venv2,venv-pypy,venv-<pyver>}

 # Syntax highlighter, reading stdin.
 .zpy_hlt () {  # <syntax>
     if (( $+commands[bat] )); then
         BAT_THEME=${BAT_THEME:-ansi-dark} bat --color always --paging never -p -l $1
         # recommended: ansi-dark, zenburn
     elif (( $+commands[highlight] )); then
         HIGHLIGHT_OPTIONS=${HIGHLIGHT_OPTIONS:-'-s darkplus'} highlight -O truecolor -S $1
         # recommended: aiseered, darkplus, oxygenated
     else
         cat -
     fi
 }

 # zpy (below), but never highlight
 .zpy () {  # [zpy-function...]
     if [[ $# -gt 0 ]]; then
         .zpy \
         | pcregrep -Mh '(^[^\n]+\n)*(^'$1'( |$))[^\n]*(\n[^\n]+)*' \
         | sed 's/  # / /g'
         for zpyfn in ${@[2,-1]}; do
             print -rl -- '' "$(
                 .zpy \
                 | pcregrep -Mh '(^[^\n]+\n)*(^'$zpyfn'( |$))[^\n]*(\n[^\n]+)*' \
                 | sed 's/  # / /g'
             )"
         done
     else
         pcregrep '^(alias|([^ \n]+ \(\))|#|$)' $ZPYSRC \
         | uniq \
         | sed -E 's/(^[^ ]+) \(\) \{(.*\})?(.*)/\1\3/g' \
         | sed -E 's/^alias ([^=]+)[^#]+(# .+)?/\1  \2/g' \
         | sed 's/  # / /g'
     fi
 }

# Print description and arguments for all or specified functions.
# To see actual function contents, use `which <funcname>`.
zpy () {  # [zpy-function...]
    local helps=(-h --help)
    .zpy ${@:|helps} | .zpy_hlt zsh
}

 if (( $+commands[md5sum] )); then
     .zpy_venvs_path () {  # [proj-dir]
         REPLY="${VENVS_WORLD}/${$(md5sum =(<<<${${1:-${PWD}}:P}))%% *}"
     }
 else
     .zpy_venvs_path () {  # [proj-dir]
         REPLY="${VENVS_WORLD}/$(md5 -qs ${${1:-${PWD}}:P})"
     }
 fi

 .zpy_venvs_paths () {  # <proj-dir...>
     reply=()
     for projdir in $@; do
         .zpy_venvs_path $projdir
         reply+=($REPLY)
     done
 }

 .zpy_chooseproj () {
     REPLY=$(print -rln -- ${VENVS_WORLD}/*/project(@N-/:P) | fzf --reverse -0 -1)
 }

# Get path of folder containing all venvs for the current folder or specified proj-dir.
# Pass -i to interactively choose the project.
venvs_path () {  # [-i|proj-dir]
    if [[ "$1" == '-i' ]]; then
        .zpy_chooseproj
        venvs_path "$REPLY"
    else
        .zpy_venvs_path $@
        print -rn -- $REPLY
    fi
}

# Install and upgrade packages.
alias pipi="python -m pip --disable-pip-version-check install -U"  # <req...>

# Install packages according to all found or specified requirements.txt files (sync).
pips () {  # [reqs-txt...]
    local reqstxts=(${@:-*requirements.txt(N)})
    if [[ $reqstxts ]]; then
        print -rP "%F{cyan}> %B%F{green}syncing%b%F{cyan} env %B<-%b $reqstxts %B::%b ${${${PWD:P}/#~/~}/%${PWD:t}/%B${PWD:t}%b}%f"
        pip-sync -q $reqstxts
        for reqstxt in $reqstxts; do                                        # can remove if https://github.com/jazzband/pip-tools/issues/896 is resolved (by merging https://github.com/jazzband/pip-tools/pull/907)
            python -m pip --disable-pip-version-check install -qr $reqstxt  # AND
        done                                                                # https://github.com/jazzband/pip-tools/issues/925 is resolved (by merging https://github.com/jazzband/pip-tools/pull/927)
    fi
}

 .zpy_pipc () {  # <reqs-in> [pip-compile-arg...]
     print -rP "%F{cyan}> %F{yellow}compiling%F{cyan} $1 %B->%b ${1:r}.txt %B::%b ${${${PWD:P}/#~/~}/%${PWD:t}/%B${PWD:t}%b}%f"
     pip-compile --no-header --build-isolation ${@[2,-1]} $1 2>&1 | .zpy_hlt py
 }

# Compile requirements.txt files from all found or specified requirements.in files (compile).
pipc () {  # [reqs-in...]
    zargs -rl -P $ZPYPROCS -- ${@:-*requirements.in(N)} -- .zpy_pipc
}
# Compile with hashes.
pipch () {  # [reqs-in...]
    zargs -ri___ -P $ZPYPROCS -- ${@:-*requirements.in(N)} -- .zpy_pipc ___ --generate-hashes
}
#
# Compile, then sync.
pipcs () {  # [reqs-in...]
    pipc $@
    pips ${^@:r}.txt
}
# Compile with hashes, then sync.
pipchs () {  # [reqs-in...]
    pipch $@
    pips ${^@:r}.txt
}

 .zpy_pipa () {  # <category> <req...>
     local reqsin=${1:+${1}-}requirements.in
     print -rP "%F{cyan}> %F{magenta}appending%F{cyan} %B->%b $reqsin %B::%b ${${${PWD:P}/#~/~}/%${PWD:t}/%B${PWD:t}%b}%f"
     print -rl -- ${@[2,-1]} >>! $reqsin
     .zpy_hlt py < $reqsin
 }

# Add loose requirements to [<category>-]requirements.in (add).
# pipa(|build|dev|doc|publish|test) <req...>
alias pipa=".zpy_pipa ''"  # <req...>

# Add loose requirements to [<category>-]requirements.in (add).
alias pipabuild=".zpy_pipa build"  # <req...>
alias pipadev=".zpy_pipa dev"  # <req...>
alias pipadoc=".zpy_pipa doc"  # <req...>
alias pipapublish=".zpy_pipa publish"  # <req...>
alias pipatest=".zpy_pipa test"  # <req...>

# Add to requirements.in, then compile it to requirements.txt (add, compile).
pipac () {  # <req...>
    pipa $@
    pipc requirements.in
}
# Add to requirements.in, then compile it with hashes to requirements.txt.
pipach () {  # <req...>
    pipa $@
    pipch requirements.in
}
#
# Add to requirements.in, compile it to requirements.txt, then sync to that (add, compile, sync).
pipacs () {  # <req...>
    pipac $@
    pips requirements.txt
}
# Add, compile with hashes, sync.
pipachs () {  # <req...>
    pipach $@
    pips requirements.txt
}

 .zpy_pipu () {  # <hashes|nohashes> <reqsin> [req...]
     local gen_hashes=${1:#nohashes}
     local reqsin=$2
     local reqs=(${@[3,-1]})

     local reqstxt=${reqsin:r}.txt
     local before=$(mktemp)
     cp $reqstxt $before 2>/dev/null || true

     if [[ $# -gt 2 ]]; then
         .zpy_pipc $reqsin -q ${${@/*/-P}:^reqs} ${gen_hashes:+--generate-hashes}
     else
         .zpy_pipc $reqsin -q -U ${gen_hashes:+--generate-hashes}
     fi

     diff -u -L "${${reqstxt:P}/#~/~} then" $before -L "${${reqstxt:P}/#~/~} now" $reqstxt | .zpy_hlt diff
     rm -f $before
 }

# Recompile *requirements.txt with upgraded versions of all or specified packages (upgrade).
pipu () {  # [req...]
    zargs -ri___ -P $ZPYPROCS -- *requirements.in(N) -- .zpy_pipu nohashes ___ $@
}
# Upgrade with hashes.
pipuh () {  # [req...]
    zargs -ri___ -P $ZPYPROCS -- *requirements.in(N) -- .zpy_pipu hashes ___ $@
}
#
# Upgrade, then sync.
pipus () {  # [req...]
    pipu $@
    pips
}
# Upgrade with hashes, then sync.
pipuhs () {  # [req...]
    pipuh $@
    pips
}

 .zpy_pyvervenvname () {
     if (( $+commands[python] )); then
         local name=($(python -V 2>&1 | tail -n 1))
         print -rn venv-${(j:-:)name:0:2:l:gs/[/}
     else
         print -rP "%F{red}> No 'python' found in path!%f" 1>&2
         return 1
     fi
 }

 .zpy_envin () {  # <venv-name> <venv-init-cmd> [reqs-txt...]
     .zpy_venvs_path
     local vpath=$REPLY
     local venv=${vpath}/${1}
     print -rP "%F{cyan}> %F{green}entering%F{cyan} venv %B@%b ${venv/#~/~} %B::%b ${${${PWD:P}/#~/~}/%${PWD:t}/%B${PWD:t}%b}%f"
     [[ -d $venv ]] || eval $2 ${(q-)venv}
     if (( $? )); then
        print -rP "%F{red}> FAILED: $2 ${(q-)venv}" 1>&2
        return 1
     fi
     ln -sfn $PWD ${vpath}/project
     . $venv/bin/activate
     pipi -q pip pip-tools
     rehash
     pips ${@[3,-1]}
 }

# Activate venv 'venv' (creating if needed) for the current folder, and sync its
# installed package set according to all found or specified requirements.txt files.
# In other words: [create, ]activate, sync.
# The interpreter will be whatever `python3` refers to at time of venv creation.
alias envin=".zpy_envin venv 'python3 -m venv'"  # [reqs-txt...]
# Also available for 'venv2'/`python2`, 'venv-pypy'/`pypy3`, 'venv-<current pyver>'/`python`:
# envin(2|py|current) [reqs-txt...]

# Like envin, but with venv 'venv2' and command `python2`.
alias envin2=".zpy_envin venv2 virtualenv2"  # [reqs-txt...]

# Like envin, but with venv 'venv-pypy' and command `pypy3`.
alias envinpy=".zpy_envin venv-pypy 'pypy3 -m venv'"  # [reqs-txt...]

# Like envin, but with venv 'venv-<current pyver>' and command `python`.
# Useful if you use pyenv or similar for multiple py3 versions on the same project.
envincurrent () {  # [reqs-txt...]
    local venv_name
    venv_name=$(.zpy_pyvervenvname) \
    && .zpy_envin "$venv_name" 'python -m venv' $@ \
    || return 1
}

# If `venvs_path`/venv exists for the current or specified project folder,
# activate it without installing anything.
# Otherwise, act as `envin` (create, activate, sync).
# Pass -i to interactively choose the project.
activate () {  # [-i|proj-dir]
    if [[ "$1" == '-i' ]]; then
        .zpy_chooseproj
        activate "$REPLY"
    else
        local projdir=${1:-${PWD}}
        .zpy_venvs_path $projdir
        . "$REPLY/venv/bin/activate" 2>/dev/null
        if [[ $? == 127 ]]; then
            trap "cd $PWD" EXIT
            cd "$projdir"
            envin
        fi
    fi
}
#
# Deactivate.
alias envout="deactivate"

 .zpy_whichvpy () {  # <venv-name> <script>
     .zpy_venvs_path ${2:P:h}
     REPLY="${REPLY}/${1}/bin/python"
 }

 .zpy_vpy () {  # <venv-name> <script> [script-arg...]
     .zpy_whichvpy $1 $2
     "$REPLY" ${@[2,-1]}
 }

# Run script with its folder's associated venv 'venv'.
alias vpy=".zpy_vpy venv"  # <script> [script-arg...]
# Also available for 'venv2', 'venv-pypy', 'venv-<current pyver>':
# vpy(2|py|current) <script> [script-arg...]

# Like vpy, but with venv 'venv2'.
alias vpy2=".zpy_vpy venv2"  # <script> [script-arg...]

# Like vpy, but with venv 'venv-pypy'.
alias vpypy=".zpy_vpy venv-pypy"  # <script> [script-arg...]

# Like vpy, but with venv 'venv-<current pyver>'.
vpycurrent () { .zpy_vpy $(.zpy_pyvervenvname) $@ }  # <script> [script-arg...]

# Get path of project for the activated venv.
whichpyproj () {
    print -rn -- ${"$(which python)":h:h:h}/project(@N:P)
}

 .zpy_vpyshebang () {  # <venv-name> <script...>
     local vpyscript=$(whence -p vpy)
     for script in ${@[2,-1]}; do
         chmod +x $script
         .zpy_whichvpy $1 $script
         print -rl "#!${vpyscript:-$REPLY}" "$(<${script})" >! $script
     done
 }

# Prepend each script with a shebang for its folder's associated venv interpreter.
# If `vpy` exists in the PATH, #!/path/to/vpy will be used instead.
# Also ensure the script is executable.
alias vpyshebang=".zpy_vpyshebang venv"  # <script...>
# Also available for 'venv2', 'venv-pypy', 'venv-<current pyver>':
# vpy(2|py|current)shebang <script...>

# Like vpyshebang, but with venv 'venv2'.
alias vpy2shebang=".zpy_vpyshebang venv2"  # <script...>

# Like vpyshebang, but with venv 'venv-pypy'.
alias vpypyshebang=".zpy_vpyshebang venv-pypy"  # <script...>

# Like vpyshebang, but with venv 'venv-<current pyver>'.
vpycurrentshebang () { .zpy_vpyshebang $(.zpy_pyvervenvname) $@ }  # <script...>

 .zpy_vpyfrom () {  # <venv-name> <proj-dir> <script-name> [script-arg...]
     .zpy_venvs_path $2
     "${REPLY}/${1}/bin/${3}" ${@[4,-1]}
 }

# Run script from a given project folder's associated venv's bin folder.
alias vpyfrom=".zpy_vpyfrom venv"  # <proj-dir> <script-name> [script-arg...]
# Also available for 'venv2', 'venv-pypy', 'venv-<current pyver>':
# vpy(2|py|current)from <proj-dir> <script-name> [script-arg...]

# Like vpyfrom, but with venv 'venv2'.
alias vpy2from=".zpy_vpyfrom venv2"  # <proj-dir> <script-name> [script-arg...]

# Like vpyfrom, but with venv 'venv-pypy'.
alias vpypyfrom=".zpy_vpyfrom venv-pypy"  # <proj-dir> <script-name> [script-arg...]

# Like vpyfrom, but with venv 'venv-<current pyver>'.
vpycurrentfrom () { .zpy_vpyfrom $(.zpy_pyvervenvname) $@ }  # <proj-dir> <script-name> [script-arg...]

# Generate an external launcher for a script in a given project folder's associated venv's bin folder.
vpylauncherfrom () {  # <proj-dir> <script-name> <launcher-dest>
    if [[ -d $3 ]]; then
        vpylauncherfrom $1 $2 ${3}/${2}
    elif [[ -e $3 ]]; then
        print -rP "%F{red}> ${${3:a}/#~/~} exists! %B::%b ${${1:P}/#~/~}%f" 1>&2
        return 1
    else
        .zpy_venvs_path $1
        ln -s "${REPLY}/venv/bin/${2}" $3
    fi
}

# Delete venvs for project folders which no longer exist.
prunevenvs () {
    local orphaned_venv
    for proj in ${VENVS_WORLD}/*/project(@N:P); do
        if [[ ! -d $proj ]]; then
            .zpy_venvs_path $proj
            orphaned_venv=$REPLY
            print -rl "Missing: ${proj/#~/~}" "Orphan: $(du -hs $orphaned_venv)"
            read -q "?Delete orphan [yN]? "
            [[ $REPLY == 'y' ]] && rm -rf $orphaned_venv
            print '\n'
        fi
    done
}

 .zpy_pipcheckoldcells () {  # <proj-dir>
     local proj=${1:P}
     if (( $+commands[jq] )); then
         local cells=($(
             vpyfrom $proj python -m pip --disable-pip-version-check list -o --format json \
             | jq -r '.[] | select(.name|test("^(setuptools|six|pip|pip-tools)$")|not) | .name,.version,.latest_version'
         ))
         #    (package, version, latest)
         # -> (package, version, latest, proj-dir)
         for ((i = 3; i <= $#cells; i+=4)); do
             cells[i]+=("${proj/#~/~}")
         done
     else
         local cells=($(
             vpyfrom $proj python -m pip --disable-pip-version-check list -o \
             | tail -n +3 \
             | grep -Ev '^(setuptools|six|pip|pip-tools) ' \
             | awk '{print $1,$2,$3,$4}'
         ))
         #    (package, version, latest, type)
         # -> (package, version, latest, proj-dir)
         for ((i = 4; i <= $#cells; i+=4)); do
             cells[i]="${proj/#~/~}"
         done
     fi
     print -rl -- $cells
 }

# `pip list -o` for all or specified projects.
pipcheckold () {  # [proj-dir...]
    local cells=("%F{cyan}%BPackage%b%f" "%F{cyan}%BVersion%b%f" "%F{cyan}%BLatest%b%f" "%F{cyan}%BProject%b%f")
    cells+=(${(f)"$(zargs -rl -P $ZPYPROCS -- ${@:-${VENVS_WORLD}/*/project(@N-/)} -- .zpy_pipcheckoldcells)"})
    if [[ $#cells -gt 4 ]]; then print -rPaC 4 -- $cells; fi
}

 .zpy_pipusproj () {  # <proj-dir>
     trap "cd $PWD" EXIT
     cd $1
     activate
     pipus
     deactivate
 }

# `pipus` (upgrade-compile, sync) for all or specified projects.
pipusall () {  # [proj-dir...]
    zargs -rl -P $ZPYPROCS -- ${@:-${VENVS_WORLD}/*/project(@N-/:P)} -- .zpy_pipusproj
}

# Inject loose requirements.in dependencies into pyproject.toml.
# Run either from the folder housing pyproject.toml, or one below.
# To categorize, name files <category>-requirements.in.
pypc () {
    python -m pip --disable-pip-version-check install -q tomlkit \
    || print -rP "%F{yellow}> You probably want to activate a venv with 'envin', first %B::%b ${${${PWD:P}/#~/~}/%${PWD:t}/%B${PWD:t}%b}%f"
    python -c "
from pathlib import Path
from contextlib import suppress
import re

import tomlkit


suffix = 'requirements.in'
pyproject = Path().absolute() / 'pyproject.toml'
if not pyproject.is_file():
    pyproject = pyproject.parents[1] / 'pyproject.toml'
if pyproject.is_file():
    reqsins = [*pyproject.parent.glob(f'*/*{suffix}')] + [*pyproject.parent.glob(f'*{suffix}')]
    toml_data = tomlkit.parse(pyproject.read_text())
    for reqsin in reqsins:
        print(f'\033[96m> injecting {reqsin} -> {pyproject}\033[0m')
        pyproject_reqs = []
        for line in reqsin.read_text().splitlines():
            with suppress(AttributeError):
                pyproject_reqs.append(
                    re.search(r'^(-\S+\s+)*([^#]+)', line).group(2).rstrip()
                )
        extras_catg = reqsin.name.rsplit(suffix, 1)[0].rstrip('-.')
        if not extras_catg:
            toml_data['tool']['flit']['metadata']['requires'] = pyproject_reqs
        else:
            # toml_data['tool']['flit']['metadata'].setdefault('requires-extra', {})  # enable on close of https://github.com/sdispater/tomlkit/issues/49
            if 'requires-extra' not in toml_data['tool']['flit']['metadata']:         # remove when #49 is fixed
                toml_data['tool']['flit']['metadata']['requires-extra'] = {}          # remove when #49 is fixed
            toml_data['tool']['flit']['metadata']['requires-extra'][extras_catg] = pyproject_reqs
    pyproject.write_text(tomlkit.dumps(toml_data))
    "
}

 # Get a new or existing Sublime Text project file for the working folder.
 .zpy_get_sublp () {
     local spfile
     local spfiles=(*.sublime-project(N))
     if [[ ! $spfiles ]]; then
         spfile=${PWD:t}.sublime-project
         print -r '{}' >! $spfile
     else
         spfile=$spfiles[1]
     fi
     REPLY=$spfile
 }

# Specify the venv interpreter in a new or existing Sublime Text project file for the working folder.
vpysublp () {
    .zpy_get_sublp
    local stp=$REPLY
    .zpy_venvs_path
    local pypath=${REPLY}/venv/bin/python
    print -rP "%F{cyan}> %F{magenta}writing%F{cyan} interpreter ${pypath/#~/~} %B->%b ${stp/#~/~} %B::%b ${${${PWD:P}/#~/~}/%${PWD:t}/%B${PWD:t}%b}%f"
    if (( $+commands[jq] )); then
        print -r -- "$(jq --arg py $pypath '.settings+={python_interpreter: $py}' $stp)" >! $stp
    else
        python -c "
from pathlib import Path
from json import loads, dumps
spfile = Path('''${stp}''')
sp = loads(spfile.read_text())
sp.setdefault('settings', {})
sp['settings']['python_interpreter'] = '''${pypath}'''
spfile.write_text(dumps(sp, indent=4))
        "
    fi
}

# Launch a new or existing Sublime Text project, setting venv interpreter.
sublp () {  # [subl-arg...]
    vpysublp
    .zpy_get_sublp
    subl --project "$REPLY" $@
}

 .zpy_pipzlistrow () {  # <projects_home> <bin>
     setopt localoptions extendedglob
     local projects_home=$1
     local bin=$2
     local plink=${bin:P:h:h:h}/project
     local pdir=${plink:P}
     if [[ -h $plink && $pdir =~ "^${projects_home}/" ]]; then
         if (( $+commands[jq] )); then
             local piplistline=($(
                 vpyfrom $pdir python -m pip --disable-pip-version-check list --format json \
                 | jq -r '.[] | .name |= ascii_downcase | select(.name=="'${${pdir:t}//[^[:alnum:].]##/-}'") | .name,.version'
             ))
         else
             local piplistline=($(
                 vpyfrom $pdir python -m pip --disable-pip-version-check list \
                 | grep -i "^${${pdir:t}//[^[:alnum:].]##/-} "
             ))
         fi
         piplistline+=('????')
         local pyverlines=(${(f)"$(vpyfrom $pdir python -V)"})
         print -rl -- "${bin:t}" "${piplistline[1,2]}" "${pyverlines[-1]}"
     fi
 }

 .zpy_pkgspec2name () {  # pkgspec
     REPLY=${${(j: :)${${(s: :)1:l}:#-*}}%%[ \[<>=#;]*}
 }

 .zpy_pipzinstallpkg () {  # <projects_home> <pkg>
     trap "cd $PWD" EXIT
     local projects_home=$1
     local pkg=$2
     .zpy_pkgspec2name $pkg
     local pkgname=$REPLY
     mkdir -p ${projects_home}/${pkgname}
     cd ${projects_home}/${pkgname}
     rm -f requirements.{in,txt}
     activate
     pipacs $pkg
     deactivate
 }

 .zpy_pipzchoosepkgs () {  # <projects_home> [header='Packages:']
    reply=(${(f)"$(
        print -rln -- $1/*(/:t) \
        | fzf --reverse -m -0 --header="${2:-Packages:}" \
        --prompt='Which packages? Choose more than one with <tab>.'
    )"})
}

# A basic pipx clone (py3 only).
# Package manager for venv-isolated scripts.
#
# pipz list [pkgname...]  ## If no pkg is provided, list all installed.
# pipz install <pkgspec...>
# pipz inject <installed-pkgname> <extra-pkgspec...>
# pipz (upgrade|uninstall|reinstall)-all
# pipz (upgrade|uninstall|reinstall) [pkspec...]    ## If no pkg is provided, interactively choose.
# pipz runpip <pkgname> <pip-arg...>
# pipz runpkg <pkgspec> <cmd> [cmd-arg...]
pipz () {  # [list|install|(uninstall|upgrade|reinstall)(|-all)|inject|runpip|runpkg] [subcmd-arg...]
    trap "cd $PWD" EXIT
    setopt localoptions nopromptsubst
    local projects_home=${XDG_DATA_HOME:-~/.local/share}/python
    local bins_home=${${XDG_DATA_HOME:-~/.local/share}:P:h}/bin
    case $1 in
    'install')
        zargs -rl -P $ZPYPROCS -- ${@[2,-1]} -- .zpy_pipzinstallpkg $projects_home
        mkdir -p $bins_home
        local bins
        local pkgname
        for pkg in ${@[2,-1]}; do
            .zpy_pkgspec2name $pkg
            pkgname=$REPLY
            cd ${projects_home}/${pkgname}
            .zpy_venvs_path
            bins=("${REPLY}/venv/bin/"*(N:t))
            bins=(${bins:#([aA]ctivate(|.csh|.fish|.ps1)|easy_install(|-<->*)|(pip|python|pypy)(|<->*)|*.so|__pycache__)})
            [[ $pkgname != pip-tools ]] && bins=(${bins:#pip-(compile|sync)})
            [[ $pkgname != wheel ]] && bins=(${bins:#wheel})
            [[ $pkgname != chardet ]] && bins=(${bins:#chardetect})
            bins=(${(f)"$(
                print -rln -- $bins \
                | fzf --reverse -m -0 -1 --header="Installing $pkg . . ." \
                --prompt='Which scripts should be added to the path? Choose more than one with <tab>.'
            )"})
            for bin in $bins; do vpylauncherfrom . $bin $bins_home; done
        done
    ;;
    'uninstall')
        if [[ ${@[2,-1]} ]]; then
            local pkgs=(${@[2,-1]})
        else
            .zpy_pipzchoosepkgs $projects_home 'Uninstalling . . .'
            [[ $reply ]] || return 1
            local pkgs=($reply)
        fi
        local vpath pkgname
        for pkg in $pkgs; do
            .zpy_pkgspec2name $pkg
            pkgname=$REPLY
            .zpy_venvs_path ${projects_home}/${pkgname}
            vpath=$REPLY
            rm -rf ${projects_home}/${pkgname} $vpath
            for bin in $bins_home/*(@N); do
                if [[ ${bin:P} =~ "^${vpath}/" ]]; then rm $bin; fi
            done
        done
    ;;
    'uninstall-all')
        pipz uninstall ${projects_home}/*(/:t)
    ;;
    'upgrade')
        if [[ ${@[2,-1]} ]]; then
            local pkgnames=()
            for pkg in ${@[2,-1]}; do
                .zpy_pkgspec2name $pkg
                pkgnames+=($REPLY)
            done
        else
            .zpy_pipzchoosepkgs $projects_home 'Upgrading . . .'
            [[ $reply ]] || return 1
            local pkgnames=($reply)
        fi
        local before=$(mktemp)
        pipz list >! $before
        pipusall ${projects_home}/${^pkgnames}
        diff -u -L Then $before -L Now =(pipz list) | .zpy_hlt diff
        rm -f $before
    ;;
    'upgrade-all')
        pipz upgrade ${projects_home}/*(/:t)
    ;;
    'list')
        print -rP "projects %B@%b %F{cyan}${projects_home/#~/~}%f"
        print -rP "venvs %B@%b %F{cyan}${${VENVS_WORLD}/#~/~}%f"
        print -rP "apps exposed %B@%b %F{cyan}${bins_home/#~/~}%f [ %F{blue}export path=(${bins_home/#~/~} \$path)%f ]"
        print
        print -rC 4 -- ${projects_home}/*(/N:t)
        print
        local bins=()
        if [[ $# -gt 1 ]]; then
            .zpy_venvs_paths ${projects_home}/${^@[2,-1]:l}
            local venvs_path_whitelist=($reply)
            for bin in ${bins_home}/*(@N:P); do
                for vpath in $venvs_path_whitelist; do
                    if [[ $bin =~ "^${vpath}/" ]]; then bins+=($bin); break; fi
                done
            done
        else
            bins=(${bins_home}/*(@N:P))
            bins=(${(M)bins:#${VENVS_WORLD}/*})
        fi
        local cells=("%F{cyan}%BCommand%b%f" "%F{cyan}%BPackage%b%f" "%F{cyan}%BRuntime%b%f")
        cells+=(${(f)"$(zargs -rl -P $ZPYPROCS -- $bins -- .zpy_pipzlistrow $projects_home)"})
        if [[ $#cells -gt 3 ]]; then
            print -rPaC 3 -- $cells | head -n 1
            print -rPaC 3 -- $cells | tail -n +2 | sort
        fi
    ;;
    'reinstall')
        if [[ ${@[2,-1]} ]]; then
            local pkgs=(${@[2,-1]})
        else
            .zpy_pipzchoosepkgs $projects_home 'Reinstalling . . .'
            [[ $reply ]] || return 1
            local pkgs=($reply)
        fi
        pipz uninstall $pkgs
        pipz install $pkgs
    ;;
    'reinstall-all')
        pipz reinstall ${projects_home}/*(/N:t)
    ;;
    'inject')
        cd ${projects_home}/${2:l} || return 1
        .zpy_venvs_path
        local vbinpath="${REPLY}/venv/bin/"
        local blacklist=(${vbinpath}*(N:t))
        envin
        pipacs ${@[3,-1]}
        deactivate
        local bins=(${vbinpath}*(N:t))
        bins=(${bins:|blacklist})
        bins=(${(f)"$(
            print -rln -- $bins \
            | fzf --reverse -m -0 --header="Injecting [${(j:, :)@[3,-1]}] -> $2 . . ." \
            --prompt='Which scripts should be added to the path? Choose more than one with <tab>.'
        )"})
        for bin in $bins; do vpylauncherfrom . $bin $bins_home; done
    ;;
    'runpip')
        vpyfrom ${projects_home}/${2:l} python -m pip ${@[3,-1]}
    ;;
    'runpkg')
        local pkg=$2
        .zpy_pkgspec2name $pkg
        local pkgname=$REPLY
        local cmd=(${@[3,-1]})
        local projdir=${TMPPREFIX}_pipz/${pkgname}
        .zpy_venvs_path $projdir
        local vpath=$REPLY
        local venv=${vpath}/venv
        local bin=${venv}/bin/${cmd[1]}
        if [[ ! -f $bin || ! -x $bin ]]; then
            [[ -d $venv ]] || python3 -m venv $venv
            ln -sfn $projdir ${vpath}/project
            . $venv/bin/activate
            pipi $pkg -q
            deactivate
        fi
        ${venv}/bin/${cmd}
    ;;
    *)
        zpy pipz
    ;;
    esac
}

 # Completions
 # -----------

 _zpy_helpmsg () {  # funcname
     _message -r "$(.zpy $1 | sed -E 's/^([^#].*)/%B\1%b/g' | sed -E 's/^(#.*)/%F{blue}\1%f/g')"
 }

 # Message-only
 for zpyfn in pipa pipac pipu prunevenvs pypc sublp vpysublp whichpyproj; do
     _${zpyfn} () { _zpy_helpmsg ${0[2,-1]} }
     compdef _${zpyfn} ${zpyfn} 2>/dev/null  # Includes gratuitous compdef for pipa
 done
 compdef _pipa .zpy_pipa 2>/dev/null
 compdef _pipac pipach pipacs pipachs 2>/dev/null
 compdef _pipu pipuh pipus pipuhs 2>/dev/null

 # *.in
 _pipc () {
     _files -g '*.in'
     _zpy_helpmsg ${0[2,-1]}
 }
 compdef _pipc pipc pipch pipcs pipchs 2>/dev/null

 # *.txt
 for zpyfn in envin pips; do
     _${zpyfn} () {
         _files -g '*.txt'
         _zpy_helpmsg ${0[2,-1]}
     }
 done
 compdef _envin .zpy_envin envincurrent 2>/dev/null
 compdef _pips pips 2>/dev/null

 # Potential Projects (Folders + -i)
 for zpyfn in activate venvs_path; do
     _${zpyfn} () {
         [[ ${#words} -le 2 ]] \
         && _arguments '-i' '1:New or Existing Projects:_files -/'
         _zpy_helpmsg ${0[2,-1]}
     }
     compdef _${zpyfn} ${zpyfn} 2>/dev/null
 done

 # Project Folders
 for zpyfn in pipcheckold pipusall; do
     _${zpyfn} () {
         _arguments "*:Projects:(${VENVS_WORLD}/*/project(@N-/:P))"
         _zpy_helpmsg ${0[2,-1]}
     }
     compdef _${zpyfn} ${zpyfn} 2>/dev/null
 done

 # Project Scripts
 for zpyfn in vpy vpyshebang; do
     _${zpyfn} () {
         local script_arg
         [[ ${words[1]} =~ '^vpycurrent' ]] \
         && script_arg=1 \
         || script_arg=2
         _arguments "${script_arg}:Scripts:(${VENVS_WORLD}/*/project/*.py(N:P))"
         _zpy_helpmsg ${0[2,-1]}
     }
     compdef _${zpyfn} .zpy_${zpyfn} ${zpyfn/vpy/vpycurrent} 2>/dev/null
 done

 _zpy () {
     _arguments "*:Functions:($(.zpy | grep -Eo '^[^ |#]+'))"
     _zpy_helpmsg ${0[2,-1]}
 }
 compdef _zpy zpy 2>/dev/null

 _vpyfrom () {
     local proj_arg
     local script_arg
     if [[ ${words[1]} == vpycurrentfrom ]]; then
         proj_arg=1
         script_arg=2
     else
         proj_arg=2
         script_arg=3
     fi
     .zpy_venvs_path ${(Q)words[$[proj_arg+1]]}
     _arguments \
         "${proj_arg}:Projects:(${VENVS_WORLD}/*/project(@N-/:P))" \
         "${script_arg}:Scripts:_files -W ${REPLY}/venv/bin"
     _zpy_helpmsg ${0[2,-1]}
 }
 compdef _vpyfrom .zpy_vpyfrom vpycurrentfrom 2>/dev/null

 _vpylauncherfrom () {
     .zpy_venvs_path ${(Q)words[2]}
     _arguments \
         "1:Projects:(${VENVS_WORLD}/*/project(@N-/:P))" \
         "2:Scripts:_files -W ${REPLY}/venv/bin" \
         '3:Destinations:_files -/'
     _zpy_helpmsg ${0[2,-1]}
 }
 compdef _vpylauncherfrom vpylauncherfrom 2>/dev/null

 _pipz () {
     local cmds=(list install uninstall uninstall-all upgrade upgrade-all reinstall reinstall-all inject runpip runpkg)
     if [[ ${words[2]} =~ '^((un|re)install|upgrade|list)$' ]]; then
         _arguments \
             "1:commands:($cmds)" \
             "*:Installed Packages:(${XDG_DATA_HOME:-~/.local/share}/python/*(/N:t))"
     elif [[ ${words[2]} =~ '^(inject|runpip)$' ]]; then
         _arguments \
             "1:commands:($cmds)" \
             "2:Installed Packages:(${XDG_DATA_HOME:-~/.local/share}/python/*(/N:t))"
     else
         _arguments "1:commands:($cmds)"
     fi
     _zpy_helpmsg ${0[2,-1]}
 }
 compdef _pipz pipz 2>/dev/null
