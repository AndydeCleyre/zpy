autoload -Uz zargs
zmodload -F zsh/files b:zf_chmod

ZPYSRC=${0:P}
ZPYPROCS=${${$(nproc 2>/dev/null):-$(sysctl -n hw.logicalcpu 2>/dev/null)}:-4}

export ZPY_VENVS_WORLD=${XDG_DATA_HOME:-~/.local/share}/venvs
## Each project is associated with one or more of:
## $ZPY_VENVS_WORLD/<hash of proj-dir>/{venv,venv2,venv-pypy,venv-<pyver>}
## which is also:
## $(venvs_path <proj-dir>)/{venv,venv2,venv-pypy,venv-<pyver>}

## Syntax highlighter, reading stdin.
.zpy_hlt () {  # <syntax>
    emulate -L zsh
    [[ $1 ]] || return 1
    rehash
    if [[ $1 == diff ]]; then
        local diffhi
        for diffhi in \
            $commands[delta] \
            $commands[diff-so-fancy] \
            $commands[diff-highlight] \
            /usr/local/opt/git/share/git-core/contrib/diff-highlight/diff-highlight \
            /usr/local/share/git-core/contrib/diff-highlight/diff-highlight \
            /usr/share/doc/git/contrib/diff-highlight \
            /usr/share/git-core/contrib/diff-highlight \
            /usr/share/git/diff-highlight/diff-highlight
        do
            if [[ -x $diffhi ]]; then
                # delta will use BAT_THEME
                BAT_THEME=${BAT_THEME:-ansi-dark} \
                $diffhi
                return
            fi
        done
    fi
    if (( $+commands[highlight] )); then  # recommended themes: aiseered, darkplus, oxygenated
        local lines=(${(f)"$(highlight --version)"})
        local version_words=(${(z)lines[1]})
        if [[ $version_words[-1] -ge 3.56 ]]; then
            HIGHLIGHT_OPTIONS=${HIGHLIGHT_OPTIONS:-'-s darkplus'} \
            highlight --no-trailing-nl=empty-file -O truecolor --stdout -S $1
        else
            # TODO: Consider dropping this workaround and the version check
            # whenever most distros package highlight >=3.56
            local content=$(<&0)
            if [[ $content ]]; then
                HIGHLIGHT_OPTIONS=${HIGHLIGHT_OPTIONS:-'-s darkplus'} \
                highlight -O truecolor --stdout -S $1 <<<$content
            fi
        fi
    elif (( $+commands[bat] )); then  # recommended themes: ansi-dark, zenburn
        BAT_THEME=${BAT_THEME:-ansi-dark} \
        bat --color always --paging never -p -l $1
    elif (( $+commands[batcat] )); then
        BAT_THEME=${BAT_THEME:-ansi-dark} \
        batcat --color always --paging never -p -l $1
    else
        >&1
    fi
}

## zpy, but never highlight
.zpy () {  # [<zpy-function>...]
    # TODO: pure zsh implementation, without pcregrep/pcre2grep/rg?
    emulate -L zsh -o extendedglob
    local cmds_pattern='^(?P<predoc>\n?(# .*\n)*)(alias (?P<aname>[^=]+)="[^"]+"|(?P<fname>[^._ \n][^ \n]+) \(\) \{)(  #(?P<usage> .+))?'
    local subcmd_pattern='.*  # (?P<usage>.*)  ## subcmd: <CMD> <SUBCMD>(?P<postdoc>\n( *# [^\n]+\n)*)'
    if (( $+commands[pcre2grep] )); then
        local cmd_doc=(pcre2grep -M -O '$1$4$5$7')
        local subcmd_doc=(pcre2grep -M -O '$1$2')
    elif (( $+commands[pcregrep] )); then
        local cmd_doc=(pcregrep -M -o1 -o4 -o5 -o7)
        local subcmd_doc=(pcregrep -M -o1 -o2)
    elif (( $+commands[rg] )); then
        local cmd_doc=(rg --no-config --color never -NU -r '$predoc$aname$fname$usage')
        local subcmd_doc=(rg --no-config --color never -NU -r '$usage$postdoc')
    else
        print -lrPu2 '%F{red}> zpy documentation functions require one of:' \
            'rg (ripgrep)' 'pcre2grep (pcre2/pcre2-tools)' 'pcregrep (pcre/pcre-tools)%f'
        return 1
    fi
    if [[ $# -eq 0 ]]; then  # all commands
        print -r -- ${"$(
            $cmd_doc $cmds_pattern $ZPYSRC
        )"##[[:space:]]#}
    else  # specified commands & subcommands
        local cmd subcmd lines
        local -A rEpLy
        for 1; do
            if (( ! ${1[(I) ]} )); then  # "<cmd>"
                print -r -- ${"$(
                    $cmd_doc ${(S)cmds_pattern//name>*\)/name>$1)} $ZPYSRC
                )"##[[:space:]]#}
            else  # "<cmd> <subcmd>"
                cmd=${${(z)1}[1]}
                subcmd=${${(z)1}[2]}
                $cmd subcommands
                print -r "# ${rEpLy[$subcmd]}"
                lines=(${(f)"$(
                    $subcmd_doc ${${subcmd_pattern:gs/<CMD>/$cmd}:gs/<SUBCMD>/$subcmd} $ZPYSRC
                )"})
                lines[1]="$cmd $subcmd $lines[1]"
                print -rl -- ${lines##[[:space:]]#}
            fi
            if [[ $1 != ${@[-1]} ]]; then print; fi
        done
    fi
}

# Print description and arguments for all or specified functions.
zpy () {  # [<zpy-function>...]
    emulate -L zsh
    if [[ $1 == --help ]]; then zpy $0; return; fi
    .zpy $@ | .zpy_hlt zsh
    local rets=($pipestatus)
    if (( rets[0] )); then return $rets[0]; fi
    if (( rets[1] )); then return $rets[1]; fi
}

.zpy_path_hash () {  # <path>
    emulate -L zsh
    unset REPLY
    [[ $1 ]] || return 1
    if (( $+commands[md5sum] )); then
        REPLY="${$(md5sum =(<<<${1:P}))%% *}"
    else
        REPLY="$(md5 -qs ${1:P})"
    fi
}

.zpy_venvs_path () {  # [<proj-dir>]
    emulate -L zsh
    unset REPLY
    .zpy_path_hash ${${1:-$PWD}:P}
    REPLY="${ZPY_VENVS_WORLD}/${REPLY}"
}

.zpy_chooseproj () {
    emulate -L zsh
    unset REPLY
    local projdirs=(${ZPY_VENVS_WORLD}/*/project(@N-/:P))
    REPLY=$(print -rln -- $projdirs | fzf --reverse -0 -1)
}

# Get path of folder containing all venvs for the current folder or specified proj-dir.
# Pass -i to interactively choose the project.
venvs_path () {  # [-i|<proj-dir>]
    emulate -L zsh
    if [[ $1 == --help ]]; then zpy $0; return; fi
    local REPLY
    if [[ $1 == -i ]]; then
        .zpy_chooseproj
        venvs_path "$REPLY"
    else
        .zpy_venvs_path $@
        print -rn -- $REPLY
    fi
}

.zpy_please_activate () {  # [not-found-item]
    emulate -L zsh
    [[ $1 ]] && print -rPu2 "%F{red}> $1 not found!%f"
    print -rPu2 \
        '%F{yellow}> You probably want to activate a venv with 'activate' (or 'a8'), first.' \
        "%B::%b ${${${PWD:P}/#~\//~/}/%${PWD:t}/%B${PWD:t}%b}%f"
    # read -q "?Continue anyway [yN]? "
    # [[ $REPLY == y ]] && rm -rf $orphaned_venv
            # print '\n'
}

# Install and upgrade packages.
pipi () {  # [--no-upgrade] <pkgspec>...
    emulate -L zsh
    if [[ $1 == --help ]]; then zpy $0; return; fi
    [[ $VIRTUAL_ENV ]] || .zpy_please_activate venv
    local upgrade=-U
    if [[ $1 == --no-upgrade ]]; then unset upgrade; shift; fi
    if [[ ! $1 ]]; then zpy $0; return 1; fi
    python -m pip --disable-pip-version-check install $upgrade $@
    local ret=$?
    rehash
    if (( ret )); then
        print -rPnu2 "%F{red}> FAILED: $0 $@ %B::%b $VIRTUAL_ENV%f"
        if [[ -L ${VIRTUAL_ENV:h}/project ]]; then
            print -rPu2 ' %B::%b' ${VIRTUAL_ENV:h}/project(:P:t)
        else
            print
        fi
        return ret
    fi
}

# Install packages according to all found or specified requirements.txt files (sync).
pips () {  # [<reqs-txt>...]
    emulate -L zsh
    if [[ $1 == --help ]]; then zpy $0; return; fi
    rehash
    if (( ! $+commands[pip-sync] )); then .zpy_please_activate pip-sync; return 1; fi
    local reqstxts=(${@:-*requirements.txt(N)})
    if [[ $reqstxts ]]; then
        print -rPu2 \
            '%F{cyan}> %B%F{green}syncing%b%F{cyan} env' \
            "%B<-%b $reqstxts" \
            "%B::%b ${${${PWD:P}/#~\//~/}/%${PWD:t}/%B${PWD:t}%b}%f"
        pip-sync -q --pip-args --disable-pip-version-check $reqstxts
        local ret=$? reqstxt
        for reqstxt in $reqstxts; do        # can remove if pip-tools #896 is resolved
            pipi --no-upgrade -qr $reqstxt  # (by merging pip-tools #907)
            (( ? )) && ret=1                #
        done                                #
        rehash
        if (( ret )); then
            print -rPu2 "%F{red}> FAILED: $0 $@%f"
            return ret
        fi
    fi
}

.zpy_pipc () {  # [--faildir <faildir>] <reqs-in> [<pip-compile-arg>...]
    emulate -L zsh
    rehash
    if (( ! $+commands[pip-compile] )); then .zpy_please_activate pip-compile; return 1; fi
    local faildir
    if [[ $1 == --faildir ]]; then faildir=${2:a}; shift 2; fi
    [[ $1 ]] || return 1
    local reqsin=$1; shift
    local reqstxt=${reqsin:r}.txt outswitch
    for outswitch in -o --output-file; do
        if (( ${@[(I)$outswitch]} )); then
            reqstxt=${@[$@[(i)$outswitch]+1]}
            break
        fi
    done
    print -rPu2 \
        "%F{cyan}> %F{yellow}compiling%F{cyan} $reqsin" \
        "%B->%b ${reqstxt}" \
        "%B::%b ${${${PWD:P}/#~\//~/}/%${PWD:t}/%B${PWD:t}%b}%f"
    # Set cache dir for concurrency (see pip-tools #1083):
    local REPLY
    .zpy_path_hash $reqstxt
    local reqstxt_hash=$REPLY

    PIP_TOOLS_CACHE_DIR=${VIRTUAL_ENV:-$(mktemp -d)}/zpy-cache/${reqstxt_hash} \
    pip-compile --no-header -o $reqstxt $@ $reqsin 2>&1 | .zpy_hlt ini
    local badrets=(${pipestatus:#0})
    [[ $badrets ]] && [[ $faildir ]] && touch $faildir/${PWD:t}
    return $badrets[1]
}

.zpy_pipu () {  # [--faildir <faildir>] <reqsin> [<pkgspec>...] [-- <pip-compile-arg>...]
    emulate -L zsh
    local zpypipc_args pipcompile_args=()
    if [[ $1 == --faildir ]]; then zpypipc_args=($1 $2); shift 2; fi
    if (( ${@[(I)--]} )); then
        pipcompile_args+=(${@[$@[(i)--]+1,-1]})
        shift -p "$(( $#pipcompile_args+1 ))"
    fi
    [[ $1 ]] || return 1
    local reqsin=$1; shift
    local reqs=($@)
    local reqstxt=${reqsin:r}.txt
    local before=$(mktemp)
    cp $reqstxt $before 2>/dev/null || true

    pipi -q pip-tools

    .zpy_pipc $zpypipc_args $reqsin -q ${${${reqs/*/-P}:^reqs}:--U} $pipcompile_args
    local ret=$?

    if [[ -r $before && -r $reqstxt ]]; then
        local lines
        lines=(${(f)"$(
            diff -wu \
            -L "${${reqstxt:P}/#~\//~/} then" $before \
            -L "${${reqstxt:P}/#~\//~/} now" $reqstxt \
        )"})
        if (( $? )); then
            lines=(${(M)lines:#(-|+|@)*})
            .zpy_hlt diff <<<${(F)lines}
        fi
    fi
    rm -f $before
    return ret
}

# Compile requirements.txt files from all found or specified requirements.in files (compile).
# Use -h to include hashes, -u dep1,dep2... to upgrade specific dependencies, and -U to upgrade all.
pipc () {  # [-h] [-U|-u <pkgspec>,...] [<reqs-in>...] [-- <pip-compile-arg>...]
    emulate -L zsh
    # TODO: follow pip-tools progress: #1047 #908 #891
    if [[ $1 == --help ]]; then zpy $0; return; fi
    local gen_hashes upgrade upgrade_csv pipcompile_args=()
    while [[ $1 == -h || $1 == -U || $1 == -u ]]; do
        if [[ $1 == -h ]]; then gen_hashes=--generate-hashes; shift; fi
        if [[ $1 == -U ]]; then upgrade=1; shift; fi
        if [[ $1 == -u ]]; then upgrade=1; upgrade_csv=$2; shift 2; fi
    done
    if (( ${@[(I)--]} )); then
       pipcompile_args+=(${@[$@[(i)--]+1,-1]})
       shift -p "$(( $#pipcompile_args+1 ))"
    fi
    local faildir=$(mktemp -d)
    if [[ $upgrade ]]; then
        zargs -P $ZPYPROCS -ri___ \
        -- ${@:-*requirements.in(N)} \
        -- .zpy_pipu --faildir $faildir ___ ${(s:,:)upgrade_csv} -- $gen_hashes $pipcompile_args
    else
        zargs -P $ZPYPROCS -ri___ \
        -- ${@:-*requirements.in(N)} \
        -- .zpy_pipc --faildir $faildir ___ $gen_hashes $pipcompile_args
    fi
    local failures=($faildir/*(N:t))
    rm -rf $faildir
    if [[ $failures ]]; then
        print -lrPu2 \
            '%F{red}> Problems compiling:' \
            ${failures}%f
        zpy $0
        return 1
    fi
}

# Compile, then sync.
# Use -h to include hashes, -u dep1,dep2... to upgrade specific dependencies, and -U to upgrade all.
pipcs () {  # [-h] [-U|-u <pkgspec>,...] [<reqs-in>...] [-- <pip-compile-arg>...]
    emulate -L zsh
    if [[ $1 == --help ]]; then zpy $0; return; fi
    pipc $@
    local ret=$?
    if (( ret )); then
        print -rPu2 "%F{red}> FAILED: $0 $@%f"
        return ret
    fi
    while [[ $1 == -h || $1 == -U || $1 == -u ]]; do
        [[ $1 == -h ]] && shift
        [[ $1 == -U ]] && shift
        [[ $1 == -u ]] && shift 2
    done
    if (( ${@[(I)--]} )); then
       local pipcompile_args=(${@[$@[(i)--]+1,-1]})
       shift -p "$(( $#pipcompile_args+1 ))"
    fi
    pips ${^@:r}.txt
}

# Add loose requirements to [<category>-]requirements.in (add).
pipa () {  # [-c <category>] <pkgspec>...
    emulate -L zsh
    if [[ $1 == --help ]]; then zpy $0; return; fi
    local reqsin=requirements.in
    if [[ $1 == -c ]]; then reqsin=${2}-requirements.in; shift 2; fi
    if [[ ! $1 ]]; then zpy $0; return 1; fi
    print -rPu2 \
        '%F{cyan}> %F{magenta}appending' \
        "%F{cyan}%B->%b $reqsin" \
        "%B::%b ${${${PWD:P}/#~\//~/}/%${PWD:t}/%B${PWD:t}%b}%f"
    print -rl -- $@ >> $reqsin
    .zpy_hlt ini <$reqsin
}

# Add to requirements.in, then compile it to requirements.txt (add, compile).
# Use -c to affect categorized requirements, and -h to include hashes.
pipac () {  # [-c <category>] [-h] <pkgspec>... [-- <pip-compile-arg>...]
    emulate -L zsh
    if [[ $1 == --help ]]; then zpy $0; return; fi
    local catg gen_hashes reqsin=requirements.in pipcompile_args=()
    while [[ $1 == -c || $1 == -h ]]; do
        if [[ $1 == -c ]]; then catg=$2; shift 2; fi
        if [[ $1 == -h ]]; then gen_hashes=--generate-hashes; shift; fi
    done
    if (( ${@[(I)--]} )); then
       pipcompile_args+=(${@[$@[(i)--]+1,-1]})
       shift -p "$(( $#pipcompile_args+1 ))"
    fi
    if [[ ! $1 ]]; then zpy $0; return 1; fi
    if [[ $catg ]]; then
        pipa -c $catg $@
        reqsin=${catg}-requirements.in
    else
        pipa $@
    fi
    pipc $reqsin -- $gen_hashes $pipcompile_args
}

# Add to requirements.in, compile it to requirements.txt, then sync to that (add, compile, sync).
# Use -c to affect categorized requirements, and -h to include hashes.
pipacs () {  # [-c <category>] [-h] <pkgspec>... [-- <pip-compile-arg>...]
    emulate -L zsh
    if [[ $1 == --help ]]; then zpy $0; return; fi
    pipac $@
    local ret=$?
    if (( ret )); then
        print -rPu2 "%F{red}> FAILED: $0 $@%f"
        return ret
    fi
    [[ $1 == -h ]] && shift
    local reqstxt=requirements.txt
    [[ $1 == -c ]] && reqstxt=${2}-requirements.txt
    pips $reqstxt
}

# View contents of all *requirements*.{in,txt} files in the current or specified folders.
reqshow () {  # [<folder>...]
    emulate -L zsh
    if [[ $1 == --help ]]; then zpy $0; return; fi
    [[ $1 ]] || 1=$PWD
    # for reqsfile in $1/*requirements*.{in,txt}(N); do
        # tail -n +1 $1/*requirements*.{in,txt} | .zpy_hlt ini
    local reqsfile folderfiles
    for 1; do
        folderfiles=($1/*requirements*.{in,txt}(N))
        for reqsfile in $folderfiles; do
            if [[ $reqsfile != ${folderfiles[1]} ]]; then print; fi
            print -r -- '==>' $reqsfile '<=='
            .zpy_hlt ini <$reqsfile
        done
        if [[ $1 != ${@[-1]} ]]; then print; fi
    done
}

.zpy_pyvervenvname () {
    emulate -L zsh
    unset REPLY
    rehash
    if (( ! $+commands[python] )); then
        print -rPu2 '%F{red}> No "python" found in path!%f'
        return 1
    fi
    local name=(${(f)"$(python -V 2>&1)"})
    name=(${(z)name[-1]})
    REPLY=venv-${(j:-:)name:0:2:l:gs/[/}
}

.zpy_envin () {  # <venv-name> <venv-init-cmd...> [-- <reqs-txt>...]
    emulate -L zsh
    [[ $2 && $1 ]] || return 1
    local REPLY
    .zpy_venvs_path
    local vpath=$REPLY

    local venv=$vpath/$1; shift

    local reqstxts=()
    local cmd_end=${@[(I)--]}
    if (( cmd_end )); then
        reqstxts=(${@[$cmd_end+1,-1]})
        shift -p "$(( $#reqstxts+1 ))"
    fi

    local venv_cmd=($@)
    # print -l $venv_cmd

    print -rPu2 \
        '%F{cyan}> %F{green}entering%F{cyan} venv' \
        "%B@%b ${venv/#~\//~/}" \
        "%B::%b ${${${PWD:P}/#~\//~/}/%${PWD:t}/%B${PWD:t}%b}%f"
    [[ -d $venv ]] || $venv_cmd $venv
    local ret=$?
    if (( ret )); then
        print -rPu2 "%F{red}> FAILED: $venv_cmd $venv%f"
        return ret
    fi
    ln -sfn $PWD ${vpath}/project
    . $venv/bin/activate
    pipi -q pip-tools
    pips $reqstxts
}

.zpy_argvenv () {  # 2|pypy|current -> ($venv_name $venv_cmd...)
    emulate -L zsh
    unset reply
    local venv_name venv_cmd=()
    case $1 in
    2)
        venv_name=venv2
        if (( $+commands[virtualenv2] )); then
            venv_cmd=(virtualenv2)
        elif (( $+commands[virtualenv] )); then
            venv_cmd=(virtualenv -p python2)
        else
            venv_cmd=(python2 -m virtualenv)
        fi
    ;;
    pypy)
        venv_name=venv-pypy
        venv_cmd=(pypy3 -m venv)
    ;;
    current)
        local REPLY
        .zpy_pyvervenvname || return
        venv_name=$REPLY
        local major=$(python -c 'from __future__ import print_function; import sys; print(sys.version_info.major)')
        if [[ $major == 3 ]]; then
            venv_cmd=(python -m venv)
        else
            venv_cmd=(python -m virtualenv)
            if (( $+commands[virtualenv] )); then
                venv_cmd=(virtualenv -p python)
            else
                venv_cmd=(python -m virtualenv)
            fi
        fi
    ;;
    *)
        return 1
    ;;
    esac
    reply=($venv_name $venv_cmd)
}

# Activate the venv (creating if needed) for the current folder, and sync its
# installed package set according to all found or specified requirements.txt files.
# In other words: [create, ]activate, sync.
# The interpreter will be whatever 'python3' refers to at time of venv creation, by default.
# Pass --py to use another interpreter and named venv.
envin () {  # [--py 2|pypy|current] [<reqs-txt>...]
    emulate -L zsh
    if [[ $1 == --help ]]; then zpy $0; return; fi
    local venv_name=venv venv_cmd=(python3 -m venv)
    if [[ $1 == --py ]]; then
        local reply
        if ! .zpy_argvenv $2; then zpy $0; return 1; fi
        venv_name=$reply[1]
        venv_cmd=($reply[2,-1])
        shift 2
    fi
    .zpy_envin $venv_name $venv_cmd -- $@
}

# Activate the venv for the current folder or specified project, if it exists.
# Otherwise create, activate, sync.
# Pass -i to interactively choose the project.
# Pass --py to use another interpreter and named venv.
activate () {  # [--py 2|pypy|current] [-i|<proj-dir>]
    emulate -L zsh
    if [[ $1 == --help ]]; then zpy $0; return; fi
    local envin_args=() venv_name=venv interactive ret REPLY
    while [[ $1 == -i || $1 == --py ]]; do
        if [[ $1 == -i ]]; then interactive=1; shift; fi
        if [[ $1 == --py ]]; then
            local reply
            if ! .zpy_argvenv $2; then zpy $0; return 1; fi
            venv_name=$reply[1]
            envin_args=($1 $2)
            shift 2
        fi
    done
    if [[ $interactive ]]; then
        .zpy_chooseproj || return
        activate $envin_args "$REPLY"
        return
    fi
    local projdir=${${1:-$PWD}:P}
    local activation_err=$(mktemp)
    .zpy_venvs_path $projdir
    . "$REPLY/$venv_name/bin/activate" &>$activation_err
    ret=$?
    if [[ $ret == 127 ]]; then
        rm $activation_err
        trap "cd ${(q-)PWD}" EXIT INT
        cd $projdir
        envin $envin_args
        return
    elif (( ! $ret )); then
        rm $activation_err
        pipi -q pip-tools
        # TODO: solve occasional:
        # ERROR: Could not install packages due to an EnvironmentError: [Errno 2] No such file or directory: '/home/andy/.local/share/venvs/xxx/venv/bin/pip-compile'
        return
    fi
    <$activation_err >&2
    rm $activation_err
    return ret
}

# Alias for 'activate'.
alias a8="activate"  # [--py 2|pypy|current] [-i|<proj-dir>]

# Alias for 'deactivate'.
alias envout="deactivate"

# Another alias for 'deactivate'.
alias da8="deactivate"

.zpy_whichvpy () {  # <venv-name> <script>
    emulate -L zsh
    unset REPLY
    [[ $2 && $1 ]] || return 1
    .zpy_venvs_path ${2:a:h}
    REPLY=$REPLY/$1/bin/python
}

# Display path of project for the activated venv.
whichpyproj () {
    emulate -L zsh
    if [[ $1 == --help ]]; then zpy $0; return; fi
    # print -r -- ${${:-=python}:h:h:h}/project(@N:P)
    [[ $VIRTUAL_ENV ]] || return
    print -r -- ${VIRTUAL_ENV:h}/project(@N:P)
}

# Prepend each script with a shebang for its folder's associated venv interpreter.
# If 'vpy' exists in the PATH, '#!/path/to/vpy' will be used instead.
# Also ensure the script is executable.
# --py may be used, same as for envin.
vpyshebang () {  # [--py 2|pypy|current] <script>...
    emulate -L zsh
    if [[ $1 == --help ]]; then zpy $0; return; fi
    local venv_name=venv
    if [[ $1 == --py ]]; then
        local reply
        if ! .zpy_argvenv $2; then zpy $0; return 1; fi
        venv_name=$reply[1]; shift 2
    fi
    if [[ ! $1 ]]; then zpy $0; return 1; fi
    local vpyscript lines shebang REPLY
    [[ $venv_name == venv ]] && vpyscript=$commands[vpy]
    for 1; do
        zf_chmod 0755 $1
        if [[ $vpyscript ]]; then
            shebang="#!${vpyscript}"
        else
            .zpy_whichvpy $venv_name $1
            shebang="#!${REPLY}"
        fi
        lines=("${(@f)$(<$1)}")
        if [[ $lines[1] != $shebang ]]; then
            print -rl -- "${shebang}" "${(@)lines}" > $1
        fi
    done
}

## Run command in a venv-activated subshell for the given project folder.

# Run command in a subshell with <venv>/bin for the given project folder prepended to the PATH.
# Use --cd to run the command from within the project folder.
# --py may be used, same as for envin.
# With --activate, activate the venv (usually unnecessary, and slower).
vrun () {  # [--py 2|pypy|current] [--cd] [--activate] <proj-dir> <cmd> [<cmd-arg>...]
    emulate -L zsh
    if [[ $1 == --help ]]; then zpy $0; return; fi
    local activate_args=() enter do_activate=
    while [[ $1 == --py || $1 == --cd || $1 == --activate ]]; do
        if [[ $1 == --cd ]]; then enter=1; shift; fi
        if [[ $1 == --activate ]]; then do_activate=1; shift; fi
        if [[ $1 == --py ]]; then
            if ! .zpy_argvenv $2; then zpy $0; return 1; fi
            activate_args=($1 $2); shift 2
        fi
    done
    if ! [[ $2 && $1 ]]; then zpy $0; return 1; fi
    local projdir=${1:a}; shift
    (
        set -e
        [[ $enter ]] && cd $projdir
        if [[ $do_activate ]]; then
            activate $activate_args $projdir
        else
            vname=venv
            if [[ $activate_args ]]; then
                .zpy_argvenv $activate_args[2]
                vname=$reply[1]
            fi
            .zpy_venvs_path $projdir
            path=($REPLY/$vname/bin $path)
            # TODO: error if venvs_path/vname doesn't exist?
        fi
        $@
    )
}

# Run script with the python from its folder's venv.
# --py may be used, same as for envin.
vpy () {  # [--py 2|pypy|current] [--activate] <script> [<script-arg>...]
    emulate -L zsh
    if [[ $1 == --help ]]; then zpy $0; return; fi
    local vrun_args=()
    while [[ $1 == --py || $1 == --activate ]]; do
        if [[ $1 == --py ]]; then vrun_args+=($1 $2); shift 2; fi
        if [[ $1 == --activate ]]; then vrun_args+=($1); shift; fi
    done
    if [[ ! $1 ]]; then zpy $0; return 1; fi
    vrun $vrun_args ${1:a:h} python ${1:a} ${@[2,-1]}
}


# Make a launcher script for a command run in a given project's activated venv.
# With --link-only, only create a symlink to <venv>/bin/<cmd>,
# which should already have the venv's python in its shebang line.
vlauncher () {  # [--link-only] [--py 2|pypy|current] <proj-dir> <cmd> <launcher-dest>
    # TODO: Consider replacing --link-only with its inverse, --activate.
    emulate -L zsh
    if [[ $1 == --help ]]; then zpy $0; return; fi
    local linkonly venv_name=venv
    while [[ $1 == --link-only || $1 == --py ]]; do
        if [[ $1 == --link-only ]]; then linkonly=1; shift; fi
        if [[ $1 == --py ]]; then
            local reply
            if ! .zpy_argvenv $2; then zpy $0; return 1; fi
            venv_name=$reply[1]; shift 2
        fi
    done
    if ! [[ $3 && $2 && $1 ]]; then zpy $0; return 1; fi
    local projdir=${1:P} cmd=$2 dest=${3:a}
    [[ -d $dest ]] && dest=$dest/$cmd
    if [[ -e $dest ]]; then
        print -rPu2 \
            "%F{red}> ${dest/#~\//~/} exists!" \
            "%B::%b ${projdir/#~\//~/}%f"
        return 1
    fi
    local REPLY
    .zpy_venvs_path $projdir
    local venv=${REPLY}/${venv_name}

    if [[ $linkonly ]]; then
        local cmdpath=${venv}/bin/${cmd}
        if [[ ! -x $cmdpath ]]; then
            print -rPu2 \
                "%F{red}> ${cmdpath/#~\//~/} is not an existing executable!" \
                "%B::%b ${projdir/#~\//~/}%f"
            return 1
        fi
        ln -s "${cmdpath}" $dest
    else
        print -rl -- '#!/bin/sh -e' ". ${venv}/bin/activate" "exec $cmd \$@" > $dest
        zf_chmod 0755 $dest
    fi
}

# Delete venvs for project folders which no longer exist.
prunevenvs () {  # [-y]
    emulate -L zsh
    if [[ $1 == --help ]]; then zpy $0; return; fi
    local noconfirm=$1 orphaned_venv proj REPLY
    for proj in ${ZPY_VENVS_WORLD}/*/project(@N:P); do
        if [[ ! -d $proj ]]; then
            .zpy_venvs_path $proj
            orphaned_venv=$REPLY
            print -rl "Missing: ${proj/#~\//~/}" "Orphan: $(du -hs $orphaned_venv)"
            if [[ $noconfirm ]]; then
                rm -rf $orphaned_venv
            else
                read -q "?Delete orphan [yN]? " && rm -rf $orphaned_venv
                print '\n'
            fi
        fi
    done
}

.zpy_pipcheckoldcells () {  # [--py 2|pypy|current] <proj-dir>
    emulate -L zsh
    local vname=venv vrun_args=()
    if [[ $1 == --py ]]; then vrun_args+=($1 $2); shift 2; fi
    [[ -d $1 ]] || return 1
    vrun_args+=($1)
    # local REPLY
    # .zpy_venvs_path $1
    local cells=() proj_cell="${${1:P}/#~\//~/}"
    rehash
    if (( $+commands[jq] )); then
        cells=($(
            vrun $vrun_args python -m pip --disable-pip-version-check list -o --format json \
            | jq -r '.[] | select(.name|test("^(setuptools|six|pip|pip-tools)$")|not) | .name,.version,.latest_version'
        ))
    elif (( $+commands[jello] )); then
        cells=($(
            vrun $vrun_args python -m pip --disable-pip-version-check list -o --format json \
            | jello -r '" ".join(" ".join((pkg["name"], pkg["version"], pkg["latest_version"])) for pkg in _ if pkg["name"] not in ("setuptools", "six", "pip", "pip-tools"))'
        ))
    else
        local lines=(${(f)"$(vrun $vrun_args python -m pip --disable-pip-version-check list -o)"})
        lines=($lines[3,-1])
        lines=(${lines:#(setuptools|six|pip|pip-tools) *})
        local line line_cells
        for line in $lines; do
            line_cells=(${(z)line})
            cells+=(${line_cells[1,3]})
        done
    fi
    #    (package, version, latest)
    # -> (package, version, latest, proj-dir)
    local i
    for ((i=3; i<=$#cells; i+=4)); do
        cells[i]+=("$proj_cell")
    done
    print -rl -- $cells
}

# 'pip list -o' for all or specified projects.
pipcheckold () {  # [--py 2|pypy|current] [<proj-dir>...]
    emulate -L zsh
    if [[ $1 == --help ]]; then zpy $0; return; fi
    local extra_args=()
    if [[ $1 == --py ]]; then
        extra_args+=($1 $2)
        shift 2
    fi
    local cells=(
        "%F{cyan}%BPackage%b%f"
        "%F{cyan}%BVersion%b%f"
        "%F{cyan}%BLatest%b%f"
        "%F{cyan}%BProject%b%f"
    )
    cells+=(${(f)"$(
        zargs -P $ZPYPROCS -rl \
        -- ${@:-${ZPY_VENVS_WORLD}/*/project(@N-/)} \
        -- .zpy_pipcheckoldcells $extra_args
    )"})
    if [[ $#cells -gt 4 ]]; then
        print -rPaC 4 -- $cells
    fi
}

.zpy_pipup () {  # [--py 2|pypy|current] [--faildir <faildir>] <proj-dir>
    emulate -L zsh
    local faildir activate_args=()
    while [[ $1 == --faildir || $1 == --py ]]; do
        if [[ $1 == --faildir ]]; then faildir=${2:a}; shift 2; fi
        if [[ $1 == --py ]]; then
            activate_args+=($1 $2)
            shift 2
        fi
    done
    [[ $1 ]] || return 1
    (
        set -e
        cd $1
        activate $activate_args
        pipcs -U
    )
    local ret=$?
    (( ret )) && [[ $faildir ]] && touch $faildir/${1:t}
    return ret
}

# 'pipcs -U' (upgrade-compile, sync) for all or specified projects.
pipup () {  # [--py 2|pypy|current] [<proj-dir>...]
    emulate -L zsh
    if [[ $1 == --help ]]; then zpy $0; return; fi
    local extra_args=()
    if [[ $1 == --py ]]; then
        extra_args+=($1 $2)
        shift 2
    fi
    local faildir=$(mktemp -d)
    zargs -P $ZPYPROCS -rl \
    -- ${@:-${ZPY_VENVS_WORLD}/*/project(@N-/:P)} \
    -- .zpy_pipup $extra_args --faildir $faildir
    local failures=($faildir/*(N:t))
    rm -rf $faildir
    if [[ $failures ]]; then
        print -lrPu2 \
            '%F{red}> Problems upgrading:' \
            ${failures}%f
        return 1
    fi
}

# Inject loose requirements.in dependencies into a flit-flavored pyproject.toml.
# Run either from the folder housing pyproject.toml, or one below.
# To categorize, name files <category>-requirements.in.
pypc () {
    emulate -L zsh
    if [[ $1 == --help ]]; then zpy $0; return; fi
    pipi --no-upgrade -q tomlkit
    local ret=$?
    if (( ret )); then .zpy_please_activate tomlkit; return $ret; fi
    local pyproject=${${:-pyproject.toml}:a}
    [[ -e $pyproject ]] || pyproject=${pyproject:h:h}/pyproject.toml

    python3 -c "
from pathlib import Path
from contextlib import suppress
import os
import re

import tomlkit


def reqs_from_reqsin(reqsin):
    reqsin = Path(os.path.abspath(os.path.expanduser(reqsin)))
    reqs = []
    for line in reqsin.read_text().splitlines():
        if line.startswith('-r '):
            reqs.extend(reqs_from_reqsin((
                reqsin.parent / re.search(r'^-r\s+([^#]+)', line).group(1).rstrip()
            ).resolve()))
            continue
        with suppress(AttributeError):
            reqs.append(
                re.search(r'^(-\S+\s+)*([^#]+)', line).group(2).rstrip()
            )
    return sorted(set(reqs))


suffix = 'requirements.in'
pyproject = Path('''${pyproject}''').absolute()
pyproject_short = re.sub(rf'^{Path.home()}/', '~/', str(pyproject))
if pyproject.is_file():
    reqsins = [*pyproject.parent.glob(f'*/*{suffix}')] + [*pyproject.parent.glob(f'*{suffix}')]
    toml_data = tomlkit.parse(pyproject.read_text())
    for reqsin in reqsins:
        reqsin_short = re.sub(rf'^{Path.home()}/', '~/', str(reqsin))
        print(f'\033[96m> injecting {reqsin_short} -> {pyproject_short}\033[0m')
        pyproject_reqs = reqs_from_reqsin(reqsin)
        print(pyproject_reqs)
        extras_catg = reqsin.name.rsplit(suffix, 1)[0].rstrip('-.')
        if not extras_catg:
            toml_data['tool']['flit']['metadata']['requires'] = pyproject_reqs
        else:
            # toml_data['tool']['flit']['metadata'].setdefault('requires-extra', {})  # enable on close of tomlkit #49
            if 'requires-extra' not in toml_data['tool']['flit']['metadata']:         # remove when #49 is fixed
                toml_data['tool']['flit']['metadata']['requires-extra'] = {}          # remove when #49 is fixed
            toml_data['tool']['flit']['metadata']['requires-extra'][extras_catg] = pyproject_reqs
    pyproject.write_text(tomlkit.dumps(toml_data))
    "
    ret=$?
    .zpy_hlt toml <$pyproject
    return ret
}

## Get a new or existing Sublime Text project file for the working folder.
.zpy_get_sublp () {
    emulate -L zsh
    unset REPLY
    local spfile
    local spfiles=(*.sublime-project(N))
    if [[ ! $spfiles ]]; then
        spfile=${PWD:t}.sublime-project
        print -r '{}' > $spfile
    else
        spfile=$spfiles[1]
    fi
    REPLY=$spfile
}

# Specify the venv interpreter in a new or existing Sublime Text project file for the working folder.
vpysublp () {
    emulate -L zsh
    if [[ $1 == --help ]]; then zpy $0; return; fi
    rehash
    local REPLY
    .zpy_get_sublp
    local stp=$REPLY
    .zpy_venvs_path
    local pypath=${REPLY}/venv/bin/python
    print -rPu2 \
        "%F{cyan}> %F{magenta}writing%F{cyan} interpreter ${pypath/#~\//~/}" \
        "%B->%b ${stp/#~\//~/}" \
        "%B::%b ${${${PWD:P}/#~\//~/}/%${PWD:t}/%B${PWD:t}%b}%f"
    if (( $+commands[jq] )); then
        print -r -- "$(
            jq --arg py $pypath '.settings+={python_interpreter: $py}' $stp
        )" > $stp
    else
        python3 -c "
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
sublp () {  # [<subl-arg>...]
    emulate -L zsh
    if [[ $1 == --help ]]; then zpy $0; return; fi
    vpysublp
    local REPLY
    .zpy_get_sublp
    subl --project "$REPLY" $@
}

.zpy_is_under () {  # <kid_path> <ok_parent>...
    emulate -L zsh
    [[ $2 && $1 ]] || return 1
    local kid=${1:a} folder ancestor; shift
    for 1; do
        folder=$kid
        ancestor=${1:a}
        while [[ $folder != $ancestor && $folder != / ]]; do
            folder=${folder:h}
        done
        [[ $folder == $ancestor ]] && return
    done
    return 1
}

.zpy_pipzlistrow () {  # <projects_home> <bin>
    # TODO: Still a bit slow (roughly 'pip list' * app-count)
    emulate -L zsh -o extendedglob
    [[ $2 && $1 ]] || return 1
    rehash
    local projects_home=${1:a}
    local bin=$2
    local plink=${bin:P:h:h:h}/project
    local pdir=${plink:P}
    if [[ -L $plink ]] && .zpy_is_under $pdir $projects_home; then
        if (( $+commands[jq] )); then
            local piplistline=($(
                vrun $pdir python -m pip --disable-pip-version-check list --pre --format json \
                | jq -r '.[] | select(.name|test("^'${${${pdir:t}//[^[:alnum:].]##/-}:gs/./\\\\.}'$"; "i")) | .name,.version'
            ))
        # elif (( $+commands[jello] )); then
        #     # Slower than the pure ZSH fallback below.
        #     local piplistline=($(
        #         vrun $pdir python -m pip --disable-pip-version-check list --pre --format json \
        #         | jello -lr '[pkg["name"] + " " + pkg["version"] for pkg in _ if pkg["name"].lower() == "'${${pdir:t}//[^[:alnum:].]##/-}'"]'
        #     ))
        else
            local lines=(${(f)"$(
                vrun $pdir python -m pip --disable-pip-version-check list --pre
            )"})
            lines=($lines[3,-1])
            local piplistline=(${(zM)lines:#(#i)${${pdir:t}//[^[:alnum:].]##/-} *})
        fi
        # Preserve the table layout in case something goes surprising and we don't get a version cell:
        piplistline+=('????')

        local pyverlines=(${(f)"$(
            vrun $pdir python -V
        )"})

        # local pyverlines=('DUMMY')

        # This may be a bit faster, but less accurate
        # local venvcfg=${plink:h}/venv/pyvenv.cfg
        # if [[ -r $venvcfg ]]; then
        #     local cfglines=(${(f)"$(<$venvcfg)"})
        #     local pyverlines=(${${(M)cfglines:#version = *}##version = })
        # else
        #     local pyverlines=(${(f)"$(
        #         vrun $pdir python -V
        #     )"})
        # fi

        print -rl -- "${bin:t}" "${piplistline[1,2]}" "${pyverlines[-1]}"
    fi
}

.zpy_pkgspec2name () {  # <pkgspec>
    emulate -L zsh
    unset REPLY
    [[ $1 ]] || return 1
    local pkgspec=${1##*\#egg=} badspec
    # NOTE: this could break on comments, though irrelevant when used by pipz as we do
    # e.g. 'pipz install "<url>#egg=<name>  # hey look at me"'
    if [[ $pkgspec =~ '^(git|hg|bzr|svn)\+' ]]; then
        badspec=1
    else
        REPLY=${${(j: :)${${(s: :)pkgspec:l}:#-*}}%%[ \[<>=#~;@&]*}
    fi
    if [[ $badspec || ! $REPLY ]]; then
        print -rPu2 "%F{red}> Improper pkgspec %F{magenta}$1%f"
        print -rPu2 \
            '%F{red}> See %F{blue}https://www.python.org/dev/peps/pep-0508/#examples%F{red}' \
            'and %F{blue}https://pip.pypa.io/en/stable/reference/pip_install/#vcs-support%f'
        return 1
    fi
}

.zpy_all_replies () {  # <func> <arg>...
    emulate -L zsh
    reply=()
    [[ $2 && $1 ]] || return 1
    local REPLY f=$1; shift
    for 1; do $f $1 || return; reply+=($REPLY); done
}

.zpy_pipzinstallpkg () {  # [--faildir <faildir>] <projects_home> <pkgspec>
    emulate -L zsh
    local faildir
    if [[ $1 == --faildir ]]; then faildir=${2:a}; shift 2; fi
    [[ $2 && $1 ]] || return 1
    local projects_home=${1:a}
    local pkg=$2
    local REPLY
    if ! .zpy_pkgspec2name $pkg; then
        [[ $faildir ]] && touch $faildir/$pkgname
        return 1
    fi
    local pkgname=$REPLY
    mkdir -p ${projects_home}/${pkgname}
    (
        set -e
        cd ${projects_home}/${pkgname}
        rm -f requirements.{in,txt}
        activate
        pipacs $pkg
    )
    (( ? )) && [[ $faildir ]] && touch $faildir/$pkgname
}

.zpy_pipzchoosepkg () {  # [--header <header>] [--multi] <projects_home>  ## <header> default: 'Packages:'
    emulate -L zsh
    local fzf_args=(--reverse -0) fzf_header='Packages:' fzf_prompt='Which package? ' multi
    while [[ $1 == --header || $1 == --multi ]]; do
        if [[ $1 == --header ]]; then fzf_header=$2; shift 2; fi
        if [[ $1 == --multi ]]; then
            fzf_args+=(-m)
            fzf_prompt='Which packages? Choose one with <enter> or more with <tab>. '
            multi=1
            shift
        fi
    done
    if [[ $multi ]]; then
        unset reply
    else
        unset REPLY
        local reply
    fi
    [[ $1 ]] || return 1
    local pkgs=($1/*(/:t))
    reply=(${(f)"$(
        print -rln -- $pkgs \
        | fzf $fzf_args --header=$fzf_header --prompt=$fzf_prompt
    )"})
    [[ $reply ]] || return 1
    if [[ ! $multi ]]; then
        REPLY=$reply[1]
    fi
}

.zpy_pipzunlinkbins () {  # <projects_home> <bins_home> <pkgspec>...
    emulate -L zsh
    [[ $3 && $2 && $1 ]] || return 1
    local projects_home=$1; shift
    local bins_home=$1; shift
    local reply REPLY
    .zpy_all_replies .zpy_pkgspec2name $@ || return 1
    .zpy_all_replies .zpy_venvs_path ${projects_home}/${^reply}
    local vpaths=($reply)
    local binlinks=(${bins_home}/*(@Ne['.zpy_is_under ${REPLY:P} $vpaths']))
    if [[ $binlinks ]]; then
        rm $binlinks
    fi
    rehash
}

.zpy_pipzrmvenvs () {  # <projects_home> <bins_home> <pkgspec>...
    emulate -L zsh
    [[ $3 && $2 && $1 ]] || return 1
    local projects_home=$1; shift
    local bins_home=$1; shift
    local REPLY
    for 1; do
        .zpy_pkgspec2name $1 || return 1
        .zpy_venvs_path ${projects_home}/${REPLY}
        rm -rf $REPLY
    done
}

.zpy_pipzlinkbins () {  # <projects_home> <bins_home> [--[no-]cmd <cmd>,...] [--activate] [--auto1] [--header <fzf_header>] <pkgspec>...
    emulate -L zsh
    local projects_home=$1; shift
    local bins_home=$1; shift
    local bins_whitelist=() bins_blacklist=() linkonly=1 fzf_args=(--reverse -m -0) fzf_header=Installing
    while [[ $1 == --cmd || $1 == --activate || $1 == --no-cmd || $1 == --auto1 || $1 == --header ]]; do
        if [[ $1 == --cmd ]]; then bins_whitelist=(${(s:,:)2}); shift 2; fi
        if [[ $1 == --no-cmd ]]; then bins_blacklist=(${(s:,:)2}); shift 2; fi
        if [[ $1 == --activate ]]; then unset linkonly; shift; fi
        if [[ $1 == --auto1 ]]; then fzf_args+=(-1); shift; fi
        if [[ $1 == --header ]]; then fzf_header=$2; shift 2; fi
    done
    [[ $1 && $bins_home && $projects_home ]] || return 1
    mkdir -p $bins_home
    local bins pkgname projdir vpath bin REPLY
    for 1; do
        .zpy_pkgspec2name $1 || return 1
        pkgname=$REPLY
        projdir=${projects_home}/${pkgname}
        .zpy_venvs_path $projdir
        vpath=$REPLY
        bins=("${vpath}/venv/bin/"*(N:t))
        if [[ $bins_whitelist ]]; then
            bins=(${bins:*bins_whitelist})
        else
            bins=(${bins:|bins_blacklist})
            bins=(${bins:#([aA]ctivate(|.csh|.fish|.ps1)|easy_install(|-<->*)|(pip|python|pypy)(|<->*)|*.so|__pycache__)})
            [[ $pkgname != pip-tools ]] && bins=(${bins:#pip-(compile|sync)})
            [[ $pkgname != wheel ]] && bins=(${bins:#wheel})
            [[ $pkgname != chardet ]] && bins=(${bins:#chardetect})
            bins=(${(f)"$(
                print -rln $bins \
                | fzf $fzf_args --header="$fzf_header $1 . . ." \
                --prompt='Which scripts should be added to the path? Choose one with <enter> or more with <tab>. '
            )"})
        fi
        for bin in $bins; do
            if [[ $linkonly ]]; then
                vlauncher --link-only $projdir $bin $bins_home
            else
                mkdir -p ${vpath}/venv/pipz_launchers
                vlauncher $projdir $bin ${vpath}/venv/pipz_launchers
                ln -s ${vpath}/venv/pipz_launchers/${bin} $bins_home/
            fi
        done
    done
    rehash
}

# Package manager for venv-isolated scripts (pipx clone; py3 only).
pipz () {  # [install|uninstall|upgrade|list|inject|reinstall|cd|runpip|runpkg] [<subcmd-arg>...]
    emulate -L zsh +o promptsubst
    local projects_home=${XDG_DATA_HOME:-~/.local/share}/python
    local bins_home=${${XDG_DATA_HOME:-~/.local/share}:P:h}/bin
    local reply REPLY
    local subcmds=(
        install     "Install apps from PyPI into isolated venvs"
        uninstall   "Remove apps"
        upgrade     "Install newer versions of apps and their dependencies"
        list        "Show each installed app with its version, commands, and Python runtime"
        inject      "Add extra packages to an installed app's isolated venv"
        reinstall   "Reinstall apps, preserving any version specs and package injections"
        cd          "Enter or run a command from an app's project (requirements.{in,txt}) folder"
        runpip      "Run pip from the venv of an installed app"
        runpkg      "Install an app temporarily and run it immediately"
    )
    case $1 in
    subcommands)
        rEpLy=($subcmds)
        return
    ;;
    --help)
        zpy $0
        local i
        for ((i=1; i<$#subcmds; i+=2)); do
            print
            zpy "$0 $subcmds[i]"
        done
        return
    ;;
    install)  # [--cmd <cmd>,...] [--activate] <pkgspec>...  ## subcmd: pipz install
    # Without --cmd, interactively choose.
    # Without --activate, 'vlauncher --link-only' is used.
        if [[ $2 == --help ]]; then zpy "$0 $1"; return; fi
        shift
        local linkbins_args=($projects_home $bins_home --auto1)
        while [[ $1 == --cmd || $1 == --activate ]]; do
            if [[ $1 == --cmd ]]; then linkbins_args+=($1 $2); shift 2; fi
            if [[ $1 == --activate ]]; then linkbins_args+=($1); shift; fi
        done
        if [[ ! $1 ]]; then zpy "$0 install"; return 1; fi
        local faildir=$(mktemp -d)
        zargs -P $ZPYPROCS -rl \
        -- $@ \
        -- .zpy_pipzinstallpkg --faildir $faildir $projects_home
        local failures=($faildir/*(N:t))
        rm -rf $faildir
        # TODO: could skip linkbins for failures, but is that desirable?
        # new array: pkgspec2name each $@
        # filter array: ${arr:|failures}
        .zpy_pipzlinkbins $linkbins_args $@
        if [[ $failures ]]; then
            print -lrPu2 \
                '%F{red}> Problems installing:' \
                ${failures}%f
            return 1
        fi
    ;;
    uninstall)  # [--all|<pkgname>...]  ## subcmd: pipz uninstall
    # Without args, interactively choose.
        if [[ $2 == --help ]]; then zpy "$0 $1"; return; fi
        shift
        if [[ $1 == --all ]]; then pipz uninstall ${projects_home}/*(/:t); return; fi
        local pkgs pkg
        if [[ $@ ]]; then
            pkgs=($@)
        else
            .zpy_pipzchoosepkg --multi --header 'Uninstalling . . .' $projects_home || return 1
            pkgs=($reply)
        fi
        .zpy_pipzunlinkbins $projects_home $bins_home $pkgs
        .zpy_pipzrmvenvs $projects_home $bins_home $pkgs
        local projdir ret=0
        for pkg in $pkgs; do
            .zpy_pkgspec2name $pkg || return 1
            projdir=${projects_home}/${REPLY}
            if [[ -d $projdir ]]; then
                rm -r $projdir
            else
                print -rPu2 "%F{red}> Project not found %B::%b ${projdir/#~\//~/}%f"
                ret=1
            fi
        done
        return ret
    ;;
    upgrade)  # [--all|<pkgname>...]  ## subcmd: pipz upgrade
    # Without args, interactively choose.
        if [[ $2 == --help ]]; then zpy "$0 $1"; return; fi
        shift
        if [[ $1 == --all ]]; then pipz upgrade ${projects_home}/*(/:t); return; fi
        local pkgnames
        if [[ $@ ]]; then
            .zpy_all_replies .zpy_pkgspec2name $@ || return 1
            pkgnames=($reply)
        else
            .zpy_pipzchoosepkg --multi --header 'Upgrading . . .' $projects_home || return 1
            pkgnames=($reply)
        fi
        print -rPu2 \
            '%F{cyan}> creating pipz-list snapshot for post-comparison' \
            "%B::%b ${projects_home/#~\//~/}%f"
        local before=$(mktemp)
        pipz list $pkgnames > $before
        pipup ${projects_home}/${^pkgnames}
        local ret=$?
        local lines
        lines=(${(f)"$(
            diff -wu \
            -L 'pipz then' $before \
            -L 'pipz now' =(pipz list $pkgnames) \
        )"})
        if (( $? )); then
            lines=(${(M)lines:#(-|+|@)*})
            .zpy_hlt diff <<<${(F)lines}
        fi
        rm -f $before
        if (( ret )); then
            print -rPu2 "%F{red}> FAILED: $0 upgrade $@%f"
            return ret
        fi
    ;;
    list)  # [<pkgname>...]  ## subcmd: pipz list
    # Without args, list all installed.
        if [[ $2 == --help ]]; then zpy "$0 $1"; return; fi
        shift
        print -rP "projects %B@%b %F{cyan}${projects_home/#~\//~/}%f"
        print -rP "venvs %B@%b %F{cyan}${ZPY_VENVS_WORLD/#~\//~/}%f"
        print -rP "apps exposed %B@%b %F{cyan}${bins_home/#~\//~/}%f"
        (( ${path[(I)$bins_home]} )) \
        || print -rP "suggestion%B:%b add %F{blue}path=(${bins_home/#~\//~/} \$path)%f to %F{cyan}~/.zshrc%f"
        print
        print -rC 4 -- ${projects_home}/*(/N:t)
        print
        local bins=() venvs_path_whitelist=()
        if [[ $# -gt 0 ]]; then
            .zpy_all_replies .zpy_venvs_path ${projects_home}/${^@:l}
            venvs_path_whitelist=($reply)
        else
            venvs_path_whitelist=($ZPY_VENVS_WORLD)
        fi
        bins=(${bins_home}/*(@Ne['.zpy_is_under ${REPLY:P} $venvs_path_whitelist']))
        local cells=(
            "%F{cyan}%BCommand%b%f"
            "%F{cyan}%BPackage%b%f"
            "%F{cyan}%BRuntime%b%f"
        )
        cells+=(${(f)"$(
            zargs -P $ZPYPROCS -rl \
            -- $bins \
            -- .zpy_pipzlistrow $projects_home
        )"})
        if [[ $#cells -gt 3 ]]; then
            local table=(${(f)"$(print -rPaC 3 -- $cells)"})
            print -- $table[1]
            print -l -- ${(i)table[2,-1]}
        fi
    ;;
    reinstall)  # [--cmd <cmd>,...] [--activate] [--all|<pkgname>...]  ## subcmd: pipz reinstall
    # Without --cmd, interactively choose.
    # Without --activate, 'vlauncher --link-only' is used.
    # Without --all or <pkgspec>, interactively choose.
        if [[ $2 == --help ]]; then zpy "$0 $1"; return; fi
        shift
        local do_all linkbins_args=($projects_home $bins_home --auto1)
        while [[ $1 == --all || $1 == --cmd || $1 == --activate ]]; do
            if [[ $1 == --all ]]; then do_all=1; shift; fi
            if [[ $1 == --cmd ]]; then linkbins_args+=($1 $2); shift 2; fi
            if [[ $1 == --activate ]]; then linkbins_args+=($1); shift; fi
        done
        local pkgs=()
        if [[ $do_all ]]; then
            pkgs=(${projects_home}/*(/N:t))
        elif [[ $@ ]]; then
            pkgs=($@)
        else
            .zpy_pipzchoosepkg --multi --header 'Reinstalling . . .' $projects_home || return 1
            pkgs=($reply)
        fi
        .zpy_pipzunlinkbins $projects_home $bins_home $pkgs
        .zpy_pipzrmvenvs $projects_home $bins_home $pkgs
        rm -f ${projects_home}/${^pkgs}/requirements.txt
        pipz upgrade $pkgs
        .zpy_pipzlinkbins $linkbins_args $pkgs
    ;;
    inject)  # [--cmd <cmd>,...] [--activate] <installed-pkgname> <extra-pkgspec>...  ## subcmd: pipz inject
    # Without --cmd, interactively choose.
    # Without --activate, 'vlauncher --link-only' is used.
        if [[ $2 == --help ]]; then zpy "$0 $1"; return; fi
        shift
        local linkbins_args=($projects_home $bins_home)
        while [[ $1 == --cmd || $1 == --activate ]]; do
            if [[ $1 == --cmd ]]; then linkbins_args+=($1 $2); shift 2; fi
            if [[ $1 == --activate ]]; then linkbins_args+=($1); shift; fi
        done
        linkbins_args+=(--header "Injecting [${(j:, :)@[2,-1]}] ->")
        local projdir=${projects_home}/${1:l}
        if ! [[ $2 && $1 && -d $projdir ]]; then; zpy "$0 inject"; return 1; fi
        .zpy_venvs_path $projdir
        local vpath=$REPLY
        local vbinpath="${vpath}/venv/bin/"
        local blacklist=(${vbinpath}*(N:t))
        (
            set -e
            cd $projdir
            activate
            pipacs ${@[2,-1]}
        )
        if [[ $blacklist ]]; then
            linkbins_args+=(--no-cmd ${(j:,:)blacklist})
        fi
        .zpy_pipzlinkbins $linkbins_args $1
    ;;
    runpip)  # [--cd] <pkgname> <pip-arg>...  ## subcmd: pipz runpip
    # With --cd, run pip from within the project folder.
        if [[ $2 == --help ]]; then zpy "$0 $1"; return; fi
        shift
        local vrun_args=()
        if [[ $1 == --cd ]]; then vrun_args+=($1); shift; fi
        if ! [[ $2 && $1 ]]; then; zpy "$0 runpip"; return 1; fi
        vrun $vrun_args ${projects_home}/${1:l} python -m pip ${@[2,-1]}
    ;;
    runpkg)  # <pkgspec> <cmd> [<cmd-arg>...]  ## subcmd: pipz runpkg
        if [[ $2 == --help ]]; then zpy "$0 $1"; return; fi
        shift
        if ! [[ $2 && $1 ]]; then; zpy "$0 runpkg"; return 1; fi
        local pkg=$1; shift
        .zpy_pkgspec2name $pkg || return 1
        local pkgname=$REPLY
        local projdir=${TMPPREFIX}_pipz/${pkgname}
        .zpy_venvs_path $projdir
        local vpath=$REPLY
        local venv=${vpath}/venv
        [[ -d $venv ]] || python3 -m venv $venv
        ln -sfn $projdir ${vpath}/project
        . $venv/bin/activate
        pipi $pkg -q
        deactivate
        vrun $projdir $@
        # ${venv}/bin/${@}
        # TODO: does anyone need --activate here? Does anyone use this subcmd at all?
    ;;
    cd)  # [<installed-pkgname> [<cmd> [<cmd-arg>...]]]  ## subcmd: pipz cd
    # Without args (or if pkgname is ''), interactively choose.
    # With cmd, run it in the folder, then return to CWD.
        if [[ $2 == --help ]]; then zpy "$0 $1"; return; fi
        shift
        local projdir
        if [[ $1 ]]; then
            projdir=${projects_home}/${1:l}; shift
        else
            .zpy_pipzchoosepkg $projects_home || return 1
            projdir=${projects_home}/${REPLY}
            [[ $2 ]] && shift
        fi
        [[ $1 ]] && trap "cd ${(q-)PWD}" EXIT INT
        cd $projdir
        if [[ $1 ]]; then
            $@
        fi
    ;;
    *)
        zpy $0
        return 1
    ;;
    esac
}

# Make a standalone script for any zpy function.
.zpy_mkbin () {  # <func> <dest>
    emulate -L zsh
    if [[ $1 == --help ]]; then zpy $0; return; fi
    if ! [[ $2 && $1 ]]; then zpy $0; return 1; fi
    local dest=${2:a}
    [[ -d $dest ]] && dest=$dest/$1
    if [[ -e $dest ]]; then
        print -rPu2 "%F{red}> ${dest/#~\//~/} exists!%f"
        return 1
    fi
    print -rl -- '#!/bin/zsh' "$(<$ZPYSRC)" "$1 \$@" > $dest
    zf_chmod 0755 $dest
}

## TODO: is there a standard/common way to include zsh completions in pypi packages?
## Maybe detect presence of any during installation/bin-linking, and integrate with bin-linking and bin-unlinking
## Found examples:
## - *.zsh-completion (td-watson: watson.zsh-completion)
## - *-completion.zsh (twisted: twisted-completion.zsh)
## - zsh.completion (invoke)
## - NOT A COMPLETION: xxh.zsh (xxh-xxh)
## could check for files that start with '#compdef '
## or is this generally better handled by outputs from each program (e.g. pipenv --completion; pip completion -z)?

## TODO: if zpy becomes pip-installable, should add a --completion action? Or a general self-install action, post pip-install?

## Completions
## -----------

_zpy_helpmsg () {  # funcname
    setopt localoptions extendedglob
    local msg=(${(f)"$(.zpy $1)"})
    msg=(${msg//#(#b)([^#]*)/%B$match[1]%b})
    msg=(${msg//#(#b)(\#*)/%F{blue}$match[1]%f})
    _message -r ${(F)msg}
}

_.zpy_mkbin () {
    _zpy_helpmsg ${0[2,-1]}
    local lines=(${(f)"$(.zpy)"})
    local cmds=(${${(M)lines:#[^# ]*}/ *})
    local pipz_cmd
    local -A rEpLy
    pipz subcommands
    for pipz_cmd in ${(k)rEpLy}; do
        cmds+=(${(q-):-"pipz $pipz_cmd"})
    done
    _arguments \
        '(:)--help[Show usage information]' \
        "(--help)1:Function:($cmds)" \
        '(--help)2:Destination:_files'
}
compdef _.zpy_mkbin .zpy_mkbin 2>/dev/null

_activate () {
    _zpy_helpmsg ${0[2,-1]}
    _arguments \
        '(- 1)--help[Show usage information]' \
        '(--help)--py[Use another interpreter and named venv]:Other Python:(2 pypy current)' \
        '(--help 1)-i[Interactively choose a project]' \
        '(-)1:New or Existing Project:_path_files -/'
}
compdef _activate activate 2>/dev/null

_envin () {
    _zpy_helpmsg ${0[2,-1]}
    local context state state_descr line opt_args
    _arguments \
        '(- *)--help[Show usage information]' \
        '(--help)--py[Use another interpreter and named venv]:Other Python:(2 pypy current)' \
        '(-)*: :->reqstxts'
    if [[ $state == reqstxts ]]; then
        local blacklist=(${line//(#m)[\[\]()\\*?#<>~\^\|]/\\$MATCH})
        _arguments \
            '(-)*:requirements.txt:_files -F blacklist -g "*.txt"'
    fi
}
compdef _envin envin 2>/dev/null

_pipa () {
    _zpy_helpmsg ${0[2,-1]}
    local -U catgs=(dev doc test *-requirements.{in,txt}(N))
    catgs=(${catgs%%-*})
    local reply
    .zpy_pypi_pkgs
    local pkgs=($reply)
    _arguments \
        '(- *)--help[Show usage information]' \
        "(--help)-c[Use <category>-requirements.in]:Category:($catgs)" \
        "(-)*:Package Spec:($pkgs)"
}
compdef _pipa pipa 2>/dev/null

for _zpyfn in pipac pipacs; do
    _${_zpyfn} () {
        _zpy_helpmsg ${0[2,-1]}
        local i=$words[(i)--]
        if (( CURRENT > $i )); then
            shift i words
            words=(pip-compile $words)
            (( CURRENT-=i, CURRENT+=1 ))
            _normal -P
            return
        fi
        local -U catgs=(dev doc test *-requirements.{in,txt}(N))
        catgs=(${catgs%%-*})
        local reply
        .zpy_pypi_pkgs
        local pkgs=($reply)
        local context state state_descr line opt_args
        _arguments \
            '(- * :)--help[Show usage information]' \
            "(--help)-c[Use <category>-requirements.in]:Category:($catgs)" \
            '(--help)-h[Include hashes in compiled requirements.txt]' \
            "(--help -c -h)1:Package Spec:($pkgs)" \
            '(--help -c -h)*:Package Spec:->pkgspecs'
        if [[ $state == pkgspecs ]]; then
            _arguments \
                "*:Package Spec:($pkgs)" \
                '(*)--[pip-compile Arguments]:pip-compile Argument: '
        fi
    }
    compdef _${_zpyfn} $_zpyfn 2>/dev/null
done

for _zpyfn in pipcheckold pipup; do
    _${_zpyfn} () {
        _zpy_helpmsg ${0[2,-1]}
        local context state state_descr line opt_args
        _arguments \
            '(* -)--help[Show usage information]' \
            '(--help)--py[Use another interpreter and named venv]:Other Python:(2 pypy current)' \
            '(--help)*: :->projects'
        if [[ $state == projects ]]; then
            local blacklist=(${line//(#m)[\[\]()\\*?#<>~\^\|]/\\$MATCH})
            _arguments \
                "(--help)*:Project:_path_files -F blacklist -/ -g '${ZPY_VENVS_WORLD}/*/project(@N-/:P)'"
        fi
    }
    compdef _${_zpyfn} ${_zpyfn} 2>/dev/null
done

for _zpyfn in pipc pipcs; do
    _${_zpyfn} () {
        _zpy_helpmsg ${0[2,-1]}
        local i=$words[(i)--]
        if (( CURRENT > $i )); then
            shift i words
            words=(pip-compile $words)
            (( CURRENT-=i, CURRENT+=1 ))
            _normal -P
            return
        fi
        local reply
        .zpy_pypi_pkgs
        local pkgs=($reply)
        local context state state_descr line opt_args
        _arguments \
            '(- *)--help[Show usage information]' \
            '(--help)-h[Include hashes in compiled requirements.txt]' \
            '(--help -u)-U[Upgrade all dependencies]' \
            "(--help -U)-u[Upgrade specific dependencies]:Package Names (comma-separated):_values -s , 'Package Names (comma-separated)' $pkgs" \
            '(-)*: :->reqsins'
        if [[ $state == reqsins ]]; then
            local blacklist=(${line//(#m)[\[\]()\\*?#<>~\^\|]/\\$MATCH})
            _arguments \
                '*:requirements.in:_files -F blacklist -g "*.in"' \
                '(*)--[pip-compile Arguments]:pip-compile Argument: '
        fi
    }
    compdef _${_zpyfn} $_zpyfn 2>/dev/null
done

_pipi () {
    _zpy_helpmsg ${0[2,-1]}
    local reply
    .zpy_pypi_pkgs
    local pkgs=($reply)
    _arguments \
        '(- *)--help[Show usage information]' \
        "(--help)--no-upgrade[Don't upgrade already-installed packages]" \
        "(-)*:Package Spec:($pkgs)"
}
compdef _pipi pipi 2>/dev/null

_pips () {
    _zpy_helpmsg ${0[2,-1]}
    local context state state_descr line opt_args
    _arguments \
        '(- *)--help[Show usage information]' \
        '(--help)*: :->reqstxts'
    if [[ $state == reqstxts ]]; then
        local blacklist=(${line//(#m)[\[\]()\\*?#<>~\^\|]/\\$MATCH})
        _arguments \
            '(--help)*:requirements.txt:_files -F blacklist -g "*.txt"'
    fi
}
compdef _pips pips 2>/dev/null

_prunevenvs () {
    _zpy_helpmsg ${0[2,-1]}
    _arguments \
        '(-)--help[Show usage information]' \
        "(--help)-y[Don't ask for confirmation]"
}
compdef _prunevenvs prunevenvs 2>/dev/null

for _zpyfn in pypc vpysublp whichpyproj; do
    _${_zpyfn} () {
        _zpy_helpmsg ${0[2,-1]}
        _arguments '--help[Show usage information]'
    }
    compdef _${_zpyfn} $_zpyfn 2>/dev/null
done

_reqshow () {
    _zpy_helpmsg ${0[2,-1]}
    local context state state_descr line opt_args
    _arguments \
        '(*)--help[Show usage information]' \
        '(--help)*: :->folders'
    if [[ $state == folders ]]; then
        local blacklist=(${line//(#m)[\[\]()\\*?#<>~\^\|]/\\$MATCH})
        _arguments \
            '(--help)*:Project:_path_files -F blacklist -/'
    fi
}
compdef _reqshow reqshow 2>/dev/null

_sublp () {
    _zpy_helpmsg ${0[2,-1]}
    if (( $+_comps[subl] )); then
    # Theoretically may act as false negative, though should be fine for subl
        $_comps[subl]
    else
        _arguments \
            '(- *)--help[Show usage information]' \
            '(--help)*:File or Folder:_files'
    fi
}
compdef _sublp sublp 2>/dev/null

_venvs_path () {
    _zpy_helpmsg ${0[2,-1]}
    _arguments \
        '(- :)--help[Show usage information]' \
        '(--help 1)-i[Interactively choose a project]' \
        '(-)1::Project:_path_files -/'
}
compdef _venvs_path venvs_path 2>/dev/null

_vlauncher () {
    _zpy_helpmsg ${0[2,-1]}
    local context state state_descr line opt_args
    _arguments \
        '(- * :)--help[Show usage information]' \
        '(--help)--link-only[Only create a symlink to <venv>/bin/<cmd>]' \
        '(--help)--py[Use another interpreter and named venv]:Other Python:(2 pypy current)' \
        "(-)1:Project:_path_files -/ -g '${ZPY_VENVS_WORLD}/*/project(@N-/:P)'" \
        '(-)2: :->cmd' \
        '(-)3:Destination:_path_files -/'
    if [[ $state == cmd ]]; then
        local REPLY projdir=${(Q)line[1]/#\~/~}
        .zpy_venvs_path $projdir
        _arguments \
            "*:Command:_path_files -g '$REPLY/venv/bin/*(x:t)'"
    fi
}
compdef _vlauncher vlauncher 2>/dev/null

_vpy () {
    _zpy_helpmsg ${0[2,-1]}
    _arguments \
        '(- : *)--help[Show usage information]' \
        '(--help)--py[Use another interpreter and named venv]:Other Python:(2 pypy current)' \
        "(--help)--activate[Activate the venv (usually unnecessary, and slower)]" \
        '(-)1:Script:_files -g "*.py"' \
        '(-)*:Script Argument: '
}
compdef _vpy vpy 2>/dev/null

_vpyshebang () {
    _zpy_helpmsg ${0[2,-1]}
    _arguments \
        '(- : *)--help[Show usage information]' \
        '(--help)--py[Use another interpreter and named venv]:Other Python:(2 pypy current)' \
        '(-)*:Script:_files -g "*.py"'
}
compdef _vpyshebang vpyshebang 2>/dev/null

_vrun () {
    _zpy_helpmsg ${0[2,-1]}
    local context state state_descr line opt_args
    integer NORMARG
    _arguments -n \
        '(- * :)--help[Show usage information]' \
        '(--help)--py[Use another interpreter and named venv]:Other Python:(2 pypy current)' \
        '(--help)--cd[Run the command from within the project folder]' \
        "(--help)--activate[Activate the venv (usually unnecessary for venv-installed scripts, and slower)]" \
        "(-)1:Project:_path_files -/ -g '${ZPY_VENVS_WORLD}/*/project(@N-/:P)'" \
        '(-)*::: :->cmd'
    local vname=venv
    if (( words[(i)--py] < NORMARG )); then
        local reply
        .zpy_argvenv ${words[${words[(i)--py]} + 1]} || return 1
        vname=$reply[1]
    fi
    if [[ $line[1] ]]; then
        local projdir=${${(Q)line[1]/#\~/~}:P} REPLY
        .zpy_venvs_path $projdir
        local venv=$REPLY/$vname
        if (( words[(i)--cd] < NORMARG )); then
            trap "cd ${(q-)PWD}" EXIT INT
            cd $projdir
        fi
    fi
    if [[ $state == cmd ]]; then
        if [[ ${#words} == 1 ]]; then

            # Neither of these work:
            # _arguments ":Command:_path_files -g '${venv}/bin/*(Nx:t)'"
            # _arguments "1:Command:_path_files -g '${venv}/bin/*(Nx:t)'"

            # This works, but doesn't inherit existing styling for header message:
            # _path_files -X Command -g "${venv}/bin/*(Nx:t)"

            # Currently settling for this:
            _path_files -g "${venv}/bin/*(Nx:t)"
        fi
        _normal -P
    fi
}
compdef _vrun vrun 2>/dev/null

_zpy () {
    _zpy_helpmsg ${0[2,-1]}
    local lines=(${(f)"$(.zpy)"})
    local cmds=(${${(M)lines:#[^# ]*}/ *})
    local pipz_cmd
    local -A rEpLy
    pipz subcommands
    for pipz_cmd in ${(k)rEpLy}; do
        cmds+=(${(q-):-"pipz $pipz_cmd"})
    done
    _arguments \
        '(*)--help[Show usage information]' \
        "(--help)*:Function:($cmds)"
}
compdef _zpy zpy 2>/dev/null

_pipz () {
    local cmds=() cmd desc
    local -A rEpLy
    ${0[2,-1]} subcommands
    for cmd desc in ${(kv)rEpLy}; do
        cmds+=("${cmd}:${desc}")
    done
    integer NORMARG
    local context state state_descr line opt_args
    _arguments \
        '(1 *)--help[Show usage information]' \
        '(--help)1:Operation:(($cmds))' \
        '(--help)*:: :->sub_arg'
    if [[ $state != sub_arg ]]; then
        _zpy_helpmsg ${0[2,-1]}
    else
        _zpy_helpmsg "$0[2,-1] $line[1]"
        case $line[1] in
        install)
            local reply
           .zpy_pypi_pkgs
            local pkgs=($reply)
            _arguments \
                '(* -)--help[Show usage information]' \
                '(--help)--cmd[Specify commands to add to your path, rather than interactively choosing]:Command (comma-separated): ' \
                '(--help)--activate[Ensure command launchers explicitly activate the venv (usually unnecessary)]' \
                "(-)*:Package Spec:($pkgs)"
        ;;
        reinstall)
            local blacklist=(${(Q)words[2,-1]})
            while [[ $blacklist[1] =~ '^(--help|--activate|--all|--cmd)$' ]]; do
                if [[ $blacklist[1] == --cmd ]]; then
                    blacklist=($blacklist[3,-1])
                else
                    blacklist=($blacklist[2,-1])
                fi
            done
            local pkgs=(${XDG_DATA_HOME:-~/.local/share}/python/*(/N:t))
            pkgs=(${pkgs:|blacklist})
            _arguments \
                '(* -)--help[Show usage information]' \
                '(--help)--cmd[Specify commands to add to your path, rather than interactively choosing]:Command (comma-separated): ' \
                '(--help)--activate[Ensure command launchers explicitly activate the venv (usually unnecessary)]' \
                '(--help *)--all[Reinstall all installed apps]' \
                "(-)*:Installed Package Name:($pkgs)"
        ;;
        inject)
            local reply
            .zpy_pypi_pkgs
            local pkgs=($reply)
            _arguments \
                '(* - :)--help[Show usage information]' \
                '(--help)--cmd[Specify commands to add to your path, rather than interactively choosing]:Command (comma-separated): ' \
                '(--help)--activate[Ensure command launchers explicitly activate the venv (usually unnecessary)]' \
                "(-)1:Installed Package Name:(${XDG_DATA_HOME:-~/.local/share}/python/*(/N:t))" \
                "(-)*:Extra Package Spec:($pkgs)"
        ;;
        uninstall)
            local blacklist=(${(Q)words[2,-1]})
            local pkgs=(${XDG_DATA_HOME:-~/.local/share}/python/*(/N:t))
            pkgs=(${pkgs:|blacklist})
            _arguments \
                '(* -)--help[Show usage information]' \
                '(--help *)--all[Uninstall all installed apps]' \
                "(-)*:Installed Package Name:($pkgs)"
        ;;
        upgrade)
            local blacklist=(${(Q)words[2,-1]})
            local pkgs=(${XDG_DATA_HOME:-~/.local/share}/python/*(/N:t))
            pkgs=(${pkgs:|blacklist})
            _arguments \
                '(* -)--help[Show usage information]' \
                '(--help *)--all[Upgrade all installed apps]' \
                "(-)*:Installed Package Name:($pkgs)"
        ;;
        list)
            local blacklist=(${(Q)words[2,-1]})
            local pkgs=(${XDG_DATA_HOME:-~/.local/share}/python/*(/N:t))
            pkgs=(${pkgs:|blacklist})
            _arguments \
                '(*)--help[Show usage information]' \
                "(--help)*:Installed Package Name:($pkgs)"
        ;;
        runpkg)
            local pkgname REPLY pkgcmd
            if [[ $line[2] ]]; then
                .zpy_pkgspec2name ${(Q)line[2]}
                pkgname=$REPLY
            fi
            pkgcmd=$line[3]
            local reply
            .zpy_pypi_pkgs
            local pkgs=($reply)
            _arguments \
                '(* :)--help[Show usage information]' \
                "(--help)1:Package Spec:($pkgs)" \
                "(--help)2:Command:($pkgname)" \
                '(--help)*:::Command Argument:->cmdarg'
            if [[ $state == cmdarg ]]; then
                words=($pkgcmd $words)
                (( CURRENT+=1 ))
                _normal -P
            fi
        ;;
        runpip)
            _arguments -n \
                '(* - :)--help[Show usage information]' \
                '(--help)--cd[Run pip from within the project folder]' \
                "(-)1:Installed Package Name:(${XDG_DATA_HOME:-~/.local/share}/python/*(/N:t))" \
                '(-)*::: :->pip_arg'
            if [[ $state == pip_arg ]]; then
                words=(pip $words)
                (( CURRENT+=1 ))
                _normal -P
            fi
        ;;
        cd)
            _arguments \
                '(* :)--help[Show usage information]' \
                "(--help)1:Installed Package Name:(${XDG_DATA_HOME:-~/.local/share}/python/*(/N:t))" \
                '(--help)*::: :->cmd'
            if [[ $state == cmd ]]; then
                trap "cd ${(q-)PWD}" EXIT INT
                cd ${XDG_DATA_HOME:-~/.local/share}/python/${(Q)line[1]:l}
                _normal -P
            fi
        ;;
        esac
    fi
}
compdef _pipz pipz 2>/dev/null

unset _zpyfn

## TODO: more [-- pip-{compile,sync}-arg...]? (pips pipup 'pipz inject' 'pipz install')
## TODO: revisit instances of 'pipi -q pip-tools' if/when pip-tools gets out-of-venv support:
## https://github.com/jazzband/pip-tools/issues/1087

.zpy_pypi_pkgs () {  # [--refresh]
    emulate -L zsh
    unset reply
    local folder=${XDG_CACHE_HOME:-~/.cache}/zpy
    mkdir -p $folder
    local json=$folder/pypi.json txt=$folder/pypi.txt
    if [[ $1 == --refresh ]] || [[ ! -r $txt ]]; then
        if (( $+commands[wget] )); then
            wget -qO $json https://hugovk.github.io/top-pypi-packages/top-pypi-packages-30-days.min.json || return 1
        else
            curl -s -o $json https://hugovk.github.io/top-pypi-packages/top-pypi-packages-30-days.min.json || return 1
        fi
        if (( $+commands[jq] )); then
            jq -r '.rows[].project' <$json >$txt
        elif (( $+commands[jello] )); then
            jello -lr '[p["project"] for p in _["rows"]]' <$json >$txt
        else
            python3 -c "
from pathlib import Path
from json import loads


jfile = Path('''${json}''')
tfile = Path('''${txt}''')
data = loads(jfile.read_text())
tfile.write_text('\n'.join(r['project'] for r in data['rows']))
            "
        fi
    fi
    # reply=("${(fq-)$(<$txt)}")
    reply=(${(f)"$(<$txt)"})
}
