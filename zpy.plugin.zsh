autoload -Uz zargs
zmodload -mF zsh/files 'b:zf_(chmod|ln|mkdir|rm)'
zmodload zsh/pcre 2>/dev/null

ZPY_SRC=${0:P}
ZPY_PROCS=${${$(nproc 2>/dev/null):-$(sysctl -n hw.logicalcpu 2>/dev/null)}:-4}

## User may want to override these:
ZPY_VENVS_WORLD=${ZPY_VENVS_WORLD:-${XDG_DATA_HOME:-~/.local/share}/venvs}
## Each project is associated with: $ZPY_VENVS_WORLD/<hash of proj-dir>/<venv-name>
## <venv-name> is one or more of: venv, venv2, venv-pypy, venv-<pyver>
## $(venvs_path <proj-dir>) evals to $ZPY_VENVS_WORLD/<hash of proj-dir>
ZPY_PIPZ_PROJECTS=${ZPY_PIPZ_PROJECTS:-${XDG_DATA_HOME:-~/.local/share}/python}
ZPY_PIPZ_BINS=${ZPY_PIPZ_BINS:-${${XDG_DATA_HOME:-~/.local/share}:P:h}/bin}
## Installing an app via pipz puts requirements.{in,txt} in $ZPY_PIPZ_PROJECTS/<appname>
## and executables in $ZPY_PIPZ_BINS

## Syntax highlighter, reading stdin.
.zpy_hlt () {  # <syntax>
    emulate -L zsh
    [[ $1 ]] || return
    rehash

    if [[ -v NO_COLOR ]] {
        >&1
        return
    }

    if [[ $1 == diff ]] {
        local diffhi
        for diffhi (
            $commands[diff-so-fancy]
            $commands[delta]
            $commands[diff-highlight]
            /usr/local/opt/git/share/git-core/contrib/diff-highlight/diff-highlight
            /usr/local/share/git-core/contrib/diff-highlight/diff-highlight
            /usr/share/doc/git/contrib/diff-highlight
            /usr/share/doc/git/contrib/diff-highlight/diff-highlight
            /usr/share/git-core/contrib/diff-highlight
            /usr/share/git/diff-highlight/diff-highlight
        ) {
            if [[ -x $diffhi && -f $diffhi ]] {
                local args=()
                if [[ $diffhi:t == delta ]] args+=(--paging never --color-only)
                # delta will use BAT_THEME
                BAT_THEME=${BAT_THEME:-ansi} \
                $diffhi $args
                return
            }
        }
    }

    if (( $+commands[highlight] )) {
        # recommended themes: aiseered, blacknblue, bluegreen, ekvoli, navy

        # highlight has two issues with newlines:

        # Firstly, empty input can yield unwanted newlines as output.
        # https://gitlab.com/saalen/highlight/-/issues/147
        # This can be avoided in highlight >= 3.56 with: --no-trailing-nl=empty-file

        # Example:
        # local lines=(${(f)"$(highlight --version)"})
        # local version_words=(${(z)lines[1]})
        # if [[ $version_words[-1] -ge 3.56 ]] {
        #     HIGHLIGHT_OPTIONS=${HIGHLIGHT_OPTIONS:-'-s aiseered'} \
        #     highlight --no-trailing-nl=empty-file -O truecolor --stdout -S $1
        # } else {
        #     <uncommented method below>
        # }

        # Secondly, when used multiple times in parallel (via zargs),
        # highlight may fail to add a newline at the end of an output,
        # resulting in the last line of one doc being joined with
        # the first of the next. This is true of at least highlight 3.58.

        # The method below bypasses both issues consistently
        # across all known versions of highlight, and still outperforms bat:
        local content=$(<&0)
        if [[ $content ]] {
            local themes=(aiseered blacknblue bluegreen ekvoli navy)
            HIGHLIGHT_OPTIONS=${HIGHLIGHT_OPTIONS:-"-s $themes[RANDOM % $#themes + 1]"} \
            highlight -O truecolor --stdout -S $1 <<<$content
        }
    } elif (( $+commands[bat] )) {  # recommended themes: ansi, zenburn
        BAT_THEME=${BAT_THEME:-ansi} \
        bat --color always --paging never -p -l $1
    } elif (( $+commands[batcat] )) {
        BAT_THEME=${BAT_THEME:-ansi} \
        batcat --color always --paging never -p -l $1
    } else {
        >&1
    }
}

## fallback basic pcregrep-like func for our needs; not preferred to pcregrep or ripgrep
.zpy_zpcregrep () {  # <output> <pattern> <file>
    emulate -L zsh
    # <output> like: '$1$4$5$7'

    local backrefs=() pattern=$2 body="$(<$3)"
    backrefs=(${(s:$:)1})

    local result_parts=() result_template
    result_parts=("\$match[${(@)^backrefs}]")
    result_template=${(j::)result_parts}  # '$match[1]$match[4]$match[5]$match[7]'

    local all_results=() ZPCRE_OP
    pcre_compile -m $pattern
    pcre_match -b -- $body
    while (( ! ? )) {
        all_results+="${(e)result_template}"
        pcre_match -b -n ${${(z)ZPCRE_OP}[-1]} -- $body
    }

    print -r -- ${(F)all_results}
}

## zpy, but never highlight
.zpy () {  # [<zpy-function>...]
    emulate -L zsh -o extendedglob
    [[ -r $ZPY_SRC ]] || return
    rehash

    local cmds_pattern='^(?P<predoc>\n?(# .*\n)*)(alias (?P<aname>[^=]+)="[^"]+"|(?P<fname>[^._ \n][^ \n]+) \(\) \{)(  #(?P<usage> .+))?'
    local subcmd_pattern='.*  # (?P<usage>.*)  ## subcmd: <CMD> <SUBCMD>(?P<postdoc>\n( *# [^\n]+\n)*)'

    local cmd_doc=() subcmd_doc=()
    if (( $+commands[pcre2grep] )) {
        cmd_doc=(pcre2grep -M -O '$1$4$5$7')
        subcmd_doc=(pcre2grep -M -O '$1$2')
    } elif (( $+commands[pcregrep] )) {
        cmd_doc=(pcregrep -M -o1 -o4 -o5 -o7)
        subcmd_doc=(pcregrep -M -o1 -o2)
    } elif (( $+commands[rg] )) {
        cmd_doc=(rg --no-config --color never -NU -r '$predoc$aname$fname$usage')
        subcmd_doc=(rg --no-config --color never -NU -r '$usage$postdoc')
    } elif { zmodload -e zsh/pcre } {
        cmd_doc=(.zpy_zpcregrep '$1$4$5$7')
        subcmd_doc=(.zpy_zpcregrep '$1$2')
    } else {
        local lines=(
            'zpy documentation functions require one of'
            '- zsh built with --enable-pcre'
            '- rg (ripgrep)'
            '- pcre2grep (pcre2/pcre2-tools)'
            '- pcregrep (pcre/pcre-tools)'
        )
        .zpy_log error $lines
        return 1
    }

    if ! (( $# )) {  # all commands
        print -r -- ${"$(
            $cmd_doc $cmds_pattern $ZPY_SRC
        )"##[[:space:]]#}

    } else {  # specified commands & subcommands
        local cmd subcmd lines=()
        local -A rEpLy
        for 1 {

            if (( ! ${1[(I) ]} )) {  # "<cmd>"
                print -r -- ${"$(
                    $cmd_doc ${(S)cmds_pattern//name>*\)/name>$1)} $ZPY_SRC
                )"##[[:space:]]#}

            } else {  # "<cmd> <subcmd>"
                cmd=${${(z)1}[1]}
                subcmd=${${(z)1}[2]}
                $cmd subcommands
                print -r "# ${rEpLy[$subcmd]}"
                lines=(${(f)"$(
                    $subcmd_doc ${${subcmd_pattern:gs/<CMD>/$cmd}:gs/<SUBCMD>/$subcmd} $ZPY_SRC
                )"})
                lines[1]="$cmd $subcmd $lines[1]"
                print -rl -- ${lines##[[:space:]]#}
            }

            if [[ $1 != ${@[-1]} ]] print
        }
    }
}

# Print description and arguments for all or specified functions.
zpy () {  # [<zpy-function>...]
    emulate -L zsh
    if [[ $1 == --help ]] { zpy $0; return }

    .zpy $@ | .zpy_hlt zsh
    local badrets=(${pipestatus:#0})
    [[ ! $badrets ]]
}

.zpy_path_hash () {  # <path>
    emulate -L zsh
    unset REPLY
    [[ $1 ]] || return
    rehash

    if (( $+commands[md5sum] )) {
        REPLY="${$(md5sum =(<<<${1:P}))%% *}"
    } else {
        REPLY="$(md5 -qs ${1:P})"
    }

    [[ $REPLY ]] || return
}

.zpy_venvs_path () {  # [<proj-dir>]
    emulate -L zsh
    unset REPLY
    [[ $ZPY_VENVS_WORLD ]] || return

    .zpy_path_hash ${${1:-$PWD}:P} || return
    REPLY="${ZPY_VENVS_WORLD}/${REPLY}"
}

.zpy_chooseproj () {
    emulate -L zsh
    unset REPLY
    [[ $ZPY_VENVS_WORLD ]] || return

    local projdirs=(${ZPY_VENVS_WORLD}/*/project(@N-/:P))
    REPLY=$(print -rln -- $projdirs | fzf --reverse -0 -1 --preview='<{}/*.in')
}

# Get path of folder containing all venvs for the current folder or specified proj-dir.
# Pass -i to interactively choose the project.
venvs_path () {  # [-i|<proj-dir>]
    emulate -L zsh
    if [[ $1 == --help ]] { zpy $0; return }

    local REPLY
    if [[ $1 == -i ]] {
        .zpy_chooseproj || return
        venvs_path "$REPLY"
    } else {
        .zpy_venvs_path $@ || return
        print -rn -- $REPLY
    }
}

.zpy_please_activate () {  # [not-found-item]
    emulate -L zsh

    .zpy_log error 'FAILED to find' "$1" \
      "You probably want to activate a venv with 'activate' (or 'a8'), first." \
      "But we'll try anyway." \
      "${${${PWD:P}/#~\//~/}/%${PWD:t}/%B${PWD:t}%b}"
}

# Install and upgrade packages.
pipi () {  # [--no-upgrade] [<pip install arg>...] <pkgspec>...
    emulate -L zsh
    if [[ $1 == --help ]] { zpy $0; return }
    [[ $VIRTUAL_ENV ]] || .zpy_please_activate venv

    local upgrade=-U
    if [[ $1 == --no-upgrade ]] { unset upgrade; shift }

    if [[ ! $1 ]] { zpy $0; return 1 }

    python -m pip --disable-pip-version-check install $upgrade $@
    local ret=$?
    rehash

    if (( ret )) {
        local log_args=(error "FAILED $0 call" "$0 $@" $VIRTUAL_ENV)
        if [[ $VIRTUAL_ENV ]] && [[ -L ${VIRTUAL_ENV:h}/project ]] {
            log_args+=${VIRTUAL_ENV:h}/project(:P:t)
        }
        .zpy_log $log_args
        return ret
    }
}

.zpy_print_action () {  # [--proj <folder>] <action> <output> [<input>...]
    emulate -L zsh

    local proj=$PWD
    if [[ $1 == --proj ]] { proj=$2; shift 2 }

    [[ $2 && $1 ]] || return

    local action output input=()
    action=$1; shift
    output=$1; shift
    input=($@)

    local -A c=(
        default     cyan
        proj        blue
        syncing     green
        compiling   magenta
        appending   yellow
        creating    yellow
        injecting   yellow
    )
    if ! (( $+c[$action] )) c[$action]=$c[default]

    local parts=()
    if ! [[ -v NO_COLOR ]] {
        parts+=(
            "%F{$c[default]}>"
            "%B%F{$c[$action]}$action%b"
        )
        if [[ $input ]] parts+=("%F{$c[default]}${(j:%B|%b:)input}")
        parts+=(
            "%F{$c[$action]}%B->%b"
            "%F{$c[default]}$output"
            "%F{$c[proj]}%B::%b ${${${proj:P}/#~\//~/}/%${proj:t}/%B${proj:t}%b}%f"
        )
    } else {
        parts+=('>' "%B$action%b")
        if [[ $input ]] parts+=("${(j:%B|%b:)input}")
        parts+=(
            '%B->%b' "$output" '%B::%b'
            "${${${proj:P}/#~\//~/}/%${proj:t}/%B${proj:t}%b}"
        )
    }

    print -rPu2 -- $parts
}

# Install packages according to all found or specified requirements.txt files (sync).
pips () {  # [<reqs-txt>...]
    emulate -L zsh
    if [[ $1 == --help ]] { zpy $0; return }
    rehash
    if (( ! $+commands[pip-sync] )) { .zpy_please_activate pip-sync; return 1 }

    local reqstxts=(${@:-*requirements.txt(N)}) ret
    if [[ $reqstxts ]] {
        local p_a_args=(syncing env $reqstxts)
        if [[ $VIRTUAL_ENV && -L ${VIRTUAL_ENV:h}/project ]] p_a_args=(--proj ${VIRTUAL_ENV:h}/project(:P) $p_a_args)
        .zpy_log action $p_a_args
        pip-sync -q --pip-args --disable-pip-version-check $reqstxts
        ret=$?

        local reqstxt                       #
        for reqstxt ( $reqstxts ) {         # can remove if pip-tools #896 is resolved
            pipi --no-upgrade -qr $reqstxt  # (by merging pip-tools #907)
            if (( ? )) ret=1                #
        }                                   #
        rehash

        if (( ret )) {
            .zpy_log error "FAILED $0 call" "$0 $@"
            return ret
        }
    }
}

.zpy_pipc () {  # [--faildir <faildir>] [--snapshotdir <snapshotdir>] <reqs-in> [<pip-compile-arg>...]
    emulate -L zsh
    rehash
    if (( ! $+commands[pip-compile] )) { .zpy_please_activate pip-compile; return 1 }

    local faildir snapshotdir
    while [[ $1 == --(fail|snapshot)dir ]] {
        if [[ $1 == --faildir     ]] { faildir=${2:a};     shift 2 }
        if [[ $1 == --snapshotdir ]] { snapshotdir=${2:a}; shift 2 }
    }

    [[ $1 ]] || return

    local reqsin=$1; shift

    local reqstxt
    if [[ ${reqsin:t:r} ]] {
        reqstxt=${reqsin:r}.txt
    } else {
        reqstxt=${reqsin}.txt
    }
    local outswitch
    for outswitch ( -o --output-file ) {
        if (( ${@[(I)$outswitch]} )) {
            reqstxt=${@[$@[(i)$outswitch]+1]}
            break
        }
    }

    .zpy_log action compiling "$reqstxt" $reqsin

    if [[ $snapshotdir ]] {
        local origtxt=${snapshotdir}${reqstxt:a}
        zf_mkdir -p -m 0700 ${origtxt:h}
        if [[ -r $reqstxt ]] {
            <$reqstxt >$origtxt
        } else {
            print -n >$origtxt
        }
        zf_chmod 0600 $origtxt
    }

    # Set cache dir for concurrency (see pip-tools #1083):
    local REPLY reqstxt_hash cachedir
    .zpy_path_hash $reqstxt
    reqstxt_hash=$REPLY
    cachedir=${VIRTUAL_ENV:-$(mktemp -d)}/zpy-cache/${reqstxt_hash}

    local badrets
    pip-compile --cache-dir $cachedir --no-header -o $reqstxt $@ $reqsin 2>&1 \
    | .zpy_hlt ini
    badrets=(${pipestatus:#0})

    if [[ $badrets && $faildir ]] print -n >>$faildir/${PWD:t}

    [[ ! $badrets ]]
}

.zpy_pipu () {  # [--faildir <faildir>] [--snapshotdir <snapshotdir>] <reqsin> [<pkgspec>...] [-- <pip-compile-arg>...]
    emulate -L zsh

    local zpypipc_args=() pipcompile_args=()
    while [[ $1 == --(fail|snapshot)dir ]] {
        zpypipc_args+=($1 $2); shift 2
    }
    if (( ${@[(I)--]} )) {
        pipcompile_args+=(${@[$@[(i)--]+1,-1]})
        shift -p "$(( $#pipcompile_args+1 ))"
    }

    [[ $1 ]] || return

    local reqsin=$1; shift

    local reqs=($@) reqstxt
    if [[ ${reqsin:t:r} ]] {
        reqstxt=${reqsin:r}.txt
    } else {
        reqstxt=${reqsin}.txt
    }

    pipi -q pip-tools wheel

    .zpy_pipc $zpypipc_args $reqsin -q ${${${reqs/*/-P}:^reqs}:--U} $pipcompile_args
    local ret=$?

    return ret
}

# Compile requirements.txt files from all found or specified requirements.in files (compile).
# Use -h to include hashes, -u dep1,dep2... to upgrade specific dependencies, and -U to upgrade all.
pipc () {  # [-h] [-U|-u <pkgspec>[,<pkgspec>...]] [<reqs-in>...] [-- <pip-compile-arg>...]
    emulate -L zsh
    unset REPLY
    if [[ $1 == --help ]] { zpy $0; return }
    [[ $ZPY_PROCS ]] || return

    local gen_hashes upgrade upgrade_csv
    while [[ $1 == -[hUu] ]] {
        if [[ $1 == -h ]] { gen_hashes=--generate-hashes; shift   }
        if [[ $1 == -U ]] { upgrade=1;                    shift   }
        if [[ $1 == -u ]] { upgrade=1; upgrade_csv=$2;    shift 2 }
    }

    local pipcompile_args=()
    if (( ${@[(I)--]} )) {
       pipcompile_args+=(${@[$@[(i)--]+1,-1]})
       shift -p "$(( $#pipcompile_args+1 ))"
    }

    local snapshotdir=$(mktemp -d) faildir=$(mktemp -d) failures=()
    local zpypipc_args=(--faildir $faildir --snapshotdir $snapshotdir)  # also .zpypipu
    if [[ $upgrade ]] {
        zargs -P $ZPY_PROCS -ri___ \
        -- ${@:-*requirements.in(N)} \
        -- .zpy_pipu $zpypipc_args ___ ${(s:,:)upgrade_csv} -- $gen_hashes $pipcompile_args
    } else {
        zargs -P $ZPY_PROCS -ri___ \
        -- ${@:-*requirements.in(N)} \
        -- .zpy_pipc $zpypipc_args ___ $gen_hashes $pipcompile_args
    }
    failures=($faildir/*(N:t))
    zf_rm -rf $faildir

    .zpy_diffsnapshot $snapshotdir

    REPLY=${snapshotdir:a}

    if [[ $failures ]] {
        .zpy_log error 'Problems compiling' $failures
        zpy $0
        return 1
    }
}

# TODO: move highest level funcs to top

# .zpy_log error <title> <subject> [<line>]...
# .zpy_log action [--proj <folder>] <action> <output> [<input>...]
.zpy_log () {  # error|action <arg>...
    emulate -L zsh

    case $1 {
    error)
        shift
        local title="> $1:"; shift
        local subject=$1; shift
        local lines=('  '${^@})
        if ! [[ -v NO_COLOR ]] {
            title="%F{red}$title %F{yellow}$subject"
            lines[-1]="${lines[-1]}%f"
        } else {
            title="$title $subject"
        }
        print -lrPu2 -- $title $lines
    ;;
    action)
        shift
        .zpy_print_action $@
    ;;
    }
}

# Compile, then sync.
# Use -h to include hashes, -u dep1,dep2... to upgrade specific dependencies, and -U to upgrade all.
pipcs () {  # [-h] [-U|-u <pkgspec>[,<pkgspec>...]] [--only-sync-if-changed] [<reqs-in>...] [-- <pip-compile-arg>...]
    emulate -L zsh
    if [[ $1 == --help ]] { zpy $0; return }

    local only_sync_if_changed pipc_args=()
    while [[ $1 == (-[hUu]|--only-sync-if-changed) ]] {
        if [[ $1 == -[hU]                  ]] { pipc_args+=($1);         shift   }
        if [[ $1 == -u                     ]] { pipc_args+=($1 $2);      shift 2 }
        if [[ $1 == --only-sync-if-changed ]] { only_sync_if_changed=$1; shift   }
    }

    local pipcompile_args=()
    if (( ${@[(I)--]} )) {
       pipcompile_args=(${@[$@[(i)--]+1,-1]})
       shift -p "$(( $#pipcompile_args+1 ))"
    }
    pipc_args+=($@ ${pipcompile_args:+--} $pipcompile_args)

    local do_sync
    if [[ ! $only_sync_if_changed ]] do_sync=1

    local ret REPLY snapshot
    pipc $pipc_args
    ret=$?
    snapshot=$REPLY

    if (( ret )) {
        .zpy_log error "FAILED $0 call" "$0 $only_sync_if_changed $pipc_args"
        return ret
    }

    local origtxts=(${snapshot}/**/*(DN.))
    local txts=(${origtxts#$snapshot})

    if [[ ! $do_sync ]] {
        local origtxt txt
        for origtxt txt ( ${origtxts:^txts} ) {
            if ! { diff -q $origtxt $txt &>/dev/null } {
                do_sync=1
                break
            }
        }
    }

    if [[ $do_sync ]] pips $txts
}

# Add loose requirements to [<category>-]requirements.in (add).
pipa () {  # [-c <category>] <pkgspec>...
    emulate -L zsh
    if [[ $1 == --help ]] { zpy $0; return }

    local reqsin=requirements.in
    if [[ $1 == -c ]] { reqsin=${2}-requirements.in; shift 2 }

    if [[ ! $1 ]] { zpy $0; return 1 }

    .zpy_log action appending "$reqsin"

    print -rl -- $@ >>$reqsin

    .zpy_hlt ini <$reqsin
}

# Add to requirements.in, then compile it to requirements.txt (add, compile).
# Use -c to affect categorized requirements, and -h to include hashes.
pipac () {  # [-c <category>] [-h] <pkgspec>... [-- <pip-compile-arg>...]
    emulate -L zsh
    if [[ $1 == --help ]] { zpy $0; return }

    local catg gen_hashes
    while [[ $1 == -[ch] ]] {
        if [[ $1 == -c ]] { catg=$2;                      shift 2 }
        if [[ $1 == -h ]] { gen_hashes=--generate-hashes; shift   }
    }

    local pipcompile_args=()
    if (( ${@[(I)--]} )) {
       pipcompile_args+=(${@[$@[(i)--]+1,-1]})
       shift -p "$(( $#pipcompile_args+1 ))"
    }

    if [[ ! $1 ]] { zpy $0; return 1 }

    local pipa_args=($@) reqsin=requirements.in
    if [[ $catg ]] {
        pipa_args=(-c $catg $pipa_args)
        reqsin=${catg}-requirements.in
    }

    local pipc_args=($reqsin -- $gen_hashes $pipcompile_args)

    pipa $pipa_args
    pipc $pipc_args
}

# Add to requirements.in, compile it to requirements.txt, then sync to that (add, compile, sync).
# Use -c to affect categorized requirements, and -h to include hashes.
pipacs () {  # [-c <category>] [-h] <pkgspec>... [-- <pip-compile-arg>...]
    emulate -L zsh
    if [[ $1 == --help ]] { zpy $0; return }

    pipac $@
    local ret=$?

    if (( ret )) {
        .zpy_log error "FAILED $0 call" "$0 $@"
        return ret
    }

    local reqstxt=requirements.txt
    if [[ $1 == -h ]] shift
    if [[ $1 == -c ]] reqstxt=${2}-requirements.txt

    pips $reqstxt
}

# View contents of all *requirements*.{in,txt} files in the current or specified folders.
reqshow () {  # [<folder>...]
    emulate -L zsh
    if [[ $1 == --help ]] { zpy $0; return }
    [[ $1 ]] || 1=$PWD

    local reqsfiles=() rf
    for 1 {
        # Basically this, but avoiding reliance on tail:
        # tail -n +1 $1/*requirements*.{in,txt} | .zpy_hlt ini

        reqsfiles+=($1/*requirements*.{txt,in}(N))

        for rf ( $reqsfiles ) {
            if [[ $rf != ${reqsfiles[1]} ]] print
            print -r -- '==>' $rf '<=='
            .zpy_hlt ini <$rf
        }
        if [[ $1 != ${@[-1]} ]] print
    }
}

.zpy_pyvervenvname () {
    emulate -L zsh
    unset REPLY
    rehash
    if (( ! $+commands[python] )) {
        .zpy_log error 'FAILED to find in path' python
        return 1
    }

    local name=(${(f)"$(python -V 2>&1)"})
    name=(${(z)name[-1]})

    REPLY=venv-${(j:-:)name:0:2:l:gs/[/}
}

.zpy_envin () {  # <venv-name> <venv-init-cmd...> [-- <reqs-txt>...]
    emulate -L zsh
    [[ $2 && $1 ]] || return

    # get venvs path (vpath) and named venv path (venv):
    local REPLY vpath venv
    .zpy_venvs_path || return
    vpath=$REPLY
    venv=$vpath/$1; shift      # chomp <venv-name>

    local reqstxts=()          # chomp [-- <reqs-txt>...]:
    local cmd_end=${@[(I)--]}
    if (( cmd_end )) {
        reqstxts=(${@[$cmd_end+1,-1]})
        shift -p "$(( $#reqstxts+1 ))"
    }

    local venv_cmd=($@)        # <venv-init-cmd...>

    # abbreviate the hash portion of the venv path, for display:
    local short_venv="${venv/#~\//~/}"
    local short_venv_parts=("${(s:/:)short_venv}")
    short_venv_parts[-2]=${short_venv_parts[-2][1,3]}…
    short_venv=${(j:/:)short_venv_parts}

    # create venv if necessary:
    local ret
    if [[ ! -r $venv/bin/activate ]] || ! { $venv/bin/pip &>/dev/null } {
        .zpy_log action 'creating' "venv %B@%b $short_venv"
        zf_rm -rf $venv
        $venv_cmd $venv
        # TODO: account for pipz install --activate?
    }
    ret=$?

    if (( ret )) {
        .zpy_log error 'FAILED to make venv' "$venv_cmd $venv"
        return ret
    }

    zf_ln -sfn $PWD ${vpath}/project

    . $venv/bin/activate || return

    if { .zpy_netcheck } {
        pipi -q pip-tools wheel
    } else {
        pipi --no-upgrade -q pip-tools wheel
    }

    pips $reqstxts
}

# Return non-zero if there's no connection
.zpy_netcheck () {
    emulate -L zsh

    local url=https://pypi.org/simple/
    local timeout=3

    if (( $+commands[nm-online] )) {
        nm-online -t $timeout -qx
    } elif (( $+commands[wget] )) {
        wget -T $timeout -q --spider $url &>/dev/null
    } else {
        curl -m $timeout -sI $url &>/dev/null
    }
}

.zpy_argvenv () {  # 2|pypy|current -> ($venv_name $venv_cmd...)
    emulate -L zsh
    unset reply

    local venv_name venv_cmd=()
    case $1 {
    2)
        venv_name=venv2
        if     (( $+commands[virtualenv2] )) { venv_cmd=(virtualenv2)
        } elif (( $+commands[virtualenv]  )) { venv_cmd=(virtualenv -p python2)
        } else                               { venv_cmd=(python2 -m virtualenv) }
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
        if     [[ $major == 3            ]] { venv_cmd=(python -m venv)
        } elif (( $+commands[virtualenv] )) { venv_cmd=(virtualenv -p python)
        } else                              { venv_cmd=(python -m virtualenv) }
    ;;
    *)
        return 1
    ;;
    }

    reply=($venv_name $venv_cmd)
}

# Activate the venv (creating if needed) for the current folder, and sync its
# installed package set according to all found or specified requirements.txt files.
# In other words: [create, ]activate, sync.
# The interpreter will be whatever 'python3' refers to at time of venv creation, by default.
# Pass --py to use another interpreter and named venv.
envin () {  # [--py 2|pypy|current] [<reqs-txt>...]
    emulate -L zsh
    if [[ $1 == --help ]] { zpy $0; return }

    local venv_name=venv venv_cmd=(python3 -m venv)
    if [[ $1 == --py ]] {
        local reply
        if ! { .zpy_argvenv $2 } { zpy $0; return 1 }
        venv_name=$reply[1]
        venv_cmd=($reply[2,-1])
        shift 2
    }

    .zpy_envin $venv_name $venv_cmd -- $@
}

# Activate the venv for the current folder or specified project, if it exists.
# Otherwise create, activate, sync.
# Pass -i to interactively choose the project.
# Pass --py to use another interpreter and named venv.
activate () {  # [--py 2|pypy|current] [-i|<proj-dir>]
    emulate -L zsh -o localtraps
    if [[ $1 == --help ]] { zpy $0; return }

    local envin_args=() venv_name=venv interactive
    while [[ $1 == -(i|-py) ]] {
        if [[ $1 == -i ]] { interactive=1; shift }
        if [[ $1 == --py ]] {
            local reply
            if ! { .zpy_argvenv $2 } { zpy $0; return 1 }
            venv_name=$reply[1]
            envin_args=($1 $2)
            shift 2
        }
    }

    local REPLY
    if [[ $interactive ]] {
        .zpy_chooseproj || return
        activate $envin_args "$REPLY"
        return
    }

    local projdir=${${1:-$PWD}:P}

    local venv
    .zpy_venvs_path $projdir || return
    venv=$REPLY/$venv_name

    local activator=$venv/bin/activate

    if [[ ! -r $activator ]] || ! { $venv/bin/pip &>/dev/null } {
        trap "cd ${(q-)PWD}" EXIT INT QUIT
        zf_mkdir -p $projdir
        cd $projdir
        envin $envin_args
        # TODO: account for pipz install --activate?
    } elif { . $activator } {
        if { .zpy_netcheck } {
            pipi -q pip-tools wheel
        } else {
            pipi --no-upgrade -q pip-tools wheel
        }
    } else {
        return
    }
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
    [[ $2 && $1 ]] || return

    .zpy_venvs_path ${2:a:h} || return
    REPLY=$REPLY/$1/bin/python
}

# Display path of project for the activated venv.
whichpyproj () {
    emulate -L zsh
    if [[ $1 == --help ]] { zpy $0; return }
    [[ $VIRTUAL_ENV ]] || return

    print -r -- ${VIRTUAL_ENV:h}/project(@N:P)
}

# Prepend each script with a shebang for its folder's associated venv interpreter.
# If 'vpy' exists in the PATH, '#!/path/to/vpy' will be used instead.
# Also ensures the script is executable.
# --py may be used, same as for envin.
vpyshebang () {  # [--py 2|pypy|current] <script>...
    emulate -L zsh
    if [[ $1 == --help ]] { zpy $0; return }

    local venv_name=venv
    if [[ $1 == --py ]] {
        local reply
        if ! { .zpy_argvenv $2 } { zpy $0; return 1 }
        venv_name=$reply[1]; shift 2
    }

    if [[ ! $1 ]] { zpy $0; return 1 }

    local vpyscript
    if [[ $venv_name == venv ]] vpyscript=$commands[vpy]

    local shebang REPLY lines
    for 1 {
        zf_chmod 0755 $1
        if [[ $vpyscript ]] {
            shebang="#!${vpyscript}"
        } else {
            .zpy_whichvpy $venv_name $1 || return
            shebang="#!${REPLY}"
        }
        lines=("${(@f)$(<$1)}")
        if [[ $lines[1] != $shebang ]] {
            print -rl -- "${shebang}" "${(@)lines}" >$1
        }
    }
}

# Run command in a subshell with <venv>/bin for the given project folder prepended to the PATH.
# Use --cd to run the command from within the project folder.
# --py may be used, same as for envin.
# With --activate, activate the venv (usually unnecessary, and slower).
vrun () {  # [--py 2|pypy|current] [--cd] [--activate] <proj-dir> <cmd> [<cmd-arg>...]
    emulate -L zsh
    if [[ $1 == --help ]] { zpy $0; return }

    local do_enter do_activate activate_args=() projdir
    while [[ $1 == --(py|cd|activate) ]] {
        if [[ $1 == --cd       ]] { do_enter=1;            shift   }
        if [[ $1 == --activate ]] { do_activate=1;         shift   }
        if [[ $1 == --py       ]] {
            if ! { .zpy_argvenv $2 } { zpy $0; return 1 }
                                    activate_args=($1 $2); shift 2 }
    }
    if ! [[ $2 && $1 ]] { zpy $0; return 1 }
                                    projdir=${1:a};        shift

    zf_mkdir -p $projdir
    (
        set -e

        if [[ $do_enter    ]] cd $projdir

        if [[ $do_activate ]] {
            activate $activate_args $projdir
        } else {
            vname=venv
            if [[ $activate_args ]] {
                .zpy_argvenv $activate_args[2]
                vname=$reply[1]
            }

            .zpy_venvs_path $projdir
            vpath=$REPLY

            if [[ -d $vpath/$vname/bin ]] { path=($vpath/$vname/bin $path)
            } else                        { activate $activate_args $projdir }
        }

        $@
    )
}

# Run script with the python from its folder's venv.
# --py may be used, same as for envin.
vpy () {  # [--py 2|pypy|current] [--activate] <script> [<script-arg>...]
    emulate -L zsh
    if [[ $1 == --help ]] { zpy $0; return }

    local vrun_args=()
    while [[ $1 == --(py|activate) ]] {
        if [[ $1 == --py       ]] { vrun_args+=($1 $2); shift 2 }
        if [[ $1 == --activate ]] { vrun_args+=($1);    shift   }
    }

    if [[ ! $1 ]] { zpy $0; return 1 }

    vrun $vrun_args ${1:a:h} python ${1:a} ${@[2,-1]}
}


# Make a launcher script for a command run in a given project's activated venv.
# With --link-only, only create a symlink to <venv>/bin/<cmd>,
# which should already have the venv's python in its shebang line.
vlauncher () {  # [--link-only] [--py 2|pypy|current] <proj-dir> <cmd> <launcher-dest>
    emulate -L zsh
    if [[ $1 == --help ]] { zpy $0; return }

    local linkonly venv_name=venv reply
    while [[ $1 == --(link-only|py) ]] {
        if [[ $1 == --link-only ]] { linkonly=1;          shift   }
        if [[ $1 == --py        ]] {
            if ! { .zpy_argvenv $2 } { zpy $0; return 1 }
                                     venv_name=$reply[1]; shift 2 }
    }

    if ! [[ $3 && $2 && $1 ]] { zpy $0; return 1 }

    local projdir=${1:P} cmd=$2 dest=${3:a}
    if [[ -d $dest ]] dest=$dest/$cmd

    if [[ -e $dest ]] {
        .zpy_log error "ABORTING because the destination exists" "${dest/#~\//~/}" "${projdir/#~\//~/}"
        return 1
    }

    local REPLY venv
    .zpy_venvs_path $projdir || return
    venv=${REPLY}/${venv_name}

    if [[ $linkonly ]] {
        local cmdpath=${venv}/bin/${cmd}

        if [[ ! -x $cmdpath ]] {
            .zpy_log error 'FAILED to find executable' "${cmdpath/#~\//~/}" "${projdir/#~\//~/}"
            return 1
        }

        zf_ln -s "${cmdpath}" $dest
    } else {
        print -rl -- '#!/bin/sh -e' ". ${venv}/bin/activate" "exec $cmd \$@" >$dest
        zf_chmod 0755 $dest
    }
}

# Delete venvs for project folders which no longer exist.
prunevenvs () {  # [-y]
    emulate -L zsh
    if [[ $1 == --help ]] { zpy $0; return }
    [[ $ZPY_VENVS_WORLD ]] || return

    local noconfirm
    if [[ $1 == -y ]] noconfirm=1

    local proj REPLY orphaned_venv
    for proj ( ${ZPY_VENVS_WORLD}/*/project(@N:P) ) {
        if [[ ! -d $proj ]] {
            .zpy_venvs_path $proj || return
            orphaned_venv=$REPLY

            print -rl "Missing: ${proj/#~\//~/}" "Orphan: $(du -hs $orphaned_venv)"
            if [[ $noconfirm ]] {
                zf_rm -rf $orphaned_venv
            } else {
                if { read -q "?Delete orphan? [yN] " } {
                    zf_rm -rf $orphaned_venv
                }
                print '\n'
            }
        }
    }
}

.zpy_pipcheckoldcells () {  # [--py 2|pypy|current] <proj-dir>
    emulate -L zsh

    local vrun_args=()
    if [[ $1 == --py ]] { vrun_args+=($1 $2); shift 2 }
    [[ -d $1 ]] || return
    vrun_args+=($1)

    rehash

    local cells=()
    if (( $+commands[jq] )) {
        cells=($(
            vrun $vrun_args python -m pip --disable-pip-version-check list -o --format json \
            | jq -r '.[] | select(.name|test("^(setuptools|six|pip|pip-tools)$")|not) | .name,.version,.latest_version'
        ))
    } elif (( $+commands[jello] )) {
        cells=($(
            vrun $vrun_args python -m pip --disable-pip-version-check list -o --format json \
            | jello -r '" ".join(" ".join((pkg["name"], pkg["version"], pkg["latest_version"])) for pkg in _ if pkg["name"] not in ("setuptools", "six", "pip", "pip-tools"))'
        ))
    } elif (( $+commands[wheezy.template] )) {
        local template=(
            '@require(_)'

            '@for pkg in _:'
            '@if pkg["name"] not in ("setuptools", "six", "pip", "pip-tools"):'

            '@pkg["name"]'
            '@pkg["version"]'
            '@pkg["latest_version"]'

            '@end'
            '@end'
        )
        cells=($(
            wheezy.template =(<<<${(F)template}) \
            =(<<<"{\"_\": $(vrun $vrun_args python -m pip --disable-pip-version-check list -o --format json)}")
        ))
    } else {
        local lines=(${(f)"$(vrun $vrun_args python -m pip --disable-pip-version-check list -o)"})
        lines=($lines[3,-1])
        lines=(${lines:#(setuptools|six|pip|pip-tools) *})

        local line line_cells
        for line ( $lines ) {
            line_cells=(${(z)line})
            cells+=(${line_cells[1,3]})
        }
    }
    #    (package, version, latest)
    # -> (package, version, latest, proj-dir)
    local i proj_cell="${${1:P}/#~\//~/}"
    for (( i=3; i<=$#cells; i+=4 )) {
        cells[i]+=("$proj_cell")
    }

    print -rl -- $cells
}

# 'pip list -o' for all or specified projects.
pipcheckold () {  # [--py 2|pypy|current] [<proj-dir>...]
    emulate -L zsh
    if [[ $1 == --help ]] { zpy $0; return }
    [[ $ZPY_PROCS        ]] || return
    [[ $ZPY_VENVS_WORLD ]] || return

    local extra_args=()
    if [[ $1 == --py ]] {
        extra_args+=($1 $2); shift 2
    }
    local cells=(
        "%BPackage%b"
        "%BVersion%b"
        "%BLatest%b"
        "%BProject%b"
    )
    if ! [[ -v NO_COLOR ]] cells=(%F{cyan}${^cells}%f)
    cells+=(${(f)"$(
        zargs -P $ZPY_PROCS -rl \
        -- ${@:-${ZPY_VENVS_WORLD}/*/project(@N-/)} \
        -- .zpy_pipcheckoldcells $extra_args
    )"})

    if [[ $#cells -gt 4 ]] {
        print -rPaC 4 -- $cells
    }
}

.zpy_pipup () {  # [--py 2|pypy|current] [--faildir <faildir>] [--only-sync-if-changed] <proj-dir>
    emulate -L zsh

    local faildir activate_args=() only_sync_if_changed
    while [[ $1 == --(faildir|py|only-sync-if-changed) ]] {
        if [[ $1 == --faildir              ]] { faildir=${2:a};          shift 2 }
        if [[ $1 == --py                   ]] { activate_args+=($1 $2);  shift 2 }
        if [[ $1 == --only-sync-if-changed ]] { only_sync_if_changed=$1; shift   }
    }

    [[ $1 ]] || return

    local ret
    (
        set -e

        cd $1
        activate $activate_args 2>/dev/null

        pipcs -U $only_sync_if_changed
    )
    ret=$?

    if (( ret )) && [[ $faildir ]] print -n >>$faildir/${1:t}

    return ret
}

# 'pipcs -U' (upgrade-compile, sync) for all or specified projects.
pipup () {  # [--py 2|pypy|current] [--only-sync-if-changed] [<proj-dir>...]
    emulate -L zsh
    # TODO: should this get an interactive mode? YES
    # maybe interactive without projdir, and add --all?
    # or without projdir use cwd, and have --all and -i, probably.
    # lemme think:

    # things that might have --allprojects (--all):
    # zpy (not projs actually)
    # pipup
    # pipcheckold
    # pipz upgrade|reinstall|uninstall|list (names which are really projs)

    # things that might have --interactive (-i):
    # zpy (not projs)
    # venvs_path
    # pipup
    # activate
    # vrun
    # vlauncher
    # pipcheckold
    # pipz cd|inject|runpip|upgrade|reinstall|uninstall|list (names which are really projs)

    # overlap, and projs only:
    # pipup:          currently default-all, TODO: default-cwd, add --all, add -i
    # pipcheckold:    currently default-all, TODO: default-cwd, add --all, add -i
    # pipz upgrade:   currently default-int, TODO: nothing (has --all)
    # pipz reinstall: currently default-int, TODO: nothing (has --all)
    # pipz uninstall: currently default-int, TODO: nothing (has --all)
    # pipz list:      currently default-all, TODO: MAYBE: default-int, add --all (see how fast we can get it...)

    # TODO: maybe drop sublp

    if [[ $1 == --help ]] { zpy $0; return }
    [[ $ZPY_PROCS        ]] || return
    [[ $ZPY_VENVS_WORLD ]] || return

    local extra_args=()
    while [[ $1 == --(py|only-sync-if-changed) ]] {
        if [[ $1 == --py                   ]] { extra_args+=($1 $2); shift 2 }
        if [[ $1 == --only-sync-if-changed ]] { extra_args+=($1);    shift   }
    }

    local faildir=$(mktemp -d) failures=()
    zargs -P $ZPY_PROCS -rl \
    -- ${@:-${ZPY_VENVS_WORLD}/*/project(@N-/:P)} \
    -- .zpy_pipup $extra_args --faildir $faildir
    failures=($faildir/*(N:t))
    zf_rm -rf $faildir

    # TODO: hold diff output until HERE?

    if [[ $failures ]] {
        .zpy_log error "FAILED $0 call; Problems upgrading" $failures
        return 1
    }
}

# Inject loose requirements.in dependencies into a flit-flavored pyproject.toml.
# Run either from the folder housing pyproject.toml, or one below.
# To categorize, name files <category>-requirements.in.
pypc () {
    emulate -L zsh
    if [[ $1 == --help ]] { zpy $0; return }

    pipi --no-upgrade -q tomlkit
    local ret=$?

    if (( ret )) { .zpy_please_activate tomlkit; return ret }

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

    local spfile spfiles=(*.sublime-project(N))
    if [[ ! $spfiles ]] {
        spfile=${PWD:t}.sublime-project
        >$spfile <<<'{}'
    } else {
        spfile=$spfiles[1]
    }

    REPLY=$spfile
}

.zpy_insertjson () {  # <jsonfile> <value> <keycrumb>...
    # Does not currently handle spaces within any keycrumb (or need to)
    emulate -L zsh
    rehash

    local jsonfile=$1; shift
    local value=$1; shift

    zf_mkdir -p ${jsonfile:h}
    [[ -r $jsonfile ]] || >$jsonfile <<<'{}'

    if (( $+commands[jq] )) {
        local keypath=".\"${(j:".":)@}\""
        if [[ $value != (true|false) ]] value=${(qqq)value}
        # TODO: is this a useless print/subshell? Why not just jq?
        print -r -- "$(
            jq --argjson val "$value" "${keypath}=\$val" "$jsonfile"
        )" >$jsonfile
    } elif (( $+commands[dasel] )) {
        local keypath=".${(j:.:)@}"
        local vartype=string
        if [[ $value == (true|false) ]] vartype=bool
        dasel put $vartype -f $jsonfile -p json $keypath $value
    } else {
        python3 -c "
from collections import defaultdict
from json import loads, dumps
from pathlib import Path


jsonfile = Path('''${jsonfile}''')

deepdefaultdict = lambda: defaultdict(deepdefaultdict)
data = defaultdict(deepdefaultdict)
data.update(loads(jsonfile.read_text()))

keycrumbs = '''${(j: :)@}'''.split()
d = data
for key in keycrumbs[:-1]:
    d = d[key]
if '''${value}''' in ('true', 'false'):
    d[keycrumbs[-1]] = ${(C)value}
else:
    d[keycrumbs[-1]] = '''${value}'''

jsonfile.write_text(dumps(data, indent=4))
        "
    }
}

# Specify the venv interpreter for the working folder in a new or existing json file.
.zpy_vpy2json () {  # [--py 2|pypy|current] <jsonfile> <keycrumb>...
    # Does not currently handle spaces within any keycrumb (or need to)
    emulate -L zsh
    if [[ $1 == --help ]] { zpy $0; return }

    local venv_name=venv
    if [[ $1 == --py ]] {
        local reply
        if ! { .zpy_argvenv $2 } { zpy $0; return 1 }
        venv_name=$reply[1]
        shift 2
    }

    local jsonfile=$1; shift

    local REPLY pypath
    .zpy_venvs_path || return
    pypath=${REPLY}/${venv_name}/bin/python

    .zpy_log action injecting "${jsonfile/#~\//~/}" "interpreter ${pypath/#~\//~/}"

    .zpy_insertjson $jsonfile $pypath $@
}

# Specify the venv interpreter in a new or existing Sublime Text project file for the working folder.
vpysublp () {  # [--py 2|pypy|current]
    emulate -L zsh
    if [[ $1 == --help ]] { zpy $0; return }

    local REPLY jsonfile
    .zpy_get_sublp
    jsonfile=$REPLY

    .zpy_vpy2json $@ $jsonfile settings python_interpreter
}

# Specify the venv interpreter in a new or existing [VS]Code settings file for the working folder.
vpyvscode () {  # [--py 2|pypy|current]
    emulate -L zsh
    if [[ $1 == --help ]] { zpy $0; return }

    local jsonfile=$PWD/.vscode/settings.json

    .zpy_vpy2json $@ $jsonfile python.defaultInterpreterPath
}

# Specify the venv interpreter in a new or existing Pyright settings file for the working folder.
vpypyright () {  # [--py 2|pypy|current]
    emulate -L zsh
    if [[ $1 == --help ]] { zpy $0; return }

    local jsonfile=$PWD/pyrightconfig.json

    local venv_name=venv
    if [[ $1 == --py ]] {
        local reply
        if ! { .zpy_argvenv $2 } { zpy $0; return 1 }
        venv_name=$reply[1]
    }

    local REPLY vpath
    .zpy_venvs_path || return
    vpath=$REPLY

    .zpy_log action injecting "${jsonfile/#~\//~/}" "venv ${vpath/#~\//~/}/$venv_name"

    .zpy_insertjson $jsonfile $vpath venvPath
    .zpy_insertjson $jsonfile $venv_name venv
    .zpy_insertjson $jsonfile true useLibraryCodeForTypes
}

# Launch a new or existing Sublime Text project for the working folder, setting venv interpreter.
sublp () {  # [--py 2|pypy|current] [<subl-arg>...]
    # would it be worth it to accept --py later, aside from as first flag?
    emulate -L zsh
    if [[ $1 == --help ]] { zpy $0; return }

    local vpysublp_args=()
    if [[ $1 == --py ]] { vpysublp_args=($1 $2); shift 2 }

    vpysublp $vpysublp_args

    local REPLY
    .zpy_get_sublp
    subl --project "$REPLY" $@
}

.zpy_is_under () {  # <kid_path> <ok_parent>...
    emulate -L zsh
    [[ $2 && $1 ]] || return

    local kid=${1:a}; shift

    for 1 {
        if [[ $kid == ${1:a} ]] return
        if [[ $kid == ${${1:a}%/}/* ]] return
    }

    return 1
}

.zpy_diffsnapshot () {  # <snapshot-dir>
    emulate -L zsh
    [[ -d $1 ]] || return

    local origtxts=(${1:a}/**/*(DN.))
    local txts=(${origtxts#${1:a}})

    local origtxt txt lines=() label
    for origtxt txt ( ${origtxts:^txts} ) {
        label=${txt:a:h:h:t}/${txt:a:h:t}${${txt:a:h:t}:+/}${txt:t}
        lines=(${(f)"$(
            diff -wu -L $label $origtxt -L $label $txt
        )"})
        if (( ? )) {
            lines=(${(M)lines:#[-+@][^ ]*})
            .zpy_hlt diff <<<${(F)lines}
        }
    }
}

.zpy_pipzlistrow () {  # <projects_home> <bin>
    # TODO: Still a bit slow (roughly 'pip list' * app-count)
    emulate -L zsh -o extendedglob
    [[ $2 && $1 ]] || return

    local projects_home bin plink pdir
    projects_home=${1:a}
    bin=$2
    plink=${bin:P:h:h:h}/project
    pdir=${plink:P}

    if [[ ! -L $plink ]] || { ! .zpy_is_under $pdir $projects_home } return
    # if [[ -L $plink ]] && { .zpy_is_under $pdir $projects_home } {

    rehash

    local piplistline=()
    if (( $+commands[jq] )) {
    # Slower than the pure ZSH fallback below?
        piplistline=($(
            vrun $pdir python -m pip --disable-pip-version-check list --pre --format json \
            | jq -r '.[] | select(.name|test("^'${${${pdir:t}//[^[:alnum:].]##/-}:gs/./\\\\.}'$"; "i")) | .name,.version'
        ))
    } elif (( $+commands[jello] )) {
        # Slower than the pure ZSH fallback below?
        piplistline=($(
            vrun $pdir python -m pip --disable-pip-version-check list --pre --format json \
            | jello -lr '[pkg["name"] + " " + pkg["version"] for pkg in _ if pkg["name"].lower() == "'${${pdir:t}//[^[:alnum:].]##/-}'"]'
        ))
    } elif (( $+commands[wheezy.template] )) {
        # Slower than the pure ZSH fallback below?
        local template=(
            '@require(_)'

            '@for pkg in _:'
            '@if pkg["name"].lower() == "'${${pdir:t}//[^[:alnum:].]##/-}'":'

            '@pkg["name"]'
            '@pkg["version"]'

            '@end'
            '@end'
        )
        piplistline=($(
            wheezy.template =(<<<${(F)template}) \
            =(<<<"{\"_\": $(vrun $pdir python -m pip --disable-pip-version-check list --pre --format json)}")
        ))
    } else {
        local lines=(${(f)"$(
            vrun $pdir python -m pip --disable-pip-version-check list --pre
        )"})
        lines=($lines[3,-1])
        piplistline=(${(zM)lines:#(#i)${${pdir:t}//[^[:alnum:].]##/-} *})
    }
    # Preserve the table layout in case something goes surprising and we don't get a version cell:
    piplistline+=('????')
    # TODO: don't do that. handle empty results.

    local pyverlines=(${(f)"$(
        vrun $pdir python -V
    )"})

    # This may be a bit faster, but less accurate
    # local venvcfg=${plink:h}/venv/pyvenv.cfg
    # if [[ -r $venvcfg ]] {
    #     local cfglines=(${(f)"$(<$venvcfg)"})
    #     local pyverlines=(${${(M)cfglines:#version = *}##version = })
    # } else {
    #     local pyverlines=(${(f)"$(
    #         vrun $pdir python -V
    #     )"})
    # }

    print -rl -- "${bin:t}" "${piplistline[1,2]}" "${pyverlines[-1]}"
    # }
}

.zpy_pkgspec2name () {  # <pkgspec>
    emulate -L zsh
    unset REPLY
    [[ $1 ]] || return

    local pkgspec=${1##*\#egg=}
    # NOTE: this could break on comments, though irrelevant when used by pipz as we do
    # e.g. 'pipz install "<url>#egg=<name>  # hey look at me"'

    local badspec
    if [[ $pkgspec == (git|hg|bzr|svn)+* ]] {
        badspec=1
    } else {
        REPLY=${${(j: :)${${(s: :)pkgspec:l}:#-*}}%%[ \[<>=#~;@&]*}
    }

    if [[ $badspec || ! $REPLY ]] {
        .zpy_log error 'FAILED to parse pkgspec' "$1" \
            'https://www.python.org/dev/peps/pep-0508/#examples' \
            'https://pip.pypa.io/en/stable/reference/pip_install/#vcs-support'
        return 1
    }
}

.zpy_all_replies () {  # <func> <arg>...
    emulate -L zsh
    reply=()
    [[ $2 && $1 ]] || return

    local REPLY f=$1; shift
    for 1 { $f $1 || return; reply+=($REPLY) }
}

.zpy_pipzinstallpkg () {  # [--faildir <faildir>] <projects_home> <pkgspec>
    emulate -L zsh

    local faildir
    if [[ $1 == --faildir ]] { faildir=${2:a}; shift 2 }

    [[ $2 && $1 ]] || return

    local projects_home pkg
    projects_home=${1:a}
    pkg=$2

    local REPLY pkgname
    if ! { .zpy_pkgspec2name $pkg } {
        if [[ $faildir ]] print -n >>$faildir/$pkgname
        return 1
    }
    pkgname=$REPLY

    local ret
    # TODO: this is stepping on its own toes during zargs parallel calls:
    # zf_mkdir -p ${projects_home}/${pkgname}
    # Here's a workaround with a retry:
    zf_mkdir -p ${projects_home}/${pkgname} 2>/dev/null \
    || zf_mkdir -p ${projects_home}/${pkgname}
    # How many retries needed for decent probabilities?
    # Fixed by patch to zsh:
    # https://gist.githubusercontent.com/phy1729/0d4519e15a37a31c5b917a895693b4b4/raw/8b42f5ba766e20b1357900c2bd146b0a8cb92485/gistfile1.txt
    # If only zsh had a public bug tracker to follow. Bug exists in zsh 5.8.
    (
        set -e

        cd ${projects_home}/${pkgname}
        zf_rm -f requirements.{in,txt}
        activate
        pipacs $pkg
    )
    ret=$?

    if (( ret )) && [[ $faildir ]] print -n >>$faildir/$pkgname

    return ret
}

.zpy_pipzchoosepkg () {  # [--header <header>] [--multi] <projects_home>  ## <header> default: 'Packages:'
    emulate -L zsh
    # TODO: fzf OR skim OR fzy OR peco
    [[ -r $ZPY_SRC ]] || return

    local fzf_args=() fzf_header fzf_prompt multi
    fzf_args=(--reverse -0)
    fzf_header='Packages:'
    fzf_prompt='Which package? '
    while [[ $1 == --(header|multi) ]] {
        if [[ $1 == --header ]] { fzf_header=$2;           shift 2 }
        if [[ $1 == --multi  ]] {
                                  fzf_prompt='Which packages? Choose one with <enter> or more with <tab>. '
                                  fzf_args+=(-m); multi=1; shift   }
    }

    if [[ $multi ]] {
        unset reply
    } else {
        unset REPLY
        local reply
    }

    [[ $1 ]] || return

    local pkgs=($1/*(/:t))
    fzf_args+=(--preview="zsh -fc '. $ZPY_SRC; .zpy_hlt ini <$1/{}/*'")
    reply=(${(f)"$(
        print -rln -- $pkgs \
        | fzf $fzf_args --header=$fzf_header --prompt=$fzf_prompt
    )"})

    [[ $reply ]] || return

    if [[ ! $multi ]] REPLY=$reply[1]
}

.zpy_pipzunlinkbins () {  # <projects_home> <bins_home> <pkgspec>...
    emulate -L zsh
    [[ $3 && $2 && $1 ]] || return

    local projects_home bins_home
    projects_home=$1; shift
    bins_home=$1;     shift

    local reply vpaths=()
    .zpy_all_replies .zpy_pkgspec2name $@ || return
    .zpy_all_replies .zpy_venvs_path ${projects_home}/${^reply} || return
    vpaths=($reply)

    local binlinks=() REPLY
    binlinks=(${bins_home}/*(@Ne['.zpy_is_under ${REPLY:P} $vpaths']))

    if [[ $binlinks ]] zf_rm $binlinks

    rehash
}

.zpy_pipzrmvenvs () {  # <projects_home> <bins_home> <pkgspec>...
    emulate -L zsh
    [[ $3 && $2 && $1 ]] || return

    local projects_home bins_home
    projects_home=$1; shift
    bins_home=$1;     shift

    local REPLY
    for 1 {
        .zpy_pkgspec2name $1 || return
        .zpy_venvs_path ${projects_home}/${REPLY} || return
        zf_rm -rf $REPLY
    }
}

.zpy_pipzlinkbins () {  # <projects_home> <bins_home> [--[no-]cmd <cmd>[,<cmd>...]] [--activate] [--auto1] [--header <fzf_header>] <pkgspec>...
    emulate -L zsh

    local projects_home bins_home
    projects_home=$1; shift
    bins_home=$1;     shift

    local bins_whitelist=() bins_blacklist=() linkonly=1 fzf_args=(--reverse -m -0) fzf_header=Installing
    while [[ $1 == --(cmd|activate|no-cmd|auto1|header) ]] {
        if [[ $1 == --cmd      ]] { bins_whitelist=(${(s:,:)2}); shift 2 }
        if [[ $1 == --no-cmd   ]] { bins_blacklist=(${(s:,:)2}); shift 2 }
        if [[ $1 == --activate ]] { unset linkonly;              shift   }
        if [[ $1 == --auto1    ]] { fzf_args+=(-1);              shift   }
        if [[ $1 == --header   ]] { fzf_header=$2;               shift 2 }
    }

    [[ $1 && $bins_home && $projects_home ]] || return

    zf_mkdir -p $bins_home

    local pkgname projdir vpath bins bin REPLY
    for 1 {
        .zpy_pkgspec2name $1 || return
        pkgname=$REPLY

        projdir=${projects_home}/${pkgname}

        .zpy_venvs_path $projdir || return
        vpath=$REPLY

        bins=("${vpath}/venv/bin/"*(N:t))
        if [[ $bins_whitelist ]] {
            bins=(${bins:*bins_whitelist})
        } else {
            bins=(${bins:|bins_blacklist})
            bins=(${bins:#([aA]ctivate(|.csh|.fish|.ps1)|easy_install(|-<->*)|(pip|python|pypy)(|<->*)|*.so|__pycache__)})
            if [[ $pkgname != pip-tools ]] bins=(${bins:#pip-(compile|sync)})
            if [[ $pkgname != wheel     ]] bins=(${bins:#wheel})
            if [[ $pkgname != chardet   ]] bins=(${bins:#chardetect})
            bins=(${(f)"$(
                print -rln $bins \
                | fzf $fzf_args --header="$fzf_header $1 . . ." \
                --prompt='Which scripts should be added to the path? Choose one with <enter> or more with <tab>. '
            )"})
        }
# TODO: in .zpy_print... shorten venv paths: ~/.local/share/venvs/45a…/venv
# vpath_parts=("${(s:/:)vpath}")
# vpath_parts[-2]=${vpath_parts[-2][1,3]}…
# vpath=${(j:/:)vpath_parts}
        for bin ( $bins ) {
            if [[ $linkonly ]] {
                vlauncher --link-only $projdir $bin $bins_home
            } else {
                zf_mkdir -p ${vpath}/venv/pipz_launchers
                vlauncher $projdir $bin ${vpath}/venv/pipz_launchers
                zf_ln -s ${vpath}/venv/pipz_launchers/${bin} $bins_home/
            }
        }
    }

    rehash
}

# TODO: policy: namespace private funcs as '.zpy_kebab-case'

# TODO: readme: links to doc pages, as alphabetical grid:
#              pipcs        vlauncher
#             pipi         vpy
# activate (a8)            pips         vpypyright
# envin          pipup        vpyshebang
# envout (da8)         pipz         vpysublp
# pipa           prunevenvs   vpyvscode
# pipac          pypc         vrun
# pipacs         reqshow      whichpyproj
# pipc           sublp        zpy
# pipcheckold    venvs_path

# envin flyover
# pipa
# pipc
# pips
# pipacs
# pipac
# pipcs -U

# venvs_path
# envin detail
# envout (da8)
# activate (a8)

# vpy
# vpyshebang
# vlauncher
# vrun

# vpysublp
# vpyvscode
# vpypyright
# pypc

# pipz

# pipcheckold
# pipup
# sublp  # TODO: hmmm, drop it? vpysublp enough?
# pipi
# reqshow
# zpy
# prunevenvs
# whichpyproj  # TODO: probably kill/privatize whichpyproj.... maybe



# Package manager for venv-isolated scripts (pipx clone; py3 only).
pipz () {  # [install|uninstall|upgrade|list|inject|reinstall|cd|runpip|runpkg] [<subcmd-arg>...]
    emulate -L zsh +o promptsubst -o globdots -o localtraps +o monitor
    [[ $ZPY_PIPZ_PROJECTS && $ZPY_PIPZ_BINS && $ZPY_VENVS_WORLD && $ZPY_PROCS ]] || return

    local reply REPLY
    local subcmds=(
        install     "Install apps from PyPI or filesystem into isolated venvs"
        uninstall   "Remove apps"
        upgrade     "Install newer versions of apps and their dependencies"
        list        "Show each installed app with its version, commands, and Python runtime"
        inject      "Add extra packages to an installed app's isolated venv"
        reinstall   "Reinstall apps, preserving any version specs and package injections"
        cd          "Enter or run a command from an app's project (requirements.{in,txt}) folder"
        runpip      "Run pip from the venv of an installed app"
        runpkg      "Install an app temporarily and run it immediately"
    )
    case $1 {
    subcommands)
        rEpLy=($subcmds)
        return
    ;;
    --help)
        zpy $0
        local i
        for ((i=1; i<$#subcmds; i+=2)) {
            print
            zpy "$0 $subcmds[i]"
        }
        return
    ;;
    install)  # [--cmd <cmd>[,<cmd>...]] [--activate] <pkgspec>...  ## subcmd: pipz install
    # Without --cmd, interactively choose.
    # Without --activate, 'vlauncher --link-only' is used.
        if [[ $2 == --help ]] { zpy "$0 $1"; return }
        shift

        local linkbins_args=($ZPY_PIPZ_PROJECTS $ZPY_PIPZ_BINS --auto1)
        while [[ $1 == --(cmd|activate) ]] {
            if [[ $1 == --cmd      ]] { linkbins_args+=($1 $2); shift 2 }
            if [[ $1 == --activate ]] { linkbins_args+=($1);    shift   }
        }

        if [[ ! $1 ]] { zpy "$0 install"; return 1 }

        local faildir=$(mktemp -d) failures=()
        zargs -P $ZPY_PROCS -rl \
        -- $@ \
        -- .zpy_pipzinstallpkg --faildir $faildir $ZPY_PIPZ_PROJECTS
        failures=($faildir/*(N:t))
        zf_rm -rf $faildir
        # TODO: could skip linkbins for failures, but is that desirable?
        # new array: pkgspec2name each $@
        # filter array: ${arr:|failures}
        .zpy_pipzlinkbins $linkbins_args $@

        if [[ $failures ]] {
            .zpy_log error "FAILED to ($0) install" $failures
            return 1
        }
    ;;
    uninstall)  # [--all|<pkgname>...]  ## subcmd: pipz uninstall
    # Without args, interactively choose.
        if [[ $2 == --help ]] { zpy "$0 $1"; return }
        shift
        if [[ $1 == --all ]] { pipz uninstall ${ZPY_PIPZ_PROJECTS}/*(/:t); return }

        local pkgs=()
        if [[ $@ ]] { pkgs=($@) } else {
            .zpy_pipzchoosepkg --multi --header 'Uninstalling . . .' $ZPY_PIPZ_PROJECTS || return
            pkgs=($reply)
        }

        .zpy_pipzunlinkbins $ZPY_PIPZ_PROJECTS $ZPY_PIPZ_BINS $pkgs
        .zpy_pipzrmvenvs $ZPY_PIPZ_PROJECTS $ZPY_PIPZ_BINS $pkgs

        local pkg projdir ret=0
        for pkg ( $pkgs ) {
            .zpy_pkgspec2name $pkg || return
            projdir=${ZPY_PIPZ_PROJECTS}/${REPLY}

            if [[ -d $projdir ]] {
                zf_rm -r $projdir
                # TODO: cluster local var declarations
                # TODO: blacklist -> badlist
                # TODO: whitelist -> goodlist
                # TODO: all op msgs: blue:: projdir%blue
                # TODO: sync op msgs: 'env' -> name of venv
                # TODO: compile op msgs: 'red-> cyan txt' -> 'red-> txt%red'
                # TODO: append op msgs: 'cyan infile' -> 'yellow infile'
            } else {
                .zpy_log error "FAILED to find project for ($0) uninstall" "${projdir/#~\//~/}"
                ret=1
            }
        }  # TODO: all my traps -- do they not exit with interrupt? need to explicitly return?

        return ret
    ;;
    upgrade)  # [--all|<pkgname>...]  ## subcmd: pipz upgrade
    # Without args, interactively choose.
        if [[ $2 == --help ]] { zpy "$0 $1"; return }
        shift
        if [[ $1 == --all ]] { pipz upgrade ${ZPY_PIPZ_PROJECTS}/*(/:t); return }

        local pkgnames=()
        if [[ $@ ]] {
            .zpy_all_replies .zpy_pkgspec2name $@ || return
        } else {
            .zpy_pipzchoosepkg --multi --header 'Upgrading . . .' $ZPY_PIPZ_PROJECTS || return
        }
        pkgnames=($reply)

        # TODO: pipz-list: is the pyver check the slow part? make that a flag, not default?

        pipup --only-sync-if-changed ${ZPY_PIPZ_PROJECTS}/${^pkgnames}
        local ret=$?

        if (( ret )) {
            .zpy_log error "FAILED $0 call" "$0 upgrade $@"
            return ret
        }
    ;;
    list)  # [<pkgname>...]  ## subcmd: pipz list
    # Without args, list all installed.
        if [[ $2 == --help ]] { zpy "$0 $1"; return }
        shift

        print -rPl \
            "projects     %B@%b ${ZPY_PIPZ_PROJECTS/#~\//~/}" \
            "venvs        %B@%b ${ZPY_VENVS_WORLD/#~\//~/}" \
            "apps exposed %B@%b ${ZPY_PIPZ_BINS/#~\//~/}"

        (( ${path[(I)$ZPY_PIPZ_BINS]} )) \
        || print -rP "suggestion%B:%b add %Bpath=(${ZPY_PIPZ_BINS/#~\//~/} \$path)%b to %B~/.zshrc%b"

        print
        print -rC 4 -- ${ZPY_PIPZ_PROJECTS}/*(/N:t)
        print

        local venvs_path_goodlist=()
        if [[ $# -gt 0 ]] {
            .zpy_all_replies .zpy_venvs_path ${ZPY_PIPZ_PROJECTS}/${^@:l} || return
            venvs_path_goodlist=($reply)
        } else {
            venvs_path_goodlist=($ZPY_VENVS_WORLD)
        }

        local bins=(${ZPY_PIPZ_BINS}/*(@Ne['.zpy_is_under ${REPLY:P} $venvs_path_goodlist']))

        local cells=(
            "%BCommand%b"
            "%BPackage%b"
            "%BRuntime%b"
        )
        if ! [[ -v NO_COLOR ]] cells=(%F{cyan}${^cells}%f)
        cells+=(${(f)"$(
            zargs -P $ZPY_PROCS -rl \
            -- $bins \
            -- .zpy_pipzlistrow $ZPY_PIPZ_PROJECTS
        )"})

        local table=()
        if [[ $#cells -gt 3 ]] {
            table=(${(f)"$(print -rPaC 3 -- $cells)"})
            print -- $table[1]
            print -l -- ${(i)table[2,-1]}
        }
    ;;
    reinstall)  # [--cmd <cmd>[,<cmd>...]] [--activate] [--all|<pkgname>...]  ## subcmd: pipz reinstall
    # Without --cmd, interactively choose.
    # Without --activate, 'vlauncher --link-only' is used.
    # Without --all or <pkgspec>, interactively choose.
        if [[ $2 == --help ]] { zpy "$0 $1"; return }
        shift

        local do_all linkbins_args=($ZPY_PIPZ_PROJECTS $ZPY_PIPZ_BINS --auto1)
        while [[ $1 == --(all|cmd|activate) ]] {
            if [[ $1 == --all      ]] { do_all=1;               shift   }
            if [[ $1 == --cmd      ]] { linkbins_args+=($1 $2); shift 2 }
            if [[ $1 == --activate ]] { linkbins_args+=($1);    shift   }
        }

        local pkgs=()
        if [[ $do_all ]] {
            pkgs=(${ZPY_PIPZ_PROJECTS}/*(/N:t))
        } elif [[ $@ ]] {
            pkgs=($@)
        } else {
            .zpy_pipzchoosepkg --multi --header 'Reinstalling . . .' $ZPY_PIPZ_PROJECTS || return
            pkgs=($reply)
        }

        .zpy_pipzunlinkbins $ZPY_PIPZ_PROJECTS $ZPY_PIPZ_BINS $pkgs
        .zpy_pipzrmvenvs $ZPY_PIPZ_PROJECTS $ZPY_PIPZ_BINS $pkgs
        zf_rm -f ${ZPY_PIPZ_PROJECTS}/${^pkgs}/requirements.txt

        zargs -P $ZPY_PROCS -ri___ \
        -- $pkgs \
        -- vrun --activate --cd ${ZPY_PIPZ_PROJECTS}/___ pipcs
        # `pipz upgrade $pkgs` would also work instead of zargs/vrun,
        # but does a few unnecessary things and takes a little longer.
        .zpy_pipzlinkbins $linkbins_args $pkgs
    ;;
    inject)  # [--cmd <cmd>[,<cmd>...]] [--activate] <installed-pkgname> <extra-pkgspec>...  ## subcmd: pipz inject
    # Without --cmd, interactively choose.
    # Without --activate, 'vlauncher --link-only' is used.
        if [[ $2 == --help ]] { zpy "$0 $1"; return }
        shift

        local linkbins_args=($ZPY_PIPZ_PROJECTS $ZPY_PIPZ_BINS)
        while [[ $1 == --(cmd|activate) ]] {
            if [[ $1 == --cmd      ]] { linkbins_args+=($1 $2); shift 2 }
            if [[ $1 == --activate ]] { linkbins_args+=($1);    shift   }
        }
        linkbins_args+=(--header "Injecting [${(j:, :)@[2,-1]}] ->")

        local projdir=${ZPY_PIPZ_PROJECTS}/${1:l}

        if ! [[ $2 && $1 && -d $projdir ]] { zpy "$0 inject"; return 1 }

        local vpath vbinpath badlist=()
        .zpy_venvs_path $projdir || return
        vpath=$REPLY
        vbinpath="${vpath}/venv/bin/"
        badlist=(${vbinpath}*(N:t))

        if [[ $badlist ]] linkbins_args+=(--no-cmd ${(j:,:)badlist})

        (
            set -e
            cd $projdir
            activate
            pipacs ${@[2,-1]}
        )
        .zpy_pipzlinkbins $linkbins_args $1
    ;;
    runpip)  # [--cd] <pkgname> <pip-arg>...  ## subcmd: pipz runpip
    # With --cd, run pip from within the project folder.
        if [[ $2 == --help ]] { zpy "$0 $1"; return }
        shift

        local vrun_args=()
        if [[ $1 == --cd ]] { vrun_args+=($1); shift }

        if ! [[ $2 && $1 ]] { zpy "$0 runpip"; return 1 }

        vrun $vrun_args ${ZPY_PIPZ_PROJECTS}/${1:l} python -m pip ${@[2,-1]}
    ;;
    runpkg)  # <pkgspec> <cmd> [<cmd-arg>...]  ## subcmd: pipz runpkg
        if [[ $2 == --help ]] { zpy "$0 $1"; return   }
        if ! [[ $3 && $2   ]] { zpy "$0 $1"; return 1 }
        shift

        local pkg=$1; shift

        local pkgname projdir vpath venv
        .zpy_pkgspec2name $pkg || return
        pkgname=$REPLY
        projdir=${TMPPREFIX}_pipz/${pkgname}
        .zpy_venvs_path $projdir || return
        vpath=$REPLY
        venv=${vpath}/venv

        [[ -d $venv ]] || python3 -m venv $venv
        zf_ln -sfn $projdir ${vpath}/project
        (
            . $venv/bin/activate
            pipi $pkg -q
            $@
        )
    ;;
    cd)  # [<installed-pkgname> [<cmd> [<cmd-arg>...]]]  ## subcmd: pipz cd
    # Without args (or if pkgname is ''), interactively choose.
    # With cmd, run it in the folder, then return to CWD.
        if [[ $2 == --help ]] { zpy "$0 $1"; return }
        shift

        local projdir
        if [[ $1 ]] {
            projdir=${ZPY_PIPZ_PROJECTS}/${1:l}; shift
        } else {
            .zpy_pipzchoosepkg $ZPY_PIPZ_PROJECTS || return
            projdir=${ZPY_PIPZ_PROJECTS}/${REPLY}

            if [[ $2 ]] shift
        }

        if [[ $1 ]] trap "cd ${(q-)PWD}" EXIT INT QUIT
        cd $projdir
        if [[ $1 ]] $@
    ;;
    *)
        zpy $0
        return 1
    ;;
    }
    # TODO: split subcommands out to 'private' functions. don't forget to update 'zpy "$0 $1"', etc.
}

# Make a standalone script for any zpy function.
.zpy_mkbin () {  # <func> <dest>
    # TODO: flag for standalone copy, or small source-ing script?
    emulate -L zsh
    if [[ $1 == --help ]] { zpy $0; return   }
    if ! [[ $2 && $1   ]] { zpy $0; return 1 }

    local dest=${2:a}
    if [[ -d $dest ]] dest=$dest/$1

    if [[ -e $dest ]] {
        .zpy_log error 'ABORTING because destination exists' "${dest/#~\//~/}"
        return 1
    }

    print -rl -- '#!/bin/zsh' "$(<$ZPY_SRC)" "$1 \$@" >$dest
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
# if { type compdef &>/dev/null } {
if (( $+functions[compdef] )) {

_zpy_helpmsg () {  # funcname
    setopt localoptions extendedglob
    local msg=(${(f)"$(.zpy $1)"})
    msg=(${msg//#(#b)([^#]*)/%B$match[1]%b})
    if ! [[ -v NO_COLOR ]] msg=(${msg//#(#b)(\#*)/%F{blue}$match[1]%f})
    _message -r ${(F)msg}
}

_.zpy_mkbin () {
    _zpy_helpmsg ${0[2,-1]}
    local lines=(${(f)"$(.zpy)"})
    local cmds=(${${(M)lines:#[^# ]*}/ *})
    local pipz_cmd
    local -A rEpLy
    pipz subcommands
    for pipz_cmd ( ${(k)rEpLy} ) cmds+=(${(q-):-"pipz $pipz_cmd"})
    _arguments \
        '(:)--help[Show usage information]' \
        "(--help)1:Function:($cmds)" \
        '(--help)2:Destination:_files'
}
compdef _.zpy_mkbin .zpy_mkbin

_activate () {
    _zpy_helpmsg ${0[2,-1]}
    _arguments \
        '(- 1)--help[Show usage information]' \
        '(--help)--py[Use another interpreter and named venv]:Other Python:(2 pypy current)' \
        '(--help 1)-i[Interactively choose a project]' \
        '(-)1:New or Existing Project:_path_files -/'
}
compdef _activate activate

_envin () {
    _zpy_helpmsg ${0[2,-1]}
    local context state state_descr line opt_args
    _arguments \
        '(- *)--help[Show usage information]' \
        '(--help)--py[Use another interpreter and named venv]:Other Python:(2 pypy current)' \
        '(-)*: :->reqstxts'
    if [[ $state == reqstxts ]] {
        local blacklist=(${line//(#m)[\[\]()\\*?#<>~\^\|]/\\$MATCH})
        _arguments \
            '(-)*:requirements.txt:_files -F blacklist -g "*.txt"'
    }
}
compdef _envin envin

_zpy_pypi_pkg () {
    local reply
    .zpy_pypi_pkgs
    _arguments \
        "*:PyPI Package:($reply)"
    if (( ${@[(I)--or-local]} )) _files
}

_pipa () {
    _zpy_helpmsg ${0[2,-1]}
    local -U catgs=(dev doc test *-requirements.{in,txt}(N))
    catgs=(${catgs%%-*})
    _arguments \
        '(- *)--help[Show usage information]' \
        "(--help)-c[Use <category>-requirements.in]:Category:($catgs)" \
        '(-)*:Package Spec:_zpy_pypi_pkg --or-local'
}
compdef _pipa pipa

_pipc () {
    _zpy_helpmsg ${0[2,-1]}
    local i=$words[(i)--]
    if (( CURRENT > $i )) {
        shift i words
        words=(pip-compile $words)
        (( CURRENT-=i, CURRENT+=1 ))
        _normal -P
        return
    }
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
    if [[ $state == reqsins ]] {
        local blacklist=(${line//(#m)[\[\]()\\*?#<>~\^\|]/\\$MATCH})
        _arguments \
            '*:requirements.in:_files -F blacklist -g "*.in"' \
            '(*)--[pip-compile Arguments]:pip-compile Argument: '
    }
}
compdef _pipc pipc

_pipcs () {
    _zpy_helpmsg ${0[2,-1]}
    local i=$words[(i)--]
    if (( CURRENT > $i )) {
        shift i words
        words=(pip-compile $words)
        (( CURRENT-=i, CURRENT+=1 ))
        _normal -P
        return
    }
    local reply
    .zpy_pypi_pkgs
    local pkgs=($reply)
    local context state state_descr line opt_args
    _arguments \
        '(- *)--help[Show usage information]' \
        '(--help)-h[Include hashes in compiled requirements.txt]' \
        '(--help -u)-U[Upgrade all dependencies]' \
        "(--help -U)-u[Upgrade specific dependencies]:Package Names (comma-separated):_values -s , 'Package Names (comma-separated)' $pkgs" \
        "(--help)--only-sync-if-changed[Don't bother syncing if the lockfile didn't change]" \
        '(-)*: :->reqsins'
    if [[ $state == reqsins ]] {
        local blacklist=(${line//(#m)[\[\]()\\*?#<>~\^\|]/\\$MATCH})
        _arguments \
            '*:requirements.in:_files -F blacklist -g "*.in"' \
            '(*)--[pip-compile Arguments]:pip-compile Argument: '
    }
}
compdef _pipcs pipcs

_pipcheckold () {
    _zpy_helpmsg ${0[2,-1]}
    _arguments \
        '(* -)--help[Show usage information]' \
        '(--help)--py[Use another interpreter and named venv]:Other Python:(2 pypy current)' \
        '(-)*: :_zpy_projects'
}
compdef _pipcheckold pipcheckold

_pipi () {
    _zpy_helpmsg ${0[2,-1]}
    local context state state_descr line opt_args
    _arguments \
        '(- *)--help[Show usage information]' \
        "(--help)--no-upgrade[Don't upgrade already-installed packages]" \
        "(-)*:::Option or Package Spec:->opt_or_pkgspec"
    if [[ $state == opt_or_pkgspec ]] {
        words=(pip install $words)
        (( CURRENT+=2 ))
        _normal
        _zpy_pypi_pkg --or-local
        # TODO: Still quite sloppy... though so is upstream pip completion
        # TODO: Consider filtering out some pip completions
    }
}
compdef _pipi pipi

_pips () {
    _zpy_helpmsg ${0[2,-1]}
    local context state state_descr line opt_args
    _arguments \
        '(- *)--help[Show usage information]' \
        '(--help)*: :->reqstxts'
    if [[ $state == reqstxts ]] {
        local blacklist=(${line//(#m)[\[\]()\\*?#<>~\^\|]/\\$MATCH})
        _arguments \
            '(--help)*:requirements.txt:_files -F blacklist -g "*.txt"'
    }
}
compdef _pips pips

_pipup () {
    _zpy_helpmsg ${0[2,-1]}
    _arguments \
        '(* -)--help[Show usage information]' \
        '(--help)--py[Use another interpreter and named venv]:Other Python:(2 pypy current)' \
        "(--help)--only-sync-if-changed[Don't bother syncing if the lockfile didn't change]" \
        '(-)*: :_zpy_projects'
}
compdef _pipup pipup

_prunevenvs () {
    _zpy_helpmsg ${0[2,-1]}
    _arguments \
        '(-)--help[Show usage information]' \
        "(--help)-y[Don't ask for confirmation]"
}
compdef _prunevenvs prunevenvs

_reqshow () {
    _zpy_helpmsg ${0[2,-1]}
    _arguments \
        '(*)--help[Show usage information]' \
        '(--help)*: :_zpy_projects'
}
compdef _reqshow reqshow

_sublp () {
    _zpy_helpmsg ${0[2,-1]}
    if (( $+_comps[subl] )) {
    # Theoretically may act as false negative, though should be fine for subl
        if (( CURRENT < 3 )) || [[ $words[2] == --py ]] {
            _arguments \
                '(--help)--py[Use another interpreter and named venv]:Other Python:(2 pypy current)'
        }
        $_comps[subl]
    } else {
        _arguments \
            '(- *)--help[Show usage information]' \
            '(--help)--py[Use another interpreter and named venv]:Other Python:(2 pypy current)' \
            '(-)*:File or Folder:_files'
    }
}
compdef _sublp sublp

() {
    emulate -L zsh
    local zpyfn

    for zpyfn ( pypc whichpyproj ) {
        _${zpyfn} () {
            _zpy_helpmsg ${0[2,-1]}
            _arguments '--help[Show usage information]'
        }
        compdef _${zpyfn} $zpyfn
    }

    for zpyfn ( vpysublp vpyvscode vpypyright ) {
        _${zpyfn} () {
            _zpy_helpmsg ${0[2,-1]}
            _arguments \
                '(-)--help[Show usage information]' \
                '(--help)--py[Use another interpreter and named venv]:Other Python:(2 pypy current)'
        }
        compdef _${zpyfn} $zpyfn
    }

    for zpyfn ( pipac pipacs ) {
        _${zpyfn} () {
            _zpy_helpmsg ${0[2,-1]}
            local i=$words[(i)--]
            if (( CURRENT > $i )) {
                shift i words
                words=(pip-compile $words)
                (( CURRENT-=i, CURRENT+=1 ))
                _normal -P
                return
            }
            local -U catgs=(dev doc test *-requirements.{in,txt}(N))
            catgs=(${catgs%%-*})
            local context state state_descr line opt_args
            _arguments \
                '(- * :)--help[Show usage information]' \
                "(--help)-c[Use <category>-requirements.in]:Category:($catgs)" \
                '(--help)-h[Include hashes in compiled requirements.txt]' \
                "(--help -c -h)1:Package Spec:_zpy_pypi_pkg --or-local" \
                '(--help -c -h)*:Package Spec:->pkgspecs'
            if [[ $state == pkgspecs ]] {
                _arguments \
                    '*:Package Spec:_zpy_pypi_pkg --or-local' \
                    '(*)--[pip-compile Arguments]:pip-compile Argument: '
            }
        }
        compdef _${zpyfn} $zpyfn
    }
}

_venvs_path () {
    _zpy_helpmsg ${0[2,-1]}
    _arguments \
        '(- :)--help[Show usage information]' \
        '(--help 1)-i[Interactively choose a project]' \
        '(-)1::Project:_zpy_projects'
        # '(-)1::Project:_path_files -/'
}
compdef _venvs_path venvs_path

_vlauncher () {
    # TODO: Project completions are too lenient (again?)!
    _zpy_helpmsg ${0[2,-1]}
    local context state state_descr line opt_args
    _arguments \
        '(- * :)--help[Show usage information]' \
        '(--help)--link-only[Only create a symlink to <venv>/bin/<cmd>]' \
        '(--help)--py[Use another interpreter and named venv]:Other Python:(2 pypy current)' \
        "(-)1:Project:_zpy_projects" \
        '(-)2: :->cmd' \
        '(-)3:Destination:_path_files -/'
    if [[ $state == cmd ]] {
        local REPLY projdir=${(Q)line[1]/#\~/~}
        .zpy_venvs_path $projdir
        _arguments \
            "*:Command:_path_files -g '$REPLY/venv/bin/*(x:t)'"
    }
}
compdef _vlauncher vlauncher

_vpy () {
    _zpy_helpmsg ${0[2,-1]}
    _arguments \
        '(- : *)--help[Show usage information]' \
        '(--help)--py[Use another interpreter and named venv]:Other Python:(2 pypy current)' \
        "(--help)--activate[Activate the venv (usually unnecessary, and slower)]" \
        '(-)1:Script:_files -g "*.py"' \
        '(-)*:Script Argument: '
}
compdef _vpy vpy

_vpyshebang () {
    _zpy_helpmsg ${0[2,-1]}
    _arguments \
        '(- : *)--help[Show usage information]' \
        '(--help)--py[Use another interpreter and named venv]:Other Python:(2 pypy current)' \
        '(-)*:Script:_files -g "*.py"'
}
compdef _vpyshebang vpyshebang

_zpy_projects () {
    local blacklist=(${line//(#m)[\[\]()\\*?#<>~\^\|]/\\$MATCH})
    # TODO: can I get properly styled "Project" header?
    # TODO: Project completions are too lenient
    _tags globbed-files
    _files -x 'Project:' -F blacklist -/ -g '${ZPY_VENVS_WORLD}/*/project(@N-/:P)'
}

_vrun () {
    # TODO: Project completions are too lenient (again?)!
    setopt localtraps
    _zpy_helpmsg ${0[2,-1]}
    local context state state_descr line opt_args
    integer NORMARG
    _arguments -n \
        '(- * :)--help[Show usage information]' \
        '(--help)--py[Use another interpreter and named venv]:Other Python:(2 pypy current)' \
        '(--help)--cd[Run the command from within the project folder]' \
        "(--help)--activate[Activate the venv (usually unnecessary for venv-installed scripts, and slower)]" \
        '(-)1:Project:_zpy_projects' \
        '(-)*::: :->cmd'
    local vname=venv
    if (( words[(i)--py] < NORMARG )) {
        local reply
        .zpy_argvenv ${words[${words[(i)--py]} + 1]} || return
        vname=$reply[1]
    }
    if [[ $line[1] ]] {
        local projdir=${${(Q)line[1]/#\~/~}:P} REPLY
        .zpy_venvs_path $projdir
        local venv=$REPLY/$vname
        if (( words[(i)--cd] < NORMARG )) {
            trap "cd ${(q-)PWD}" EXIT INT QUIT
            cd $projdir
        }
    }
    if [[ $state == cmd ]] {
        if [[ ${#words} == 1 ]] {

            # Neither of these work:
            # _arguments ":Command:_path_files -g '${venv}/bin/*(Nx:t)'"
            # _arguments "1:Command:_path_files -g '${venv}/bin/*(Nx:t)'"

            # This works, but doesn't inherit existing styling for header message:
            # _path_files -X Command -g "${venv}/bin/*(Nx:t)"

            # Currently settling for this:
            _path_files -g "${venv}/bin/*(Nx:t)"
            # Can I refactor to call _arguments once and still cover this?
            # Can I / should I use a dummy _arguments call to capture the style args, then pass them manually?
        }
        _normal -P
    }
}
compdef _vrun vrun

_zpy () {
    _zpy_helpmsg ${0[2,-1]}
    local lines=(${(f)"$(.zpy)"})
    local cmds=(${${(M)lines:#[^# ]*}/ *})
    local pipz_cmd
    local -A rEpLy
    pipz subcommands
    for pipz_cmd ( ${(k)rEpLy} ) cmds+=(${(q-):-"pipz $pipz_cmd"})
    _arguments \
        '(*)--help[Show usage information]' \
        "(--help)*:Function:($cmds)"
}
compdef _zpy zpy

_pipz () {
    setopt localtraps
    local cmds=() cmd desc
    local -A rEpLy
    ${0[2,-1]} subcommands
    for cmd desc ( ${(kv)rEpLy} ) cmds+=("${cmd}:${desc}")
    integer NORMARG
    local context state state_descr line opt_args
    _arguments \
        '(1 *)--help[Show usage information]' \
        '(--help)1:Operation:(($cmds))' \
        '(--help)*:: :->sub_arg'
    if [[ $state != sub_arg ]] {
        _zpy_helpmsg ${0[2,-1]}
    } else {
        _zpy_helpmsg "$0[2,-1] $line[1]"
        case $line[1] {
        install)
            _arguments \
                '(* -)--help[Show usage information]' \
                '(--help)--cmd[Specify commands to add to your path, rather than interactively choosing]:Command (comma-separated): ' \
                '(--help)--activate[Ensure command launchers explicitly activate the venv (usually unnecessary)]' \
                '(-)*:Package Spec:_zpy_pypi_pkg --or-local'
        ;;
        reinstall)
            local blacklist=(${(Q)words[2,-1]})
            while [[ $blacklist[1] == --(help|activate|all|cmd) ]] {
                if [[ $blacklist[1] == --cmd ]] {
                    blacklist=($blacklist[3,-1])
                } else {
                    blacklist=($blacklist[2,-1])
                }
            }
            local pkgs=($ZPY_PIPZ_PROJECTS/*(/N:t))
            pkgs=(${pkgs:|blacklist})
            _arguments \
                '(* -)--help[Show usage information]' \
                '(--help)--cmd[Specify commands to add to your path, rather than interactively choosing]:Command (comma-separated): ' \
                '(--help)--activate[Ensure command launchers explicitly activate the venv (usually unnecessary)]' \
                '(--help *)--all[Reinstall all installed apps]' \
                "(-)*:Installed Package Name:($pkgs)"
        ;;
        inject)
            _arguments \
                '(* - :)--help[Show usage information]' \
                '(--help)--cmd[Specify commands to add to your path, rather than interactively choosing]:Command (comma-separated): ' \
                '(--help)--activate[Ensure command launchers explicitly activate the venv (usually unnecessary)]' \
                "(-)1:Installed Package Name:($ZPY_PIPZ_PROJECTS/*(/N:t))" \
                '(-)*:Extra Package Spec:_zpy_pypi_pkg --or-local'
        ;;
        uninstall)
            local blacklist=(${(Q)words[2,-1]})
            local pkgs=($ZPY_PIPZ_PROJECTS/*(/N:t))
            pkgs=(${pkgs:|blacklist})
            _arguments \
                '(* -)--help[Show usage information]' \
                '(--help *)--all[Uninstall all installed apps]' \
                "(-)*:Installed Package Name:($pkgs)"
        ;;
        upgrade)
            local blacklist=(${(Q)words[2,-1]})
            local pkgs=($ZPY_PIPZ_PROJECTS/*(/N:t))
            pkgs=(${pkgs:|blacklist})
            _arguments \
                '(* -)--help[Show usage information]' \
                '(--help *)--all[Upgrade all installed apps]' \
                "(-)*:Installed Package Name:($pkgs)"
        ;;
        list)
            local blacklist=(${(Q)words[2,-1]})
            local pkgs=($ZPY_PIPZ_PROJECTS/*(/N:t))
            pkgs=(${pkgs:|blacklist})
            _arguments \
                '(*)--help[Show usage information]' \
                "(--help)*:Installed Package Name:($pkgs)"
        ;;
        runpkg)
            local pkgname REPLY pkgcmd
            if [[ $line[2] ]] {
                .zpy_pkgspec2name ${(Q)line[2]} 2>/dev/null
                pkgname=$REPLY
            }
            pkgcmd=$line[3]
            _arguments \
                '(* :)--help[Show usage information]' \
                '(--help)1:Package Spec:_zpy_pypi_pkg --or-local' \
                "(--help)2:Command:($pkgname)" \
                '(--help)*:::Command Argument:->cmdarg'
            if [[ $state == cmdarg ]] {
                words=($pkgcmd $words)
                (( CURRENT+=1 ))
                _normal -P
            }
        ;;
        runpip)
            _arguments -n \
                '(* - :)--help[Show usage information]' \
                '(--help)--cd[Run pip from within the project folder]' \
                "(-)1:Installed Package Name:($ZPY_PIPZ_PROJECTS/*(/N:t))" \
                '(-)*::: :->pip_arg'
            if [[ $state == pip_arg ]] {
                words=(pip $words)
                (( CURRENT+=1 ))
                _normal -P
            }
        ;;
        cd)
            _arguments \
                '(* :)--help[Show usage information]' \
                "(--help)1:Installed Package Name:($ZPY_PIPZ_PROJECTS/*(/N:t))" \
                '(--help)*::: :->cmd'
            if [[ $state == cmd ]] {
                trap "cd ${(q-)PWD}" EXIT INT QUIT
                cd $ZPY_PIPZ_PROJECTS/${(Q)line[1]:l}
                _normal -P
            }
        ;;
        }
    }
}
compdef _pipz pipz

## TODO: more [-- pip-{compile,sync}-arg...]? (pips pipup 'pipz inject' 'pipz install')
## TODO: revisit instances of 'pipi -q pip-tools' if/when pip-tools gets out-of-venv support:
## https://github.com/jazzband/pip-tools/issues/1087

.zpy_pypi_pkgs () {  # [--refresh]
    emulate -L zsh
    unset reply

    # TODO: maybe I should split these into a few tiers for completion, based on rank (downloads)

    local folder=${XDG_CACHE_HOME:-~/.cache}/zpy

    local json=$folder/pypi.json txt=$folder/pypi.txt

    zf_mkdir -p $folder
    if [[ $1 == --refresh ]] || [[ ! -r $txt ]] {
        if (( $+commands[wget] )) {
            wget -qO $json https://hugovk.github.io/top-pypi-packages/top-pypi-packages-30-days.min.json || return
        } else {
            curl -s -o $json https://hugovk.github.io/top-pypi-packages/top-pypi-packages-30-days.min.json || return
        }
        if (( $+commands[jq] )) {
            jq -r '.rows[].project' <$json >$txt
        } elif (( $+commands[dasel] )) {
            dasel --plain -m -f $json '.rows.[*].project' >$txt
        } elif (( $+commands[jello] )) {
            jello -lr '[p["project"] for p in _["rows"]]' <$json >$txt
        } else {
            python3 -c "
from pathlib import Path
from json import loads


jfile = Path('''${json}''')
tfile = Path('''${txt}''')
data = loads(jfile.read_text())
tfile.write_text('\n'.join(r['project'] for r in data['rows']))
            "
        }
    }
    # reply=("${(fq-)$(<$txt)}")
    reply=(${(f)"$(<$txt)"})
}

}
