# path of folder containing all project-venvs (venvs_path) folders
# each project is linked to one or more of:
# <VENVS_WORLD>/<`venvs_path proj-dir`>/{venv,venv2,venvPyPy}
VENVS_WORLD=${XDG_DATA_HOME:-~/.local/share}/venvs

# syntax highlighter, reading stdin
_hlt () {  # <syntax>
    # recommended themes: aiseered, base16/flat, moria, oxygenated
    ((( $+commands[highlight] )) && highlight -O truecolor -s moria -S $1) ||
    ((( $+commands[bat]       )) && bat -l $1 -p)                          ||
                                    cat -
}
# pipe pythonish syntax through this to make it colorful
alias hpype="_hlt py"

# print description and arguments for all or specified functions
# to see actual function contents, use `which <funcname>`
zpy () {  # [zpy-function [python.zshrc]]
    local zpyzshrc="${2:-$HOME/.python.zshrc}"
    if [[ "$#" -gt 0 ]]; then
        pcregrep -Mh '(^[^\n]+\n?)*^(alias '$1'=|('$1' \(\)))\n?([^\n]+\n?)*' $zpyzshrc \
        | grep -Ev '^ |}' \
        | uniq \
        | sed -E 's/([^ \n]+) \(\) \{([^\}]*\})?(.*)/\1\3/g' \
        | sed -E 's/^alias ([^=]+).+(  # .+)?/\1\2/g' \
        | _hlt zsh
    else
        pcregrep '^(alias|([^ \n]+ \(\))|#|$)' $zpyzshrc \
        | uniq \
        | sed -E 's/([^ \n]+) \(\) \{([^\}]*\})?(.*)/\1\3/g' \
        | sed -E 's/^alias ([^=]+).+(  # .+)?/\1\2/g' \
        | _hlt zsh
    fi
}

# get path of folder containing all venvs for the current folder or specified project path
venvs_path () {  # [proj-dir]
    ((( $+commands[md5sum] )) && print "${VENVS_WORLD}/${$(print -n ${${1:-${PWD}}:P} | md5sum)%% *}") ||
                                 print "${VENVS_WORLD}/$(md5 -qs ${${1:-${PWD}}:P})"
}

# start REPL
alias i="ipython"
alias i2="ipython2"

# install packages
alias pipi="pip install -U"  # <req> [req...]

# compile requirements.txt files from all found or specified requirements.in files (compile)
pipc () {  # [reqs-in...]
    for reqsin in ${@:-*requirements.in(N)}; do
        print -P "%F{cyan}> compiling $reqsin -> ${reqsin:r}.txt . . .%f"
        pip-compile --no-header "$reqsin" 2>&1 | hpype
    done
}
# compile with hashes
pipch () {  # [reqs-in...]
    for reqsin in ${@:-*requirements.in(N)}; do
        print -P "%F{cyan}> compiling $reqsin -> ${reqsin:r}.txt . . .%f"
        pip-compile --no-header --generate-hashes "$reqsin" 2>&1 | hpype
    done
}

# install packages according to all found or specified requirements.txt files (sync)
pips () {  # [reqs-txt...]
    local reqstxts=(${@:-*requirements.txt(N)})
    if [[ $reqstxts ]]; then
        print -P "%F{cyan}> syncing env <- $reqstxts . . .%f"
        pip-sync $reqstxts
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

# add loose requirements to [<category>-]requirements.in (add)
_pipa () {  # <category> <req> [req...]
    local reqsin="requirements.in"
    [[ $1 ]] && reqsin="$1-requirements.in"
    print -P "%F{cyan}> appending -> $reqsin . . .%f"
    printf "%s\n" "${@:2}" >> "$reqsin"
    hpype < "$reqsin"
}
alias pipa="_pipa ''"  # <req> [req...]
alias pipabuild="_pipa build"  # <req> [req...]
alias pipadev="_pipa dev"  # <req> [req...]
alias pipadoc="_pipa doc"  # <req> [req...]
alias pipapublish="_pipa publish"  # <req> [req...]
alias pipatest="_pipa test"  # <req> [req...]

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

# recompile *requirements.txt with upgraded versions of all or specified packages (upgrade)
pipu () {  # [req...]
    local reqs=($@)
    for reqsin in *requirements.in(N); do
        print -P "%F{cyan}> upgrading ${reqsin:r}.txt <- $reqsin . . .%f"
        if [[ "$#" -gt 0 ]]; then
            pip-compile --no-header ${${@/*/-P}:^reqs} $reqsin 2>&1 | hpype
            pipc $reqsin  # can remove if https://github.com/jazzband/pip-tools/issues/759 gets fixed
        else
            pip-compile --no-header -U $reqsin 2>&1 | hpype
        fi
    done
}
# upgrade with hashes
pipuh () {  # [req...]
    local reqs=($@)
    for reqsin in *requirements.in(N); do
        print -P "%F{cyan}> upgrading ${reqsin:r}.txt <- $reqsin . . .%f"
        if [[ "$#" -gt 0 ]]; then
            pip-compile --no-header --generate-hashes ${${@/*/-P}:^reqs} $reqsin 2>&1 | hpype
            pipch $reqsin  # can remove if https://github.com/jazzband/pip-tools/issues/759 gets fixed
        else
            pip-compile --no-header -U --generate-hashes $reqsin 2>&1 | hpype
        fi
    done
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

# activate venv for the current folder and install requirements, creating venv if necessary
_envin () {  # <venv-name> <venv-init-cmd> [reqs-txt...]
    local vpath="$(venvs_path)"
    local venv="$vpath/$1"
    print -P "%F{cyan}> entering venv @ ${venv/#$HOME/~} . . .%f"
    [[ -d $venv ]] || eval $2 $venv
    ln -sfn "$PWD" "$vpath/project"
    . $venv/bin/activate
    pip install -qU pip pip-tools
    rehash
    pips "${@:3}"
}
alias envin="_envin venv 'python3 -m venv'"  # [reqs-txt...]
alias envin2="_envin venv2 virtualenv2"  # [reqs-txt...]
alias envinpypy="_envin venvPyPy 'pypy3 -m venv'"  # [reqs-txt...]

# activate without installing anything
activate () {  # [proj-dir]
    . $(venvs_path ${1:-"$(pwd)"})/venv/bin/activate
}
activatefzf () {
    activate "$(printf "%s\n" ${XDG_DATA_HOME:-~/.local/share}/venvs/*/project(:P) | fzf --reverse)"
}
# deactivate
alias envout="deactivate"

# get path of python for the given script's folder's associated venv
_whichvpy () {  # <venv-name> <script>
    echo "$(venvs_path ${2:P:h})/$1/bin/python"
}
alias whichvpy="_whichvpy venv"  # <script>

# run script with its folder's associated venv
_vpy () {  # <venv-name> <script> [script-arg...]
    $(_whichvpy $1 $2) ${@:2}
}
alias vpy="_vpy venv"  # <script> [script-arg...]
alias vpy2="_vpy venv2"  # <script> [script-arg...]
alias vpypy="_vpy venvPyPy"  # <script> [script-arg...]

# get path of project for the activated venv
whichpyproj () {
    echo ${"$(which python)":h:h:h}/project(N:P)
}

# prepend each script with a shebang for its folder's associated venv python
# if vpy exists in the PATH, #!/path/to/vpy will be used instead
# also ensure the script is executable
_vpyshebang () {  # <venv-name> <script> [script...]
    local vpybin
    for script in ${@:2}; do
        chmod +x $script
        vpybin=$(whence -p vpy) || vpybin="$(_whichvpy $1 $script)"
        sed -i'' "1i\
#!${vpybin}" $script
    done
}
alias vpyshebang="_vpyshebang venv"  # <script> [script...]
alias vpy2shebang="_vpyshebang venv2"  # <script> [script...]
alias vpypyshebang="_vpyshebang venvPyPy"  # <script> [script...]

# run script from a given project folder's associated venv's bin folder
_vpyfrom () {  # <venv-name> <proj-dir> <script-name> [script-arg...]
    $(venvs_path $2)/$1/bin/$3 ${@:4}
}
alias vpyfrom="_vpyfrom venv"  # <proj-dir> <script-name> [script-arg...]
alias vpy2from="_vpyfrom venv2"  # <proj-dir> <script-name> [script-arg...]
alias vpypyfrom="_vpyfrom venvPyPy"  # <proj-dir> <script-name> [script-arg...]

# generate an external launcher for a script in a given project folder's associated venv's bin folder
vpylauncherfrom () {  # <proj-dir> <script-name> <launcher-dest>
    if [[ -d $3 ]]; then
        vpylauncherfrom $1 $2 $3/$2
    elif [[ -e $3 ]]; then
        print -P "%F{red}> ${3/#$HOME/~} exists%f"
        return 1
    else
        printf "%s\n" "#!/bin/sh" "exec $(venvs_path $1)/venv/bin/$2 \"\$@\"" > $3
        chmod +x $3
    fi
}

# delete venvs for project folders which no longer exist
prunevenvs () {
    local orphaned_venv
    for proj in "${VENVS_WORLD}/"*"/project"(:P); do
        if [[ ! -d $proj ]]; then
            orphaned_venv=$(venvs_path $proj)
            printf "%s\n" "Missing: ${proj/#$HOME/~}" "Orphan: $(du -hs $orphaned_venv)"
            read -q "?Delete orphan [yN]? "
            [[ $REPLY = 'y' ]] && rm -r $orphaned_venv
            printf "%s\n" '' ''
        fi
    done
}

# pip list -o for all projects
pipcheckold () {
    for proj in "${VENVS_WORLD}/"*"/project"(:P); do
        if [[ -d $proj ]]; then
            print -P "\n%F{cyan}> checking ${proj/#$HOME/~} . . .%f"
            vpyfrom $proj pip list -o --format freeze | grep -v "^setuptools=" | hpype
        fi
    done
}

# pipus for all or specified projects
pipusall () {  # [proj-dir...]
    for proj in ${@:-"${VENVS_WORLD}/"*"/project"(:P)}; do
        if [[ -d $proj ]]; then
            print -P "\n%F{cyan}> visiting ${proj/#$HOME/~} . . .%f"
            cd $proj
            activate
            pipus
            deactivate
            cd - 1> /dev/null
        fi
    done
}

# inject loose requirements.in dependencies into pyproject.toml
# run either from the folder housing pyproject.toml, or one below
# to categorize, name files <category>-requirements.in
pypc () {
    pip install -qU tomlkit || print -P "%F{yellow}> You probably want to activate a venv with 'envin', first%f"
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
        print(f'\033[96m> injecting {reqsin} -> {pyproject} . . .\033[0m')
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
_get_sublp () {
    local spfile
    local spfiles=(*.sublime-project(N))
    if [[ ! $spfiles ]]; then
        spfile="${PWD:t}.sublime-project"
        print '{}' > $spfile
    else
        spfile=$spfiles[1]
    fi
    printf $spfile
}

# specify the venv interpreter in a new or existing sublime text project file
vpysublp () {
    local stp=$(_get_sublp)
    local pypath=$(venvs_path)/venv/bin/python
    print -P "%F{cyan}> writing interpreter ${pypath/#$HOME/~} -> ${stp/#$HOME/~} . . .%f"
    python -c "
from pathlib import Path
from json import loads, dumps
spfile = Path('''${stp}''')
sp = loads(spfile.read_text())
sp.setdefault('settings', {})
sp['settings']['python_interpreter'] = '''$(venvs_path)/venv/bin/python'''
spfile.write_text(dumps(sp, indent=4))
    "
}

# launch a new or existing sublime text project, setting venv interpreter
sublp () {  # [subl-arg...]
    vpysublp
    subl --project "$(_get_sublp)" $@
}
