 ZPYSRC=${0:P}

 autoload -Uz zargs
 PROCS="${${$(nproc 2>/dev/null):-$(sysctl -n hw.logicalcpu 2>/dev/null)}:-4}"

 export VENVS_WORLD=${XDG_DATA_HOME:-~/.local/share}/venvs
 # path of folder containing all project-venv (venvs_path) folders
 # each project is linked to one or more of:
 # $VENVS_WORLD/<hash of proj-dir>/{venv,venv2,venvPyPy}
 # which is also accessible as:
 # `venvs_path <proj-dir>`/{venv,venv2,venvPyPy}

 # syntax highlighter, reading stdin
 __hlt () {  # <syntax>
     # recommended themes: aiseered, base16/flat, moria, oxygenated
     ((( $+commands[highlight] )) && highlight -O truecolor -s moria -S $1) ||
     ((( $+commands[bat]       )) && bat -l $1 -p)                          ||
                                     cat -
 }
# pipe pythonish syntax through this to make it colorful
alias hpype="__hlt py"

# print description and arguments for all or specified functions
# to see actual function contents, use `which <funcname>`
zpy () {  # [zpy-function]
    if [[ $# -gt 0 ]]; then
        pcregrep -Mh '(^[^\n]+\n)*^(alias '$1'=|('$1' \(\)))\n?([^\n]+\n)*' $ZPYSRC \
        | grep -Ev '^( |})' \
        | uniq \
        | sed -E 's/(^[^ ]+) \(\) \{(.*\})?(.*)/\1\3/g' \
        | sed -E 's/^alias ([^=]+)[^#]+(# .+)?/\1  \2/g' \
        | __hlt zsh
    else
        pcregrep '^(alias|([^ \n]+ \(\))|#|$)' $ZPYSRC \
        | uniq \
        | sed -E 's/(^[^ ]+) \(\) \{(.*\})?(.*)/\1\3/g' \
        | sed -E 's/^alias ([^=]+)[^#]+(# .+)?/\1  \2/g' \
        | __hlt zsh
    fi
}

# get path of folder containing all venvs for the current folder or specified project path
 if (( $+commands[md5sum] )); then
venvs_path () {  # [proj-dir]
    print -rn "${VENVS_WORLD}/${$(print -rn ${${1:-${PWD}}:P} | md5sum)%% *}"
}
 else
     venvs_path () {  # [proj-dir]
         print -rn "${VENVS_WORLD}/$(md5 -qs ${${1:-${PWD}}:P})"
     }
 fi

# start REPL
alias i="ipython"
alias i2="ipython2"

# install packages
alias pipi="pip --disable-pip-version-check install -U"  # <req> [req...]

 __pipc () {  # <reqs-in> [pip-compile option...]
     print -rP "%F{cyan}> %F{yellow}compiling%F{cyan} $1 %B->%b ${1:r}.txt %B::%b ${${PWD:P}/#~/~}%f"
     pip-compile --no-header ${@:2} $1 2>&1 | hpype
 }

# compile requirements.txt files from all found or specified requirements.in files (compile)
pipc () {  # [reqs-in...]
    zargs -rl -P $PROCS -- ${@:-*requirements.in(N)} -- __pipc
}
# compile with hashes
pipch () {  # [reqs-in...]
    zargs -ri___ -P $PROCS -- ${@:-*requirements.in(N)} -- __pipc ___ --generate-hashes
}

# install packages according to all found or specified requirements.txt files (sync)
pips () {  # [reqs-txt...]
    local reqstxts=(${@:-*requirements.txt(N)})
    if [[ $reqstxts ]]; then
        print -rP "%F{cyan}> %F{blue}syncing%F{cyan} env %B<-%b $reqstxts %B::%b ${${PWD:P}/#~/~}%f"
        pip-sync -q $reqstxts
        for reqstxt in $reqstxts; do  # can remove if https://github.com/jazzband/pip-tools/issues/896 is resolved (by merging https://github.com/jazzband/pip-tools/pull/907)
            pip install -qr $reqstxt  # AND
        done                          # https://github.com/jazzband/pip-tools/issues/925 is resolved (by merging https://github.com/jazzband/pip-tools/pull/927)
    fi
}

# compile, then sync
pipcs () {  # [reqs-in...]
    pipc $@
    pips ${^@:r}.txt
}
# compile with hashes, then sync
pipchs () {  # [reqs-in...]
    pipch $@
    pips ${^@:r}.txt
}

 __pipa () {  # <category> <req> [req...]
     local reqsin=${1:+${1}-}requirements.in
     print -rP "%F{cyan}> %F{magenta}appending%F{cyan} %B->%b $reqsin %B::%b ${${PWD:P}/#~/~}%f"
     print -rl ${@:2} >>! $reqsin
     hpype < $reqsin
 }
# add loose requirements to [<category>-]requirements.in (add)
alias pipa="__pipa ''"  # <req> [req...]
alias pipabuild="__pipa build"  # <req> [req...]
alias pipadev="__pipa dev"  # <req> [req...]
alias pipadoc="__pipa doc"  # <req> [req...]
alias pipapublish="__pipa publish"  # <req> [req...]
alias pipatest="__pipa test"  # <req> [req...]

# add to requirements.in and compile it to requirements.txt
pipac () {  # <req> [req...]
    pipa $@
    pipc requirements.in
}
# add to requirements.in and compile it with hashes to requirements.txt
pipach () {  # <req> [req...]
    pipa $@
    pipch requirements.in
}
# add to requirements.in and compile it to requirements.txt, then sync to that
pipacs () {  # <req> [req...]
    pipac $@
    pips requirements.txt
}
# add to requirements.in and compile it with hashes to requirements.txt, then sync to that
pipachs () {  # <req> [req...]
    pipach $@
    pips requirements.txt
}

 __pipu () {  # <hashes|nohashes> <reqsin> [req...]
     local gen_hashes=${1:#nohashes}
     local reqsin=$2
     local reqs=(${@:3})
     print -rP "%F{cyan}> %F{yellow}upgrading%F{cyan} ${reqsin:r}.txt %B<-%b $reqsin %B::%b ${${PWD:P}/#~/~}%f"
     if [[ $# -gt 2 ]]; then
         if [[ $gen_hashes ]]; then
             pip-compile --no-header --generate-hashes ${${@/*/-P}:^reqs} $reqsin 2>&1 | hpype
             pipch $reqsin  # can remove if https://github.com/jazzband/pip-tools/issues/759 gets fixed
         else
             pip-compile --no-header ${${@/*/-P}:^reqs} $reqsin 2>&1 | hpype
             pipc $reqsin  # can remove if https://github.com/jazzband/pip-tools/issues/759 gets fixed
         fi
     elif [[ $gen_hashes ]]; then
         pip-compile --no-header -U --generate-hashes $reqsin 2>&1 | hpype
     else
         pip-compile --no-header -U $reqsin 2>&1 | hpype
     fi
 }

# recompile *requirements.txt with upgraded versions of all or specified packages (upgrade)
pipu () {  # [req...]
    zargs -ri___ -P $PROCS -- *requirements.in(N) -- __pipu nohashes ___ $@
}
# upgrade with hashes
pipuh () {  # [req...]
    zargs -ri___ -P $PROCS -- *requirements.in(N) -- __pipu hashes ___ $@
}

# upgrade, then sync
pipus () {  # [req...]
    pipu $@
    pips
}
pipuhs () {  # [req...]
    pipuh $@
    pips
}

 __envin () {  # <venv-name> <venv-init-cmd> [reqs-txt...]
     local vpath=$(venvs_path)
     local venv=${vpath}/${1}
     print -rP "%F{cyan}> %F{green}entering%F{cyan} venv %B@%b ${venv/#~/~} %B::%b ${${PWD:P}/#~/~}%f"
     [[ -d $venv ]] || eval $2 ${(q-)venv}
     ln -sfn $PWD ${vpath}/project
     . $venv/bin/activate
     pip install -qU pip pip-tools
     rehash
     pips ${@:3}
 }
# activate venv for the current folder and install requirements, creating venv if necessary
alias envin="__envin venv 'python3 -m venv'"  # [reqs-txt...]
alias envin2="__envin venv2 virtualenv2"  # [reqs-txt...]
alias envinpypy="__envin venvPyPy 'pypy3 -m venv'"  # [reqs-txt...]

# activate without installing anything
activate () {  # [proj-dir]
    . "$(venvs_path ${1:-${PWD}})/venv/bin/activate"
}
activatefzf () {
    local projects=(${VENVS_WORLD}/*/project(@N-/:P))
    activate "$(print -rl $projects | fzf --reverse -0 -1)"
}
# deactivate
alias envout="deactivate"

 __whichvpy () {  # <venv-name> <script>
     print -rn "$(venvs_path ${2:P:h})/$1/bin/python"
 }
# get path of python for the given script's folder's associated venv
alias whichvpy="__whichvpy venv"  # <script>

 __vpy () {  # <venv-name> <script> [script-arg...]
     "$(__whichvpy $1 $2)" ${@:2}
 }
# run script with its folder's associated venv
alias vpy="__vpy venv"  # <script> [script-arg...]
alias vpy2="__vpy venv2"  # <script> [script-arg...]
alias vpypy="__vpy venvPyPy"  # <script> [script-arg...]

# get path of project for the activated venv
whichpyproj () {
    print -rn ${"$(which python)":h:h:h}/project(@N:P)
}

 __vpyshebang () {  # <venv-name> <script> [script...]
     local vpybin
     local vpyscript=$(whence -p vpy)
     for script in ${@:2}; do
         chmod +x $script
         vpybin="${vpyscript:-$(__whichvpy $1 $script)}"
         print -rl "#!${vpybin}" "$(<${script})" > $script
     done
 }
# prepend each script with a shebang for its folder's associated venv python
# if vpy exists in the PATH, #!/path/to/vpy will be used instead
# also ensure the script is executable
alias vpyshebang="__vpyshebang venv"  # <script> [script...]
alias vpy2shebang="__vpyshebang venv2"  # <script> [script...]
alias vpypyshebang="__vpyshebang venvPyPy"  # <script> [script...]

 __vpyfrom () {  # <venv-name> <proj-dir> <script-name> [script-arg...]
     "$(venvs_path $2)/$1/bin/$3" ${@:4}
 }
# run script from a given project folder's associated venv's bin folder
alias vpyfrom="__vpyfrom venv"  # <proj-dir> <script-name> [script-arg...]
alias vpy2from="__vpyfrom venv2"  # <proj-dir> <script-name> [script-arg...]
alias vpypyfrom="__vpyfrom venvPyPy"  # <proj-dir> <script-name> [script-arg...]

# generate an external launcher for a script in a given project folder's associated venv's bin folder
vpylauncherfrom () {  # <proj-dir> <script-name> <launcher-dest>
    if [[ -d $3 ]]; then
        vpylauncherfrom $1 $2 $3/$2
    elif [[ -e $3 ]]; then
        print -rP "%F{red}> ${${3:a}/#~/~} exists! %B::%b ${${1:P}/#~/~}%f"
        return 1
    else
        ln -s "$(venvs_path $1)/venv/bin/$2" $3
    fi
}

# delete venvs for project folders which no longer exist
prunevenvs () {
    local orphaned_venv
    for proj in ${VENVS_WORLD}/*/project(@N:P); do
        if [[ ! -d $proj ]]; then
            orphaned_venv=$(venvs_path $proj)
            print -rl "Missing: ${proj/#~/~}" "Orphan: $(du -hs $orphaned_venv)"
            read -q "?Delete orphan [yN]? "
            [[ $REPLY = 'y' ]] && rm -rf $orphaned_venv
            print '\n'
        fi
    done
}

 __pipcheckoldcells () {  # <proj-dir>
     # TODO: use jq if present, fall back to this
     local proj=${1:P}
     local cells=($(vpyfrom $proj pip --disable-pip-version-check list -o | tail -n +3 | grep -Ev '^(setuptools|six|pip|pip-tools) ' | awk '{print $1,$2,$3,$4}'))
     # [package; version; latest; type] -> [package; version; latest; proj-dir]
     for ((i = 1; i <= $#cells; i++)); do
         if (( $i % 4 == 0 )); then cells[i]="${proj/#~/~}"; fi
     done
     print -rl $cells
 }
# pip list -o for all or specified projects
pipcheckold () {  # [proj-dir...]
    local cells=("%F{cyan}%BPackage%b%f" "%F{cyan}%BVersion%b%f" "%F{cyan}%BLatest%b%f" "%F{cyan}%BProject%b%f")
    cells+=(${(f)"$(zargs -rl -P $PROCS -- ${@:-${VENVS_WORLD}/*/project(@N-/)} -- __pipcheckoldcells)"})
    if [[ $#cells -gt 4 ]]; then print -rPaC 4 $cells; fi
}

 __pipusproj () {  # <proj-dir>
     trap "cd $PWD" EXIT
     cd $1
     activate
     pipus
     deactivate
 }

# pipus for all or specified projects
pipusall () {  # [proj-dir...]
    zargs -ri___ -P $PROCS -- ${@:-${VENVS_WORLD}/*/project(@N-/:P)} -- __pipusproj ___ | grep '::'
}

# inject loose requirements.in dependencies into pyproject.toml
# run either from the folder housing pyproject.toml, or one below
# to categorize, name files <category>-requirements.in
pypc () {
    pip install -qU tomlkit || print -rP "%F{yellow}> You probably want to activate a venv with 'envin', first %B::%b ${${PWD:P}/#~/~}%f"
    python -c "
from pathlib import Path
import tomlkit
suffix = 'requirements.in'
cwd = Path().absolute()
pyproject = cwd / 'pyproject.toml'
if not pyproject.is_file():
    pyproject = cwd.parent / 'pyproject.toml'
reqsins = [*pyproject.parent.glob(f'*/*{suffix}')] + [*pyproject.parent.glob(f'*{suffix}')]
if pyproject.is_file():
    toml_data = tomlkit.parse(pyproject.read_text())
    for reqsin in reqsins:
        print(f'\033[96m> injecting {reqsin} -> {pyproject}\033[0m')
        pyproject_reqs = [
            line
            for line in reqsin.read_text().splitlines()
            if line.strip() and not (line.startswith('#') or line.startswith('-r'))
        ]
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

 # get a new or existing sublime text project file for the working folder
 __get_sublp () {
     local spfile
     local spfiles=(*.sublime-project(N))
     if [[ ! $spfiles ]]; then
         spfile=${PWD:t}.sublime-project
         print '{}' > $spfile
     else
         spfile=$spfiles[1]
     fi
     print -rn $spfile
 }

# specify the venv interpreter in a new or existing sublime text project file for the working folder
vpysublp () {
    # TODO: use jq if available, otherwise python
    local stp=$(__get_sublp)
    local pypath=$(venvs_path)/venv/bin/python
    print -rP "%F{cyan}> %F{magenta}writing%F{cyan} interpreter ${pypath/#~/~} %B->%b ${stp/#~/~} %B::%b ${${PWD:P}/#~/~}%f"
    python -c "
from pathlib import Path
from json import loads, dumps
spfile = Path('''${stp}''')
sp = loads(spfile.read_text())
sp.setdefault('settings', {})
sp['settings']['python_interpreter'] = '''${pypath}'''
spfile.write_text(dumps(sp, indent=4))
    "
}

# launch a new or existing sublime text project, setting venv interpreter
sublp () {  # [subl-arg...]
    vpysublp
    subl --project "$(__get_sublp)" $@
}

 __pipzlistrow () {  # <projects_home> <bin>
     # TODO: use jq if present, fall back to this
     local projects_home=$1
     local bin=$2
     local plink=${bin:P:h:h:h}/project
     local pdir=${plink:P}
     if [[ -h $plink && $pdir =~ "^${projects_home}/" ]]; then
         local piplistline=($(vpyfrom $pdir pip list | grep "^${pdir:t} "))
         print -rl "${bin:t}" "${piplistline[1,2]}" "$(vpyfrom $pdir python -V)"
     fi
 }

 __pipzinstallpkg () {  # <projects_home> <pkg>
     trap "cd $PWD" EXIT
     local projects_home=$1
     local pkg=$2
     mkdir -p $projects_home/$pkg
     cd $projects_home/$pkg
     envin
     rm -f requirements.{in,txt}
     pipacs $pkg
     envout
 }

# a basic pipx clone
# supported commands:
# pipz install <pkg> [pkg...]
# pipz uninstall [pkg...]
# pipz upgrade [pkg...]
# pipz list
# pipz reinstall [pkg...]
# pipz inject <pkg> <extra-pkg> [extra-pkg...]
# pipz runpip <pkg> <pip-arg...>
# pipz runpkg <pkg> <cmd> [cmd-arg...]
pipz () {
    trap "cd $PWD" EXIT
    local projects_home=${XDG_DATA_HOME:-~/.local/share}/python
    local bins_home=${${XDG_DATA_HOME:-~/.local/share}:P:h}/bin
    case $1 in
    'install')
        zargs -rl -P $PROCS -- ${@:2} -- __pipzinstallpkg $projects_home
        mkdir -p $bins_home
        local bins
        for pkg in ${@:2}; do
            cd $projects_home/$pkg
            bins=("$(venvs_path)/venv/bin/"*(N:t))
            bins=(${bins:#([aA]ctivate(|.csh|.fish|.ps1)|easy_install(|-<->*)|pip(|<->*)|python(|<->*))})
            [[ $pkg != pip-tools ]] && bins=(${bins:#pip-(compile|sync)})
            bins=(${(f)"$(print -rl $bins | fzf --reverse -m -0 -1 --prompt='['$pkg'] Which scripts should be added to the path? Select more than one with <tab>.')"})
            for bin in $bins; do vpylauncherfrom . $bin $bins_home; done
        done
    ;;
    'uninstall')
        if [[ ${@:2} ]]; then
            local vpath
            for pkg in ${@:2}; do
                vpath=$(venvs_path $projects_home/$pkg)
                rm -rf $projects_home/$pkg $vpath
                for bin in $bins_home/*(@N); do
                    if [[ ${bin:P} =~ "^${vpath}/" ]]; then rm $bin; fi
                done
            done
        else
            pipz uninstall $projects_home/*(/:t)
        fi
    ;;
    'upgrade')
        if [[ ${@:2} ]]; then
            pipusall $projects_home/${^@:2}
        else
            pipusall $projects_home/*(/N)
        fi
    ;;
    'list')
        print -rP "projects are in %F{cyan}${projects_home/#~/~}%f"
        print -rP "venvs are in %F{cyan}${${VENVS_WORLD}/#~/~}%f"
        print -rP "apps are exposed at %F{cyan}${bins_home/#~/~}%f"
        print -rP $bins_home/*(@N:t)
        local cells=("%F{cyan}%BCommand%b%f" "%F{cyan}%BPackage%b%f" "%F{cyan}%BRuntime%b%f")
        cells+=(${(f)"$(zargs -rl -P $PROCS -- $bins_home/*(@N) -- __pipzlistrow $projects_home)"})
        if [[ $#cells -gt 3 ]]; then
            print -rPaC 3 $cells | head -n 1
            print -rPaC 3 $cells | tail -n +2 | sort
        fi
    ;;
    'reinstall')
        local pkgs=(${${@:2}:-$projects_home/*(/N:t)})
        pipz uninstall $pkgs
        pipz install $pkgs
    ;;
    'inject')
        cd $projects_home/$2 || return 1
        local vbinpath="$(venvs_path)/venv/bin/"
        local blacklist=(${vbinpath}*(N:t))
        envin
        pipacs ${@:3}
        envout
        local bins=(${vbinpath}*(N:t))
        bins=(${bins:|blacklist})
        bins=(${(f)"$(print -rl $bins | fzf --reverse -m -0 -1 --prompt='['$2'] Which scripts should be added to the path? Select more than one with <tab>.')"})
        for bin in $bins; do vpylauncherfrom . $bin $bins_home; done
    ;;
    'runpip')
        vpyfrom $projects_home/$2 pip ${@:3}
    ;;
    'runpkg')
        local pkg=$2
        local cmd=(${@:3})
        local projdir=${TMPPREFIX}_pipz/${pkg}
        local vpath=$(venvs_path $projdir)
        local venv=${vpath}/venv
        local bin=${venv}/bin/$cmd[1]
        if [[ ! -f $bin || ! -x $bin ]]; then
            [[ -d $venv ]] || python3 -m venv $venv
            ln -sfn $projdir ${vpath}/project
            . $venv/bin/activate
            pipi $pkg -q
            envout
        fi
        ${venv}/bin/${cmd}
    ;;
    *)
        zpy pipz
    ;;
    esac
}
