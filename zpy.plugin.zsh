autoload -Uz zargs
zmodload -mF zsh/files 'b:zf_(chmod|ln|mkdir|rm)'
zmodload zsh/pcre 2>/dev/null

ZPY_SRC=${0:P}
ZPY_PROCS=${${$(nproc 2>/dev/null):-$(sysctl -n hw.logicalcpu 2>/dev/null)}:-4}

## User may want to override these:
: ${ZPY_VENVS_HOME:=${XDG_DATA_HOME:-~/.local/share}/venvs}
## Each project is associated with: $ZPY_VENVS_HOME/<hash of proj-dir>/<venv-name>
## <venv-name> is one or more of: venv, venv2, venv-pypy, venv-<pyver>
## $(venvs_path <proj-dir>) evals to $ZPY_VENVS_HOME/<hash of proj-dir>
: ${ZPY_PIPZ_PROJECTS:=${XDG_DATA_HOME:-~/.local/share}/python}
: ${ZPY_PIPZ_BINS:=${${XDG_DATA_HOME:-~/.local/share}:P:h}/bin}
## Installing an app via pipz puts requirements.{in,txt} in $ZPY_PIPZ_PROJECTS/<appname>
## and executables in $ZPY_PIPZ_BINS

# Optional launcher for all zpy functions as subcommands
.zpy_ui_zpy () {  # <function> [<function-arg>...]
    emulate -L zsh

    local REPLY
    .zpy_help
    local lines=(${(f)REPLY})
    local cmds=(${${(M)lines:#[^# ]*}/ *})
    cmds=(${cmds:#zpy})

    local subcmds=()
    if ! { zstyle -a :zpy: subcommands subcmds } {
        local ui_cmd
        for ui_cmd ( $cmds ) {
            .zpy_help $ui_cmd
            lines=(${(f)REPLY})
            subcmds+=($ui_cmd ${lines[1]### })
        }
        zstyle ':zpy:*' subcommands $subcmds
    }

    case $1 {
    subcommands)
        rEpLy=($subcmds)
        return
    ;;
    --help)
        .zpy_ui_help ${0[9,-1]}
        return
    ;;
    *)
        if (( ${(k)subcmds[(I)$1]} )) {
            .zpy_ui_${1} ${@[2,-1]}
            return
        }
    ;;
    }
    return 1
}

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
        local diffhi args=()
        for diffhi ( riff delta diff-so-fancy colordiff ) {
            if (( $+commands[$diffhi] )) {
                if [[ $diffhi == riff ]]   args+=(--no-pager)
                if [[ $diffhi == delta ]]  args+=(--paging never --color-only)

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
    } elif (( $+commands[rich] )) {
        local content=$(<&0)
        if [[ $content ]]  rich --force-terminal --no-wrap -W $(( COLUMNS-4 )) --lexer $1 - <<<$content
    } else {
        >&1
    }
}

## fallback basic pcregrep-like func for our needs; not preferred to pcre2grep or ripgrep
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

.zpy_help () {  # [<zpy-function>...]
    emulate -L zsh -o extendedglob
    unset REPLY

    # Multiple commands or subcommands:
    if (( $# > 1 )) {
        local reply
        .zpy_all_replies .zpy_help $@
        REPLY=${(pj:\n\n:)reply}
        return
    }

    # Either all commands or a single command or subcommand:

    local topic=help-${1:-all}
    if { zstyle -s :zpy: $topic REPLY }  return

    [[ -r $ZPY_SRC ]] || return

    local cmds_pattern='^(?P<predoc>\n?(# .*\n)*)(\.zpy_ui_(?P<fname>[^._ \n][^ \n]+) \(\) \{)(  #(?P<usage> .+))?'
    local subcmd_pattern='.*  # (?P<usage>.*)  ## subcmd: <CMD> <SUBCMD>(?P<postdoc>\n( *# [^\n]+\n)*)'

    local cmd_doc=() subcmd_doc=()
    rehash
    if (( $+commands[pcre2grep] )) {
        cmd_doc=(pcre2grep -M -O '$1$4$6')
        subcmd_doc=(pcre2grep -M -O '$1$2')
    } elif { zmodload -e zsh/pcre } {
        cmd_doc=(.zpy_zpcregrep '$1$4$6')
        subcmd_doc=(.zpy_zpcregrep '$1$2')
    } elif (( $+commands[pcregrep] )) {
        cmd_doc=(pcregrep -M -o1 -o4 -o6)
        subcmd_doc=(pcregrep -M -o1 -o2)
    } elif (( $+commands[rg] )) {
        cmd_doc=(rg --no-config --color never -NU -r '$predoc$fname$usage')
        subcmd_doc=(rg --no-config --color never -NU -r '$usage$postdoc')
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

    # All commands or single command (but not a subcommand):
    if [[ ! $1 ]] || (( ! ${1[(I) ]} )) {
        if [[ $1 ]]  cmds_pattern=${(S)cmds_pattern//name>*\)/name>$1)}
        zstyle ':zpy:*' $topic ${"$(
            $cmd_doc $cmds_pattern $ZPY_SRC
        )"##[[:space:]]#}

        zstyle -s :zpy: $topic REPLY
        return
    }

    # Subcommand ("<cmd> <subcmd>"):

    local cmd subcmd
    cmd=${${(z)1}[1]}
    subcmd=${${(z)1}[2]}

    local lines=(${(f)"$(
        $subcmd_doc ${${subcmd_pattern:gs/<CMD>/$cmd}:gs/<SUBCMD>/$subcmd} $ZPY_SRC
    )"})

    local help_subcmd=()
    local -A rEpLy
    .zpy_ui_${cmd} subcommands
    help_subcmd+=("# ${rEpLy[$subcmd]}" "$cmd $subcmd $lines[1]" $lines[2,-1])

    zstyle ':zpy:*' $topic ${(F)help_subcmd##[[:space:]]#}
    zstyle -s :zpy: $topic REPLY
}

# Print description and arguments for all or specified functions.
.zpy_ui_help () {  # [<zpy-function>...]
    emulate -L zsh
    if [[ $1 == --help ]] { .zpy_ui_help ${0[9,-1]}; return }

    local REPLY ret=0
    .zpy_help $@ || ret=$?
    REPLY=${REPLY/$'\n'help /$'\n'zpy help }
    REPLY=${REPLY/$'\n'mkbin /$'\n'zpy mkbin }
    .zpy_hlt zsh <<<$REPLY || ret=$?
    return ret
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
    [[ $ZPY_VENVS_HOME ]] || return

    .zpy_path_hash ${${1:-$PWD}:P} || return
    REPLY="${ZPY_VENVS_HOME}/${REPLY}"
}

.zpy_chooseproj () {  # [--multi]
    emulate -L zsh
    [[ $ZPY_VENVS_HOME ]] || return

    # TODO: should this absorb .zpy_pipzchoosepkg?

    local multi fzf_args=(--reverse -0 --preview='<{}/*.in')
    if [[ $1 == --multi ]] {
        unset reply
        fzf_args+=(-m)
        multi=1
        shift
    } else {
        unset REPLY
        local reply
    }

    local projdirs=(${ZPY_VENVS_HOME}/*/project(@N-/:P))
    reply=(${(f)"$(
        print -rln -- $projdirs \
        | fzf $fzf_args
    )"})

    [[ $reply ]] || return

    if [[ ! $multi ]]  REPLY=$reply[1]
}

# Get path of folder containing all venvs for the current folder or specified proj-dir.
# Pass -i to interactively choose the project.
.zpy_ui_venvs_path () {  # [-i|<proj-dir>]
    emulate -L zsh
    if [[ $1 == --help ]] { .zpy_ui_help ${0[9,-1]}; return }

    local REPLY
    if [[ $1 == -i ]] {
        .zpy_chooseproj || return
        .zpy_ui_venvs_path $REPLY
    } else {
        .zpy_venvs_path $@ || return
        print -rn -- $REPLY
    }
}

.zpy_please_activate () {  # [not-found-item]
    emulate -L zsh

    .zpy_log error 'FAILED to find' "$1" \
      "You probably want to activate a venv with 'activate' (or 'a8'), first." \
      "${${PWD:P}/%${PWD:P:t}/%B${PWD:P:t}%b}"
}

# Install and upgrade packages.
.zpy_ui_pipi () {  # [--no-upgrade] [<pip install arg>...] <pkgspec>...
    emulate -L zsh
    if [[ $1 == --help ]] { .zpy_ui_help ${0[9,-1]}; return }
    [[ $VIRTUAL_ENV ]] || .zpy_please_activate venv

    local upgrade=-U
    if [[ $1 == --no-upgrade ]] { unset upgrade; shift }

    if [[ ! $1 ]] { .zpy_ui_help ${0[9,-1]}; return 1 }

    python -m pip --disable-pip-version-check install $upgrade $@
    local ret=$?
    rehash

    if (( ret )) {
        local log_args=(error "FAILED ${0[9,-1]} call" "${0[9,-1]} $@" $VIRTUAL_ENV)
        if [[ $VIRTUAL_ENV ]] && [[ -L ${VIRTUAL_ENV:h}/project ]] {
            log_args+=${${:-${VIRTUAL_ENV:h}/project}:P:t}
        }
        .zpy_log $log_args
        return ret
    }
}

.zpy_print_action () {  # [--proj <folder>] <action> <output> [<input>...]
    emulate -L zsh

    local proj=$PWD
    if [[ $1 == --proj ]] { proj=$2; shift 2 }
    proj=${${proj:P}/#~\//\~/}

    [[ $2 && $1 ]] || return

    local action output input=()
    action=$1; shift
    output=${1/#~\//\~/}; shift
    input=(${@/#~\//\~/})

    local -A c=(
        default     cyan
        proj        blue
        syncing     green
        compiling   magenta
        appending   yellow
        creating    yellow
        injecting   yellow
    )
    if ! (( $+c[$action] ))  c[$action]=$c[default]

    local parts=()
    if ! [[ -v NO_COLOR ]] {
        parts+=(
            "%F{$c[default]}==>"
            "%B%F{$c[$action]}$action%b"
        )
        if [[ $input ]]  parts+=("%F{$c[default]}${(j:%B|%b:)input}")
        parts+=(
            "%F{$c[$action]}%B->%b"
            "%F{$c[default]}$output"
            "%F{$c[proj]}%B::%b ${proj/%${proj:t}/%B${proj:t}%b}%f"
        )
    } else {
        parts+=('>' "%B$action%b")
        if [[ $input ]]  parts+=("${(j:%B|%b:)input}")
        parts+=(
            '%B->%b' "$output" '%B::%b'
            "${proj/%${proj:t}/%B${proj:t}%b}"
        )
    }

    print -rPu2 -- $parts
}

# Install packages according to all found or specified requirements.txt files (sync).
.zpy_ui_pips () {  # [<reqs-txt>...]
    emulate -L zsh
    if [[ $1 == --help ]] { .zpy_ui_help ${0[9,-1]}; return }
    rehash
    if (( ! $+commands[pip-sync] )) { .zpy_please_activate pip-sync; return 1 }

    local reqstxts=(${@:-*requirements.txt(N)}) ret
    if [[ $reqstxts ]] {
        local p_a_args=(syncing env $reqstxts)
        if [[ $VIRTUAL_ENV && -L ${VIRTUAL_ENV:h}/project ]]  p_a_args=(--proj ${VIRTUAL_ENV:h}/project(:P) $p_a_args)
        .zpy_log action $p_a_args
        # --read-relative-to-input
        pip-sync -q --pip-args --disable-pip-version-check $reqstxts
        ret=$?

        local reqstxt                               #
        for reqstxt ( $reqstxts ) {                 # can remove if pip-tools #896 is resolved
            .zpy_ui_pipi --no-upgrade -qr $reqstxt  # (by merging pip-tools #907)
            if (( ? ))  ret=1                       #
        }                                           #
        rehash

        if (( ret )) {
            .zpy_log error "FAILED ${0[9,-1]} call" "${0[9,-1]} $@"
            return ret
        }
    }
}

.zpy_pipc () {  # [--faildir <faildir>] [--snapshotdir <snapshotdir>] <reqs-in> [<pip-compile-arg>...]
    emulate -L zsh
    rehash

    local faildir snapshotdir
    while [[ $1 == --(fail|snapshot)dir ]] {
        if [[ $1 == --faildir     ]] { faildir=${2:a};     shift 2 }
        if [[ $1 == --snapshotdir ]] { snapshotdir=${2:a}; shift 2 }
    }

    if (( ! $+commands[pip-compile] )) {
        .zpy_please_activate pip-compile
        if [[ $faildir ]]  print -n >>$faildir/${PWD:t}
        return 1
    }

    if ! [[ $1 ]] {
        if [[ $faildir ]]  print -n >>$faildir/${PWD:t}
        return 1
    }

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

    .zpy_log action compiling $reqstxt $reqsin

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

    local pipcompile_args
    if ! { zstyle -a :zpy: pip-compile-args pipcompile_args }  pipcompile_args=(
        --no-header
        --annotation-style=line
        --strip-extras
        --allow-unsafe
    )
    # After updating minimum pip-tools to support each of these, add them:
    # --resolver=backtracking     # remove parameter PIP_TOOLS_RESOLVER, below
    # --write-relative-to-output
    # --read-relative-to-input

    local badrets
    PIP_TOOLS_RESOLVER=${PIP_TOOLS_RESOLVER:-backtracking} \
    pip-compile --cache-dir=$cachedir -o $reqstxt $pipcompile_args $@ $reqsin 2>&1 \
    | .zpy_hlt ini
    badrets=(${pipestatus:#0})

    if [[ $badrets && $faildir ]]  print -n >>$faildir/${PWD:t}

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

    .zpy_maximum_piptools

    .zpy_pipc $zpypipc_args $reqsin -q ${${${reqs/*/-P}:^reqs}:--U} $pipcompile_args
    local ret=$?

    return ret
}

# Compile requirements.txt files from all found or specified requirements.in files (compile).
# Use -h to include hashes, -u dep1,dep2... to upgrade specific dependencies, and -U to upgrade all.
.zpy_ui_pipc () {  # [-h] [-U|-u <pkgspec>[,<pkgspec>...]] [<reqs-in>...] [-- <pip-compile-arg>...]
    emulate -L zsh
    unset REPLY
    if [[ $1 == --help ]] { .zpy_ui_help ${0[9,-1]}; return }
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
    local zpypipc_args=(--faildir $faildir --snapshotdir $snapshotdir)  # for either .zpy_pipc or .zpy_pipu
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
        .zpy_ui_help ${0[9,-1]}
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
        local title="==> $1:"; shift
        local subject=${1/#~\//\~/}; shift
        local lines=('  '${^@/#~\//\~/})
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
.zpy_ui_pipcs () {  # [-h] [-U|-u <pkgspec>[,<pkgspec>...]] [--only-sync-if-changed] [<reqs-in>...] [-- <pip-compile-arg>...]
    emulate -L zsh
    if [[ $1 == --help ]] { .zpy_ui_help ${0[9,-1]}; return }

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
    if [[ ! $only_sync_if_changed ]]  do_sync=1

    local ret REPLY snapshot
    .zpy_ui_pipc $pipc_args
    ret=$?
    snapshot=$REPLY

    if (( ret )) {
        .zpy_log error "FAILED ${0[9,-1]} call" "${0[9,-1]} $only_sync_if_changed $pipc_args"
        return ret
    }

    local origtxts=(${snapshot}/**/*(DN.))
    local newtxts=(${origtxts#$snapshot})

    if [[ ! $do_sync ]] {
        local origtxt newtxt
        for origtxt newtxt ( ${origtxts:^newtxts} ) {
            if ! { diff -q $origtxt $newtxt &>/dev/null } {
                do_sync=1
                break
            }
        }
    }

    if [[ $do_sync ]]  .zpy_ui_pips $newtxts
}

# Add loose requirements to [<category>-]requirements.in (add).
.zpy_ui_pipa () {  # [-c <category>] <pkgspec>...
    emulate -L zsh
    if [[ $1 == --help ]] { .zpy_ui_help ${0[9,-1]}; return }

    local reqsin=requirements.in
    if [[ $1 == -c ]] { reqsin=${2}-requirements.in; shift 2 }

    if [[ ! $1 ]] { .zpy_ui_help ${0[9,-1]}; return 1 }

    .zpy_log action appending $reqsin

    print -rl -- $@ >>$reqsin

    .zpy_hlt ini <$reqsin
}

# Add to requirements.in, then compile it to requirements.txt (add, compile).
# Use -c to affect categorized requirements, and -h to include hashes.
.zpy_ui_pipac () {  # [-c <category>] [-h] <pkgspec>... [-- <pip-compile-arg>...]
    emulate -L zsh
    if [[ $1 == --help ]] { .zpy_ui_help ${0[9,-1]}; return }

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

    if [[ ! $1 ]] { .zpy_ui_help ${0[9,-1]}; return 1 }

    local pipa_args=($@) reqsin=requirements.in
    if [[ $catg ]] {
        pipa_args=(-c $catg $pipa_args)
        reqsin=${catg}-requirements.in
    }

    local pipc_args=($reqsin -- $gen_hashes $pipcompile_args)

    .zpy_ui_pipa $pipa_args
    .zpy_ui_pipc $pipc_args
}

# Add to requirements.in, compile it to requirements.txt, then sync to that (add, compile, sync).
# Use -c to affect categorized requirements, and -h to include hashes.
.zpy_ui_pipacs () {  # [-c <category>] [-h] <pkgspec>... [-- <pip-compile-arg>...]
    emulate -L zsh
    if [[ $1 == --help ]] { .zpy_ui_help ${0[9,-1]}; return }

    .zpy_ui_pipac $@
    local ret=$?

    if (( ret )) {
        .zpy_log error "FAILED ${0[9,-1]} call" "${0[9,-1]} $@"
        return ret
    }

    local reqstxt=requirements.txt
    if [[ $1 == -h ]]  shift
    if [[ $1 == -c ]]  reqstxt=${2}-requirements.txt

    .zpy_ui_pips $reqstxt
}

# View contents of all *requirements*.{in,txt} files in the current or specified folders.
.zpy_ui_reqshow () {  # [<folder>...]
    emulate -L zsh
    if [[ $1 == --help ]] { .zpy_ui_help ${0[9,-1]}; return }
    [[ $1 ]] || 1=$PWD

    local reqsfiles=() rf
    for 1 {
        # Basically this, but avoiding reliance on tail:
        # tail -n +1 $1/*requirements*.{in,txt} | .zpy_hlt ini

        reqsfiles+=($1/*requirements*.{txt,in}(N))

        for rf ( $reqsfiles ) {
            if [[ $rf != ${reqsfiles[1]} ]]  print
            print -r -- '==>' $rf '<=='
            .zpy_hlt ini <$rf
        }
        if [[ $1 != ${@[-1]} ]]  print
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

    local short_venv
    .zpy_shortvenv $venv
    short_venv=$REPLY

    # create venv if necessary:
    local ret
    if [[ ! -r $venv/bin/activate ]] || ! { $venv/bin/pip &>/dev/null } {
        .zpy_log action creating $short_venv
        zf_rm -rf $venv
        $venv_cmd $venv
    }
    ret=$?

    if (( ret )) {
        .zpy_log error 'FAILED to make venv' "$venv_cmd $venv"
        return ret
    }

    zf_ln -sfn $PWD ${vpath}/project

    . $venv/bin/activate || return

    .zpy_minimum_piptools || return

    .zpy_ui_pips $reqstxts
}

.zpy_argvenv () {  # pypy|current -> ($venv_name $venv_cmd...)
    emulate -L zsh
    unset reply

    local venv_name venv_cmd=()
    case $1 {
    pypy)
        venv_name=venv-pypy
        venv_cmd=(pypy3 -m venv)
    ;;
    current)
        local REPLY
        .zpy_pyvervenvname || return
        venv_name=$REPLY

        local major=$(python -c 'from __future__ import print_function; import sys; print(sys.version_info.major)')
        [[ $major == 3 ]] || return
        venv_cmd=(python -m venv)
    ;;
    *)
        return 1
    ;;
    }

    reply=($venv_name $venv_cmd)
}

# Activate the venv (creating if needed) for the current folder, and sync
# its installed package set according to all found or specified requirements.txt files.
# In other words: [create, ]activate, sync.
# The interpreter will be whatever 'python3' refers to at time of venv creation, by default.
# Pass --py to use another interpreter and named venv.
.zpy_ui_envin () {  # [--py pypy|current] [<reqs-txt>...]
    emulate -L zsh
    if [[ $1 == --help ]] { .zpy_ui_help ${0[9,-1]}; return }

    local venv_name=venv venv_cmd=(python3 -m venv)
    if [[ $1 == --py ]] {
        local reply
        if ! { .zpy_argvenv $2 } { .zpy_ui_help ${0[9,-1]}; return 1 }
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
.zpy_ui_activate () {  # [--py pypy|current] [-i|<proj-dir>]
    emulate -L zsh
    if [[ $1 == --help ]] { .zpy_ui_help ${0[9,-1]}; return }

    local envin_args=() venv_name=venv interactive
    while [[ $1 == -(i|-py) ]] {
        if [[ $1 == -i ]] { interactive=1; shift }
        if [[ $1 == --py ]] {
            local reply
            if ! { .zpy_argvenv $2 } { .zpy_ui_help ${0[9,-1]}; return 1 }
            venv_name=$reply[1]
            envin_args=($1 $2)
            shift 2
        }
    }

    local REPLY
    if [[ $interactive ]] {
        .zpy_chooseproj || return
        .zpy_ui_activate $envin_args "$REPLY"
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
        .zpy_ui_envin $envin_args
    } elif { . $activator } {
        .zpy_minimum_piptools || return
    } else {
        return
    }
}

.zpy_minimum_piptools () {
    emulate -L zsh

    .zpy_ui_pipi --no-upgrade -q \
        'pip-tools>=6.6.2' \
        'setuptools>=62.0.0' \
        wheel
}

.zpy_maximum_piptools () {
    emulate -L zsh

    .zpy_ui_pipi -q \
        pip \
        pip-tools \
        setuptools \
        wheel
}

# Alias for 'activate'.
.zpy_ui_a8 () {  # [--py pypy|current] [-i|<proj-dir>]
    .zpy_ui_activate $@
}

# Alias for 'deactivate'.
.zpy_ui_envout () {
    deactivate $@
}

# Another alias for 'deactivate'.
.zpy_ui_da8 () {
    deactivate $@
}

.zpy_whichvpy () {  # <venv-name> <script>
    emulate -L zsh
    unset REPLY
    [[ $2 && $1 ]] || return

    .zpy_venvs_path ${2:a:h} || return
    REPLY=$REPLY/$1/bin/python
}

# Display path of project for the activated venv.
.zpy_ui_whichpyproj () {
    emulate -L zsh
    if [[ $1 == --help ]] { .zpy_ui_help ${0[9,-1]}; return }
    [[ $VIRTUAL_ENV ]] || return

    print -r -- ${VIRTUAL_ENV:h}/project(@N:P)
}

# Prepend each script with a shebang for its folder's associated venv interpreter.
# If 'vpy' exists in the PATH, '#!/path/to/vpy' will be used instead.
# Also ensures the script is executable.
# --py may be used, same as for envin.
.zpy_ui_vpyshebang () {  # [--py pypy|current] <script>...
    emulate -L zsh
    if [[ $1 == --help ]] { .zpy_ui_help ${0[9,-1]}; return }

    local venv_name=venv
    if [[ $1 == --py ]] {
        local reply
        if ! { .zpy_argvenv $2 } { .zpy_ui_help ${0[9,-1]}; return 1 }
        venv_name=$reply[1]; shift 2
    }

    if [[ ! $1 ]] { .zpy_ui_help ${0[9,-1]}; return 1 }

    local vpyscript
    if [[ $venv_name == venv ]]  vpyscript=$commands[vpy]

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
.zpy_ui_vrun () {  # [--py pypy|current] [--cd] [--activate] <proj-dir> <cmd> [<cmd-arg>...]
    emulate -L zsh
    if [[ $1 == --help ]] { .zpy_ui_help ${0[9,-1]}; return }

    local do_enter do_activate activate_args=() projdir
    while [[ $1 == --(py|cd|activate) ]] {
        if [[ $1 == --cd       ]] { do_enter=1;    shift }
        if [[ $1 == --activate ]] { do_activate=1; shift }
        if [[ $1 == --py       ]] {
            if ! { .zpy_argvenv $2 } { .zpy_ui_help ${0[9,-1]}; return 1 }
            activate_args=($1 $2); shift 2
        }
    }
    if ! [[ $2 && $1 ]] { .zpy_ui_help ${0[9,-1]}; return 1 }
    projdir=${1:a}; shift

    zf_mkdir -p $projdir
    (
        set -e

        if [[ $do_enter ]]  cd $projdir

        if [[ $do_activate ]] {
            .zpy_ui_activate $activate_args $projdir
        } else {
            vname=venv
            if [[ $activate_args ]] {
                .zpy_argvenv $activate_args[2]
                vname=$reply[1]
            }

            .zpy_venvs_path $projdir
            vpath=$REPLY

            if [[ -d $vpath/$vname/bin ]] { path=($vpath/$vname/bin $path)
            } else                        { .zpy_ui_activate $activate_args $projdir }
        }

        $@
    )
}

# Run script with the python from its folder's venv.
# --py may be used, same as for envin.
.zpy_ui_vpy () {  # [--py pypy|current] [--activate] <script> [<script-arg>...]
    emulate -L zsh
    if [[ $1 == --help ]] { .zpy_ui_help ${0[9,-1]}; return }

    local vrun_args=()
    while [[ $1 == --(py|activate) ]] {
        if [[ $1 == --py       ]] { vrun_args+=($1 $2); shift 2 }
        if [[ $1 == --activate ]] { vrun_args+=($1);    shift   }
    }

    if [[ ! $1 ]] { .zpy_ui_help ${0[9,-1]}; return 1 }

    .zpy_ui_vrun $vrun_args ${1:a:h} python ${1:a} ${@[2,-1]}
}


# Make a launcher script for a command run in a given project's activated venv.
# With --link-only, only create a symlink to <venv>/bin/<cmd>,
# which should already have the venv's python in its shebang line.
.zpy_ui_vlauncher () {  # [--link-only] [--py pypy|current] <proj-dir> <cmd> <launcher-dest>
    emulate -L zsh
    if [[ $1 == --help ]] { .zpy_ui_help ${0[9,-1]}; return }

    local linkonly venv_name=venv reply
    while [[ $1 == --(link-only|py) ]] {
        if [[ $1 == --link-only ]] {
            linkonly=1; shift
        }
        if [[ $1 == --py ]] {
            if ! { .zpy_argvenv $2 } { .zpy_ui_help ${0[9,-1]}; return 1 }
            venv_name=$reply[1]; shift 2
        }
    }

    if ! [[ $3 && $2 && $1 ]] { .zpy_ui_help ${0[9,-1]}; return 1 }

    local projdir=${1:P} cmd=$2 dest=${3:a}
    if [[ -d $dest ]]  dest=$dest/$cmd

    local REPLY venv
    .zpy_venvs_path $projdir || return
    venv=${REPLY}/${venv_name}

    if [[ $linkonly ]] {
        local cmdpath=${venv}/bin/${cmd}

        if [[ ! -x $cmdpath ]] {
            .zpy_log error 'FAILED to find executable' $cmdpath $projdir
            return 1
        }

        if ! { zf_ln -s $cmdpath $dest 2>/dev/null } {
            if [[ ${dest:P} != ${cmdpath:P} ]] {
                .zpy_log error 'ABORTING symlink creation' 'destination exists' $dest $projdir
                return 1
            }
        }
    } else {

        if [[ -e $dest ]] {
            .zpy_log error 'ABORTING launcher creation' 'destination exists' $dest $projdir
            return 1
        }

        print -rl -- '#!/bin/sh -e' ". ${venv}/bin/activate" "exec $cmd \$@" >$dest
        zf_chmod 0755 $dest
    }
}

# Delete venvs for project folders which no longer exist.
.zpy_ui_prunevenvs () {  # [-y]
    emulate -L zsh
    if [[ $1 == --help ]] { .zpy_ui_help ${0[9,-1]}; return }
    [[ $ZPY_VENVS_HOME ]] || return

    local noconfirm
    if [[ $1 == -y ]]  noconfirm=1

    local proj REPLY orphaned_venv
    for proj ( ${ZPY_VENVS_HOME}/*/project(@N:P) ) {
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

.zpy_pipcheckoldcells () {  # [--py pypy|current] <proj-dir>
    emulate -L zsh

    local vrun_args=()
    if [[ $1 == --py ]] { vrun_args+=($1 $2); shift 2 }
    [[ -d $1 ]] || return
    vrun_args+=($1)

    rehash

    local cells=()
    if (( $+commands[jq] )) {
        cells=($(
            .zpy_ui_vrun $vrun_args python -m pip --disable-pip-version-check list -o --format json \
            | jq -r '.[] | select(.name|test("^(setuptools|six|pip|pip-tools)$")|not) | .name,.version,.latest_version'
        ))
    } elif (( $+commands[jello] )) {
        cells=($(
            .zpy_ui_vrun $vrun_args python -m pip --disable-pip-version-check list -o --format json \
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
            =(<<<"{\"_\": $(.zpy_ui_vrun $vrun_args python -m pip --disable-pip-version-check list -o --format json)}")
        ))
    } else {
        local lines=(${(f)"$(.zpy_ui_vrun $vrun_args python -m pip --disable-pip-version-check list -o)"})
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

# 'pip list -o' (show outdated) for the current or specified folders.
# Use --all to instead act on all known projects, or -i to interactively choose.
.zpy_ui_pipcheckold () {  # [--py pypy|current] [--all|-i|<proj-dir>...]
    emulate -L zsh
    if [[ $1 == --help ]] { .zpy_ui_help ${0[9,-1]}; return }
    [[ $ZPY_PROCS      ]] || return
    [[ $ZPY_VENVS_HOME ]] || return

    local extra_args=() projects=() reply
    while [[ $1 == -(-py|-all|i) ]] {
        if [[ $1 == --py ]] { extra_args+=($1 $2); shift 2 }
        if [[ $1 == --all ]] {
            projects=(${ZPY_VENVS_HOME}/*/project(@N-/))
            shift
        } elif [[ $1 == -i ]] {
            .zpy_chooseproj --multi || return
            projects=($reply)
            shift
        }
    }
    projects=(${projects:-${@:-$PWD}})

    local header=(Package Version Latest Project) cells=()
    cells+=(${(f)"$(
        zargs -P $ZPY_PROCS -rl \
        -- $projects \
        -- .zpy_pipcheckoldcells $extra_args
    )"})

    if [[ $cells ]] {
        if (( $+commands[rich] )) {
            local rows=(${(j:,:)header}) i
            for (( i=1; i<=$#cells; i+=$#header ))  rows+=(${(j:,:)cells[i,i+$#header-1]})

            rich --csv - <<<${(F)rows}
        } else {
            header=(%B${^header}%b)
            if ! [[ -v NO_COLOR ]]  header=(%F{cyan}${^header}%f)

            print -rPaC 4 -- $header $cells
        }
    }
}

.zpy_pipup () {  # [--py pypy|current] [--faildir <faildir>] [--only-sync-if-changed] <proj-dir>
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
        .zpy_ui_activate $activate_args 2>/dev/null

        .zpy_ui_pipcs -U $only_sync_if_changed
    )
    ret=$?

    if (( ret )) && [[ $faildir ]]  print -n >>$faildir/${1:t}

    return ret
}

# 'pipcs -U' (upgrade-compile, sync) in a venv-activated subshell for the current or specified folders.
# Use --all to instead act on all known projects, or -i to interactively choose.
.zpy_ui_pipup () {  # [--py pypy|current] [--only-sync-if-changed] [--all|-i|<proj-dir>...]
    emulate -L zsh
    # TODO:
    # things that *might* gain --interactive (-i):
    # vrun
    # vlauncher
    # pipz cd|inject|runpip (names which are really projs)

    if [[ $1 == --help ]] { .zpy_ui_help ${0[9,-1]}; return }
    [[ $ZPY_PROCS      ]] || return
    [[ $ZPY_VENVS_HOME ]] || return

    local extra_args=() projects=() reply
    while [[ $1 == -(-py|-only-sync-if-changed|-all|i) ]] {
        if [[ $1 == --py                   ]] { extra_args+=($1 $2); shift 2 }
        if [[ $1 == --only-sync-if-changed ]] { extra_args+=($1);    shift   }
        if [[ $1 == --all ]] {
            projects=(${ZPY_VENVS_HOME}/*/project(@N-/:P))
            shift
        } elif [[ $1 == -i ]] {
            .zpy_chooseproj --multi || return
            projects=($reply)
            shift
        }
    }
    projects=(${projects:-${@:-$PWD}})

    local faildir=$(mktemp -d) failures=()
    zargs -P $ZPY_PROCS -rl \
    -- $projects \
    -- .zpy_pipup $extra_args --faildir $faildir
    failures=($faildir/*(N:t))
    zf_rm -rf $faildir

    if [[ $failures ]] {
        .zpy_log error "FAILED ${0[9,-1]} call; Problems upgrading" $failures
        return 1
    }
}

# Inject loose requirements.in dependencies into a PEP 621 pyproject.toml.
# Run either from the folder housing pyproject.toml, or one below.
# To categorize, name files <category>-requirements.in.
.zpy_ui_pypc () {  # [-y]
    emulate -L zsh
    if [[ $1 == --help ]] { .zpy_ui_help ${0[9,-1]}; return }

    local noconfirm
    if [[ $1 == -y ]]  noconfirm=1

    .zpy_ui_pipi --no-upgrade -q tomlkit
    local ret=$?

    if (( ret )) { .zpy_please_activate tomlkit; return ret }

    local pyproject=${${:-pyproject.toml}:a}
    if [[ ! -e $pyproject ]] && [[ -e ${pyproject:h:h}/pyproject.toml ]] {
        pyproject=${pyproject:h:h}/pyproject.toml
    }

    if [[ ! $noconfirm ]] && [[ -e $pyproject ]] {
        if ! { read -q "?Overwrite ${pyproject}? [yN] " } {
            print '\n'
            return
        }
        print '\n'
    }

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
        elif line.startswith('-c '):
            continue
        with suppress(AttributeError):
            reqs.append(
                re.search(r'^(-\S+\s+)*([^#]+)', line).group(2).rstrip()
            )
    return sorted(set(reqs))


suffix = 'requirements.in'
pyproject = Path('''${pyproject}''').absolute()
pyproject_short = re.sub(rf'^{Path.home()}/', '~/', str(pyproject))
if not pyproject.is_file():
    pyproject.touch()
reqsins = [*pyproject.parent.glob(f'*/*{suffix}')] + [*pyproject.parent.glob(f'*{suffix}')]
toml_data = tomlkit.parse(pyproject.read_text())
for reqsin in reqsins:
    reqsin_short = re.sub(rf'^{Path.home()}/', '~/', str(reqsin))
    print(f'\033[96m> injecting {reqsin_short} -> {pyproject_short}\033[0m')
    pyproject_reqs = reqs_from_reqsin(reqsin)
    print(pyproject_reqs)
    extras_catg = reqsin.name.rsplit(suffix, 1)[0].rstrip('-.')
    toml_data.setdefault('project', {})
    if not extras_catg:
        toml_data['project']['dependencies'] = pyproject_reqs
    else:
        toml_data['project'].setdefault('optional-dependencies', {})
        toml_data['project']['optional-dependencies'][extras_catg] = pyproject_reqs
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

# TODO: anywhere jq is tried, try all: jq, jello, dasel, wheezy.template
# MAYBE: add yaml-path (again)? Check performance...
# THEN: update deps.md
# - .zpy_pipcheckoldcells (current: jq, jello, wheezy.template, zsh) (add dasel)
# - .zpy_pipzlistrow (current: jq, jello, wheezy.template, zsh) (add dasel)
# - .zpy_insertjson (current: jq, dasel, python)
# - .zpy_pypi_pkgs (current: jq, dasel, jello, python)


# TODO: tables printed, maybe try rich --csv
# THEN: update deps.md

.zpy_insertjson () {  # <jsonfile> <value> <keycrumb>...
    # Does not currently handle spaces within any keycrumb (or need to)
    emulate -L zsh
    rehash

    local jsonfile=$1; shift
    local value=$1; shift

    zf_mkdir -p ${jsonfile:h}
    if [[ ! -r $jsonfile ]] || [[ ! $(<$jsonfile) ]] {
        >$jsonfile <<<'{}'
    }

    if (( $+commands[jq] )) {
        local keypath=".\"${(j:".":)@}\""
        if [[ $value != (true|false) ]]  value=${(qqq)value}
        print -r -- "$(
            jq --argjson val "$value" "${keypath}=\$val" "$jsonfile"
        )" >$jsonfile
    } elif (( $+commands[dasel] )) {
        local keypath=".${(j:.:)@}"
        local vartype=string
        if [[ $value == (true|false) ]]  vartype=bool
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

value = '''${value}'''
value = {'true': True, 'false': False}.get(value.lower(), value)

d[keycrumbs[-1]] = value

jsonfile.write_text(dumps(data, indent=4))
        "
    }
}

# Specify the venv interpreter for the working folder in a new or existing json file.
.zpy_vpy2json () {  # [--py pypy|current] <jsonfile> <keycrumb>...
    # Does not currently handle spaces within any keycrumb (or need to)
    emulate -L zsh

    local venv_name=venv
    if [[ $1 == --py ]] {
        local reply
        if ! { .zpy_argvenv $2 } { return 1 }
        venv_name=$reply[1]
        shift 2
    }

    local jsonfile=$1; shift

    local REPLY pypath venv_path
    .zpy_venvs_path || return
    venv_path=${REPLY}/${venv_name}
    pypath=${venv_path}/bin/python

    local short_pypath
    .zpy_shortvenv $venv_path
    short_pypath=${REPLY}/bin/python

    .zpy_log action injecting $jsonfile "interpreter $short_pypath"

    .zpy_insertjson $jsonfile $pypath $@
}

# Abbreviate the hash portion of the venv path, for display.
.zpy_shortvenv () {  # <venv-path>
    emulate -L zsh
    unset REPLY

    local short_venv="${1/#~\//~/}"
    local short_venv_parts=("${(s:/:)short_venv}")
    short_venv_parts[-2]=${short_venv_parts[-2][1,3]}…
    short_venv=${(j:/:)short_venv_parts}

    REPLY=$short_venv
}

# Specify the venv interpreter in a new or existing Sublime Text project file for the working folder.
.zpy_ui_vpysublp () {  # [--py pypy|current]
    emulate -L zsh
    if [[ $1 == --help ]] { .zpy_ui_help ${0[9,-1]}; return }

    local REPLY jsonfile
    .zpy_get_sublp
    jsonfile=$REPLY

    .zpy_vpy2json $@ $jsonfile settings python_interpreter
}

# Specify the venv interpreter in a new or existing [VS]Code settings file for the working folder.
.zpy_ui_vpyvscode () {  # [--py pypy|current]
    emulate -L zsh
    if [[ $1 == --help ]] { .zpy_ui_help ${0[9,-1]}; return }

    local jsonfile=$PWD/.vscode/settings.json

    .zpy_vpy2json $@ $jsonfile python.defaultInterpreterPath
}

# Specify the venv interpreter in a new or existing Pyright settings file for the working folder.
.zpy_ui_vpypyright () {  # [--py pypy|current]
    emulate -L zsh
    if [[ $1 == --help ]] { .zpy_ui_help ${0[9,-1]}; return }

    local jsonfile=$PWD/pyrightconfig.json

    local venv_name=venv
    if [[ $1 == --py ]] {
        local reply
        if ! { .zpy_argvenv $2 } { .zpy_ui_help ${0[9,-1]}; return 1 }
        venv_name=$reply[1]
    }

    local REPLY vpath
    .zpy_venvs_path || return
    vpath=$REPLY

    local short_venv
    .zpy_shortvenv ${vpath}/${venv_name}
    short_venv=$REPLY

    .zpy_log action injecting $jsonfile "venv $short_venv"

    .zpy_insertjson $jsonfile $vpath venvPath
    .zpy_insertjson $jsonfile $venv_name venv
    .zpy_insertjson $jsonfile true useLibraryCodeForTypes
}

.zpy_is_under () {  # <kid_path> <ok_parent>...
    emulate -L zsh
    [[ $2 && $1 ]] || return

    local kid=${1:a}; shift

    for 1 {
        if [[ $kid == ${1:a} ]]  return
        if [[ $kid == ${${1:a}%/}/* ]]  return
    }

    return 1
}

.zpy_diffsnapshot () {  # <snapshot-dir>
    emulate -L zsh
    [[ -d $1 ]] || return

    # Original text file contents have been copied into the snapshot dir,
    # at <snapshot dir>/<original full path>

    local origtxts=(${1:a}/**/*(DN.))
    local newtxts=(${origtxts#${1:a}})

    local origtxt newtxt lines=() label
    for origtxt newtxt ( ${origtxts:^newtxts} ) {
        if [[ ! $(<$origtxt) ]]  continue

        label=${newtxt:a:h:h:t}/${newtxt:a:h:t}${${newtxt:a:h:t}:+/}${newtxt:t}
        lines=(${(f)"$(
            diff -wu -L $label $origtxt -L $label $newtxt
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

    rehash

    local piplistline=()
    if (( $+commands[jq] )) {
    # Slower than the pure ZSH fallback below?
        local pattern=${${pdir:t}//-/[._-]}
        piplistline=($(
            .zpy_ui_vrun $pdir python -m pip --disable-pip-version-check list --pre --format json \
            | jq -r '.[] | select(.name|test("^'${pattern}'$"; "i")) | .name,.version'
        ))
    } elif (( $+commands[jello] )) {
        # Slower than the pure ZSH fallback below?
        piplistline=($(
            .zpy_ui_vrun $pdir python -m pip --disable-pip-version-check list --pre --format json \
            | jello -lr '[pkg["name"] + " " + pkg["version"] for pkg in _ if pkg["name"].lower().replace("_", "-").replace(".", "-") == "'${pdir:t}'"]'
        ))
    } elif (( $+commands[wheezy.template] )) {
        # Slower than the pure ZSH fallback below?
        local template=(
            '@require(_)'

            '@for pkg in _:'
            '@if pkg["name"].lower().replace("_", "-").replace(".", "-") == "'${pdir:t}'":'

            '@pkg["name"]'
            '@pkg["version"]'

            '@end'
            '@end'
        )
        piplistline=($(
            wheezy.template =(<<<${(F)template}) \
            =(<<<"{\"_\": $(.zpy_ui_vrun $pdir python -m pip --disable-pip-version-check list --pre --format json)}")
        ))
    } else {
        local lines=(${(f)"$(
            .zpy_ui_vrun $pdir python -m pip --disable-pip-version-check list --pre
        )"})
        lines=($lines[3,-1])

        local pattern=${${pdir:t}//-/[._-]}
        piplistline=(${(zM)lines:#(#i)${~pattern} *})
    }
    # Preserve the table layout in case something goes surprising and we don't get a version cell:
    piplistline+=('????')
    # TODO: don't do that. handle empty results.

    local pyverlines=(${(f)"$(
        .zpy_ui_vrun $pdir python -V
    )"})

    print -rl -- "${bin:t}" "${piplistline[1,2]}" "${pyverlines[-1]}"
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
        REPLY=${${${(j: :)${${(s: :)pkgspec:l}:#-*}}%%[ \[<>=#~;@&]*}//[._]/-}
    }

    if [[ $badspec || ! $REPLY ]] {
        .zpy_log error 'FAILED to parse pkgspec' "$1" \
            'https://www.python.org/dev/peps/pep-0508/#examples' \
            'https://pip.pypa.io/en/stable/topics/vcs-support/'
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
        if [[ $faildir ]]  print -n >>$faildir/$pkgname
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
        .zpy_ui_activate
        .zpy_ui_pipacs $pkg
    )
    ret=$?

    if (( ret )) && [[ $faildir ]]  print -n >>$faildir/$pkgname

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
        if [[ $1 == --header ]] {
            fzf_header=$2; shift 2
        }
        if [[ $1 == --multi  ]] {
            fzf_prompt='Which packages? Choose one with <enter> or more with <tab>. '
            fzf_args+=(-m)
            multi=1; shift
        }
    }
    fzf_args+=(--header=$fzf_header --prompt=$fzf_prompt)

    if [[ $multi ]] {
        unset reply
    } else {
        unset REPLY
        local reply
    }

    [[ $1 ]] || return

    fzf_args+=(--preview="zsh -fc '. $ZPY_SRC; .zpy_hlt ini <$1/{}/*'")

    local pkgs=($1/*(N/:t))
    reply=(${(f)"$(
        print -rln -- $pkgs | fzf $fzf_args
    )"})

    [[ $reply ]] || return

    if [[ ! $multi ]]  REPLY=$reply[1]
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

    if [[ $binlinks ]]  zf_rm $binlinks

    rehash
}

.zpy_pipzrmvenvs () {  # <projects_home> <pkgspec>...
    emulate -L zsh
    [[ $2 && $1 ]] || return

    local projects_home=$1; shift

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

    local bins_showlist=() bins_hidelist=() linkonly=1 fzf_args=(--reverse -m -0) fzf_header=Installing
    while [[ $1 == --(cmd|activate|no-cmd|auto1|header) ]] {
        if [[ $1 == --cmd      ]] { bins_showlist=(${(s:,:)2});  shift 2 }
        if [[ $1 == --no-cmd   ]] { bins_hidelist=(${(s:,:)2});  shift 2 }
        if [[ $1 == --activate ]] { unset linkonly;              shift   }
        if [[ $1 == --auto1    ]] { fzf_args+=(-1);              shift   }
        if [[ $1 == --header   ]] { fzf_header=$2;               shift 2 }
    }

    [[ $1 && $bins_home && $projects_home ]] || return

    zf_mkdir -p $bins_home

    local pkgname projdir vpath bins bin src dest REPLY
    for 1 {
        .zpy_pkgspec2name $1 || return
        pkgname=$REPLY

        projdir=${projects_home}/${pkgname}

        .zpy_venvs_path $projdir || return
        vpath=$REPLY

        bins=("${vpath}/venv/bin/"*(N:t))
        if [[ $bins_showlist ]] {
            bins=(${bins:*bins_showlist})
        } else {
            bins=(${bins:|bins_hidelist})
            bins=(${bins:#([aA]ctivate(|.csh|.fish|.ps1)|easy_install(|-<->*)|(pip|python|pypy)(|<->*)|*.so|__pycache__)})
            if [[ $pkgname != pip-tools ]]  bins=(${bins:#pip-(compile|sync)})
            if [[ $pkgname != wheel     ]]  bins=(${bins:#wheel})
            if [[ $pkgname != chardet   ]]  bins=(${bins:#chardetect})
            bins=(${(f)"$(
                print -rln $bins \
                | fzf $fzf_args --header="$fzf_header $1 . . ." \
                --prompt='Which scripts should be added to the path? Choose one with <enter> or more with <tab>. '
            )"})
        }

        for bin ( $bins ) {
            if [[ $linkonly ]] {
                .zpy_ui_vlauncher --link-only $projdir $bin $bins_home
            } else {
                zf_mkdir -p ${vpath}/venv/pipz_launchers
                .zpy_ui_vlauncher $projdir $bin ${vpath}/venv/pipz_launchers

                src=${vpath}/venv/pipz_launchers/${bin}
                dest=${bins_home}/${bin}
                if ! { zf_ln -s $src $dest 2>/dev/null } {
                    if [[ ${src:P} != ${dest:P} ]] {
                        .zpy_log error 'ABORTING launcher creation' 'destination exists' $dest
                    }
                }
            }
        }
    }

    rehash
}

# TODO: readme: links to doc pages, as alphabetical grid:

# Package manager for venv-isolated scripts (pipx clone).
.zpy_ui_pipz () {  # [install|uninstall|upgrade|list|inject|reinstall|cd|runpip|runpkg] [<subcmd-arg>...]
    emulate -L zsh +o promptsubst -o globdots
    [[ $ZPY_PIPZ_PROJECTS && $ZPY_PIPZ_BINS && $ZPY_VENVS_HOME && $ZPY_PROCS ]] || return

    local reply REPLY
    local subcmds=(
        install     "Install apps from PyPI or filesystem into isolated venvs"
        uninstall   "Remove apps"
        upgrade     "Install newer versions of apps and their dependencies"
        list        "Show one or more installed app with its version, commands, and Python runtime"
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
        .zpy_ui_help ${0[9,-1]}
        local i
        for ((i=1; i<$#subcmds; i+=2)) {
            print
            .zpy_ui_help "${0[9,-1]} $subcmds[i]"
        }
        return
    ;;
    install)  # [--cmd <cmd>[,<cmd>...]] [--activate] <pkgspec>...  ## subcmd: pipz install
    # Without --cmd, interactively choose.
    # Without --activate, 'vlauncher --link-only' is used.
        if [[ $2 == --help ]] { .zpy_ui_help "${0[9,-1]} $1"; return }
        shift

        local linkbins_args=($ZPY_PIPZ_PROJECTS $ZPY_PIPZ_BINS --auto1)
        while [[ $1 == --(cmd|activate) ]] {
            if [[ $1 == --cmd      ]] { linkbins_args+=($1 $2); shift 2 }
            if [[ $1 == --activate ]] { linkbins_args+=($1);    shift   }
        }

        if [[ ! $1 ]] { .zpy_ui_help "${0[9,-1]} install"; return 1 }

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

        # TODO: track failures from .zpy_pipzlinkbins?

        (( ${path[(I)$ZPY_PIPZ_BINS]} )) \
        || print -rP "suggestion%B:%b add %Bpath=(${ZPY_PIPZ_BINS/#~\//~/} \$path)%b to %B~/.zshrc%b"

        if [[ $failures ]] {
            .zpy_log error "FAILED to (${0[9,-1]}) install" $failures
            return 1
        }
    ;;
    uninstall)  # [--all|<pkgname>...]  ## subcmd: pipz uninstall
    # Without args, interactively choose.
        if [[ $2 == --help ]] { .zpy_ui_help "${0[9,-1]} $1"; return }
        shift
        if [[ $1 == --all ]] { pipz uninstall ${ZPY_PIPZ_PROJECTS}/*(/:t); return }

        local pkgs=()
        if [[ $@ ]] { pkgs=($@) } else {
            .zpy_pipzchoosepkg --multi --header 'Uninstalling . . .' $ZPY_PIPZ_PROJECTS || return
            pkgs=($reply)
        }

        .zpy_pipzunlinkbins $ZPY_PIPZ_PROJECTS $ZPY_PIPZ_BINS $pkgs
        .zpy_pipzrmvenvs $ZPY_PIPZ_PROJECTS $pkgs

        local pkg projdir ret=0
        for pkg ( $pkgs ) {
            .zpy_pkgspec2name $pkg || return
            projdir=${ZPY_PIPZ_PROJECTS}/${REPLY}

            if [[ -d $projdir ]] {
                zf_rm -r $projdir
            } else {
                .zpy_log error "FAILED to find project for (${0[9,-1]}) uninstall" $projdir
                ret=1
            }
        }

        return ret
    ;;
    upgrade)  # [--all|<pkgname>...]  ## subcmd: pipz upgrade
    # Without args, interactively choose.
        if [[ $2 == --help ]] { .zpy_ui_help "${0[9,-1]} $1"; return }
        shift
        if [[ $1 == --all ]] { pipz upgrade ${ZPY_PIPZ_PROJECTS}/*(/:t); return }

        local pkgnames=()
        if [[ $@ ]] {
            .zpy_all_replies .zpy_pkgspec2name $@ || return
        } else {
            .zpy_pipzchoosepkg --multi --header 'Upgrading . . .' $ZPY_PIPZ_PROJECTS || return
        }
        pkgnames=($reply)

        .zpy_ui_pipup --only-sync-if-changed ${ZPY_PIPZ_PROJECTS}/${^pkgnames}
        local ret=$?

        if (( ret )) {
            .zpy_log error "FAILED ${0[9,-1]} call" "${0[9,-1]} upgrade $@"
            return ret
        }
    ;;
    list)  # [--all|<pkgname>...]  ## subcmd: pipz list
    # Without args, interactively choose which installed apps to list.
        if [[ $2 == --help ]] { .zpy_ui_help "${0[9,-1]} $1"; return }
        shift

        print -rPl \
            "projects     %B@%b ${ZPY_PIPZ_PROJECTS/#~\//~/}" \
            "venvs        %B@%b ${ZPY_VENVS_HOME/#~\//~/}" \
            "apps exposed %B@%b ${ZPY_PIPZ_BINS/#~\//~/}"

        (( ${path[(I)$ZPY_PIPZ_BINS]} )) \
        || print -rP "suggestion%B:%b add %Bpath=(${ZPY_PIPZ_BINS/#~\//~/} \$path)%b to %B~/.zshrc%b"

        print
        print -rC 4 -- ${ZPY_PIPZ_PROJECTS}/*(/N:t)
        print

        local venvs_path_goodlist=()
        if [[ $1 == --all ]] {
            venvs_path_goodlist=($ZPY_VENVS_HOME)
            shift
        } elif [[ $1 ]] {
            .zpy_all_replies .zpy_pkgspec2name $@ || return
            .zpy_all_replies .zpy_venvs_path ${ZPY_PIPZ_PROJECTS}/${^reply} || return
            venvs_path_goodlist=($reply)
        } else {
            .zpy_pipzchoosepkg --multi $ZPY_PIPZ_PROJECTS || return
            .zpy_all_replies .zpy_venvs_path ${ZPY_PIPZ_PROJECTS}/${^reply} || return
            venvs_path_goodlist=($reply)
        }

        local bins=(${ZPY_PIPZ_BINS}/*(@Ne['.zpy_is_under ${REPLY:P} $venvs_path_goodlist']))

        local header=(Command Package Runtime)
        local cells=()
        cells+=(${(f)"$(
            zargs -P $ZPY_PROCS -rl \
            -- $bins \
            -- .zpy_pipzlistrow $ZPY_PIPZ_PROJECTS
        )"})

        if [[ $cells ]] {
            local rows=() i
            for (( i=1; i<=$#cells; i+=$#header ))  rows+=(${(j:,:)cells[i,i+$#header-1]})
            rows=(${(i)rows})

            if (( $+commands[rich] )) {
                rows=(${(j:,:)header} $rows)

                rich --csv - <<<${(F)rows}
            } else {
                header=(%B${^header}%b)
                if ! [[ -v NO_COLOR ]]  header=(%F{cyan}${^header}%f)

                cells=($header ${(j:,:s:,:)rows})

                print -rPaC 3 -- $cells
            }
        }
    ;;
    reinstall)  # [--cmd <cmd>[,<cmd>...]] [--activate] [--all|<pkgname>...]  ## subcmd: pipz reinstall
    # Without --cmd, interactively choose.
    # Without --activate, 'vlauncher --link-only' is used.
    # Without --all or <pkgname>, interactively choose.
        if [[ $2 == --help ]] { .zpy_ui_help "${0[9,-1]} $1"; return }
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
            .zpy_all_replies .zpy_pkgspec2name $@ || return
            pkgs=($reply)
        } else {
            .zpy_pipzchoosepkg --multi --header 'Reinstalling . . .' $ZPY_PIPZ_PROJECTS || return
            pkgs=($reply)
        }

        .zpy_pipzunlinkbins $ZPY_PIPZ_PROJECTS $ZPY_PIPZ_BINS $pkgs
        .zpy_pipzrmvenvs $ZPY_PIPZ_PROJECTS $pkgs
        zf_rm -f ${ZPY_PIPZ_PROJECTS}/${^pkgs}/requirements.txt

        zargs -P $ZPY_PROCS -ri___ \
        -- $pkgs \
        -- .zpy_ui_vrun --activate --cd ${ZPY_PIPZ_PROJECTS}/___ .zpy_ui_pipcs
        # `pipz upgrade $pkgs` would also work instead of zargs/vrun,
        # but does a few unnecessary things and takes a little longer.
        .zpy_pipzlinkbins $linkbins_args $pkgs
    ;;
    inject)  # [--cmd <cmd>[,<cmd>...]] [--activate] <installed-pkgname> <extra-pkgspec>...  ## subcmd: pipz inject
    # Without --cmd, interactively choose.
    # Without --activate, 'vlauncher --link-only' is used.
        if [[ $2 == --help ]] { .zpy_ui_help "${0[9,-1]} $1"; return }
        shift

        local linkbins_args=($ZPY_PIPZ_PROJECTS $ZPY_PIPZ_BINS)
        while [[ $1 == --(cmd|activate) ]] {
            if [[ $1 == --cmd      ]] { linkbins_args+=($1 $2); shift 2 }
            if [[ $1 == --activate ]] { linkbins_args+=($1);    shift   }
        }
        linkbins_args+=(--header "Injecting [${(j:, :)@[2,-1]}] ->")

        local pkgname projdir
        .zpy_pkgspec2name $1 || return
        pkgname=$REPLY
        projdir=${ZPY_PIPZ_PROJECTS}/${pkgname}

        if ! [[ $2 && $1 && -d $projdir ]] { .zpy_ui_help "${0[9,-1]} inject"; return 1 }

        local vpath vbinpath badlist=()
        .zpy_venvs_path $projdir || return
        vpath=$REPLY
        vbinpath="${vpath}/venv/bin/"
        badlist=(${vbinpath}*(N:t))

        if [[ $badlist ]]  linkbins_args+=(--no-cmd ${(j:,:)badlist})

        (
            set -e
            cd $projdir
            .zpy_ui_activate
            .zpy_ui_pipacs ${@[2,-1]}
        )
        .zpy_pipzlinkbins $linkbins_args $pkgname
    ;;
    runpip)  # [--cd] <pkgname> <pip-arg>...  ## subcmd: pipz runpip
    # With --cd, run pip from within the project folder.
        if [[ $2 == --help ]] { .zpy_ui_help "${0[9,-1]} $1"; return }
        shift

        local vrun_args=()
        if [[ $1 == --cd ]] { vrun_args+=($1); shift }

        if ! [[ $2 && $1 ]] { .zpy_ui_help "${0[9,-1]} runpip"; return 1 }

        .zpy_pkgspec2name $1 || return
        .zpy_ui_vrun $vrun_args ${ZPY_PIPZ_PROJECTS}/${REPLY} python -m pip ${@[2,-1]}
    ;;
    runpkg)  # <pkgspec> <cmd> [<cmd-arg>...]  ## subcmd: pipz runpkg
        if [[ $2 == --help ]] { .zpy_ui_help "${0[9,-1]} $1"; return   }
        if ! [[ $3 && $2   ]] { .zpy_ui_help "${0[9,-1]} $1"; return 1 }
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
            .zpy_ui_pipi $pkg -q
            $@
        )
    ;;
    cd)  # [<installed-pkgname> [<cmd> [<cmd-arg>...]]]  ## subcmd: pipz cd
    # Without args (or if pkgname is ''), interactively choose.
    # With cmd, run it in the folder, then return to CWD.
        if [[ $2 == --help ]] { .zpy_ui_help "${0[9,-1]} $1"; return }
        shift

        local projdir
        if [[ $1 ]] {
            .zpy_pkgspec2name $1 || return
            projdir=${ZPY_PIPZ_PROJECTS}/${REPLY}; shift
        } else {
            .zpy_pipzchoosepkg $ZPY_PIPZ_PROJECTS || return
            projdir=${ZPY_PIPZ_PROJECTS}/${REPLY}

            if [[ $2 ]]  shift
        }

        if [[ $1 ]]  trap "cd ${(q-)PWD}" EXIT INT QUIT
        cd $projdir
        if [[ $1 ]]  $@
    ;;
    *)
        .zpy_ui_help ${0[9,-1]}
        return 1
    ;;
    }
    # TODO: split subcommands out to 'private' functions. don't forget to update 'zpy help "$0 $1"', etc.
}

# Make a standalone script for any zpy function.
.zpy_ui_mkbin () {  # <func> <dest>
    # TODO: flag for standalone copy, or small source-ing script?
    emulate -L zsh
    if [[ $1 == --help ]] { .zpy_ui_help ${0[9,-1]}; return   }
    if ! [[ $2 && $1   ]] { .zpy_ui_help ${0[9,-1]}; return 1 }

    local dest=${2:a}
    if [[ -d $dest ]]  dest=$dest/$1

    if [[ -e $dest ]] {
        .zpy_log error 'ABORTING launcher creation' 'destination exists' $dest
        return 1
    }

    print -rl -- '#!/bin/zsh' "$(<$ZPY_SRC)" ".zpy_ui_${1} \$@" >$dest
    zf_chmod 0755 $dest
}

.zpy_expose_funcs () {
    emulate -L zsh

    local cmds=(
        envout
        vpyshebang
        pipac
        pipz
        reqshow
        pipi
        vlauncher
        prunevenvs
        vrun
        vpy
        whichpyproj
        da8
        venvs_path
        vpysublp
        vpyvscode
        a8
        pipacs
        pipup
        envin
        pipa
        pypc
        pips
        vpypyright
        pipc
        pipcheckold
        activate
        pipcs
        zpy
    )

    local exposed_funcs
    if ! { zstyle -a :zpy: exposed-funcs exposed_funcs }  exposed_funcs=($cmds)

    local zpyfn
    for zpyfn ( $exposed_funcs ) {
        if (( $+functions[.zpy_ui_${zpyfn}] )) {
            eval "$zpyfn () { .zpy_ui_${zpyfn} \$@ }"
            if (( $+functions[compdef] ))  compdef _.zpy_ui_${zpyfn} $zpyfn
        }
    }
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

_zpy_helpmsg () {  # <zpy-function>
    setopt localoptions extendedglob
    local msg=() REPLY
    .zpy_help $1
    msg=(${(f)REPLY})
    msg=(${msg//#(#b)([^#]*)/%B$match[1]%b})
    if ! [[ -v NO_COLOR ]]  msg=(${msg//#(#b)(\#*)/%F{blue}$match[1]%f})
    _message -r ${(F)msg}
}

_.zpy_ui_mkbin () {
    _zpy_helpmsg ${0[10,-1]}
    # TODO: desc style help, like _.zpy_ui_help?

    local cmds=()
    local -A rEpLy
    .zpy_ui_zpy subcommands
    cmds=(${(k)rEpLy})
    cmds+=(zpy)

    local pipz_cmd
    .zpy_ui_pipz subcommands
    for pipz_cmd ( ${(k)rEpLy} )  cmds+=(${(q-):-"pipz $pipz_cmd"})

    _arguments \
        '(:)--help[Show usage information]' \
        "(--help)1:Function:($cmds)" \
        '(--help)2:Destination:_files'
}

_.zpy_ui_activate () {
    _zpy_helpmsg ${0[10,-1]}
    _arguments \
        '(- 1)--help[Show usage information]' \
        '(--help)--py[Use another interpreter and named venv]:Other Python:(pypy current)' \
        '(--help 1)-i[Interactively choose a project]' \
        '(-)1:New or Existing Project:_path_files -/'
}
_.zpy_ui_a8 () { _.zpy_ui_activate $@ }

_.zpy_ui_envin () {
    _zpy_helpmsg ${0[10,-1]}
    local context state state_descr line opt_args
    _arguments \
        '(- *)--help[Show usage information]' \
        '(--help)--py[Use another interpreter and named venv]:Other Python:(pypy current)' \
        '(-)*: :->reqstxts'
    if [[ $state == reqstxts ]] {
        local blocklist=(${line//(#m)[\[\]()\\*?#<>~\^\|]/\\$MATCH})
        _arguments \
            '(-)*:requirements.txt:_files -F blocklist -g "*.txt"'
    }
}

_zpy_pypi_pkg () {
    local reply
    .zpy_pypi_pkgs
    _arguments \
        "*:PyPI Package:($reply)"
    if (( ${@[(I)--or-local]} ))  _files
}

_.zpy_ui_pipa () {
    _zpy_helpmsg ${0[10,-1]}
    local -U catgs=(dev doc test *-requirements.{in,txt}(N))
    catgs=(${catgs%%-*})
    _arguments \
        '(- *)--help[Show usage information]' \
        "(--help)-c[Use <category>-requirements.in]:Category:($catgs)" \
        '(-)*:Package Spec:_zpy_pypi_pkg --or-local'
}

_.zpy_ui_pipc () {
    _zpy_helpmsg ${0[10,-1]}
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
        local blocklist=(${line//(#m)[\[\]()\\*?#<>~\^\|]/\\$MATCH})
        _arguments \
            '*:requirements.in:_files -F blocklist -g "*.in"' \
            '(*)--[pip-compile Arguments]:pip-compile Argument: '
    }
}

_.zpy_ui_pipcs () {
    _zpy_helpmsg ${0[10,-1]}
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
        local blocklist=(${line//(#m)[\[\]()\\*?#<>~\^\|]/\\$MATCH})
        _arguments \
            '*:requirements.in:_files -F blocklist -g "*.in"' \
            '(*)--[pip-compile Arguments]:pip-compile Argument: '
    }
}

_.zpy_ui_pipcheckold () {
    _zpy_helpmsg ${0[10,-1]}
    _arguments \
        '(* -)--help[Show usage information]' \
        '(--help)--py[Use another interpreter and named venv]:Other Python:(pypy current)' \
        '(--help -i *)--all[Show outdated dependencies for every known project]' \
        '(--help --all *)-i[Choose projects to check interactively]' \
        '(-)*: :_zpy_projects'
}

_.zpy_ui_pipi () {
    _zpy_helpmsg ${0[10,-1]}
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

_.zpy_ui_pips () {
    _zpy_helpmsg ${0[10,-1]}
    local context state state_descr line opt_args
    _arguments \
        '(- *)--help[Show usage information]' \
        '(--help)*: :->reqstxts'
    if [[ $state == reqstxts ]] {
        local blocklist=(${line//(#m)[\[\]()\\*?#<>~\^\|]/\\$MATCH})
        _arguments \
            '(--help)*:requirements.txt:_files -F blocklist -g "*.txt"'
    }
}

_.zpy_ui_pipup () {
    _zpy_helpmsg ${0[10,-1]}
    _arguments \
        '(* -)--help[Show usage information]' \
        '(--help)--py[Use another interpreter and named venv]:Other Python:(pypy current)' \
        "(--help)--only-sync-if-changed[Don't bother syncing if the lockfile didn't change]" \
        '(--help -i *)--all[Upgrade every known project]' \
        '(--help --all *)-i[Choose projects to upgrade interactively]' \
        '(-)*: :_zpy_projects'
}

_.zpy_ui_reqshow () {
    _zpy_helpmsg ${0[10,-1]}
    _arguments \
        '(*)--help[Show usage information]' \
        '(--help)*: :_zpy_projects'
}

() {
    emulate -L zsh
    local zpyfn

    for zpyfn ( .zpy_ui_whichpyproj ) {
        _${zpyfn} () {
            _zpy_helpmsg ${0[10,-1]}
            _arguments '--help[Show usage information]'
        }
    }

    for zpyfn ( .zpy_ui_prunevenvs .zpy_ui_pypc ) {
        _${zpyfn} () {
            _zpy_helpmsg ${0[10,-1]}
            _arguments \
                '(-)--help[Show usage information]' \
                "(--help)-y[Don't ask for confirmation]"
        }
    }

    for zpyfn ( .zpy_ui_vpysublp .zpy_ui_vpyvscode .zpy_ui_vpypyright ) {
        _${zpyfn} () {
            _zpy_helpmsg ${0[10,-1]}
            _arguments \
                '(-)--help[Show usage information]' \
                '(--help)--py[Use another interpreter and named venv]:Other Python:(pypy current)'
        }
    }

    for zpyfn ( .zpy_ui_pipac .zpy_ui_pipacs ) {
        _${zpyfn} () {
            _zpy_helpmsg ${0[10,-1]}
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
    }
}

_.zpy_ui_venvs_path () {
    _zpy_helpmsg ${0[10,-1]}
    _arguments \
        '(- :)--help[Show usage information]' \
        '(--help 1)-i[Interactively choose a project]' \
        '(-)1::Project:_zpy_projects'
}

_.zpy_ui_vlauncher () {
    # TODO: Project completions are too lenient (again?)!
    _zpy_helpmsg ${0[10,-1]}
    local context state state_descr line opt_args
    _arguments \
        '(- * :)--help[Show usage information]' \
        '(--help)--link-only[Only create a symlink to <venv>/bin/<cmd>]' \
        '(--help)--py[Use another interpreter and named venv]:Other Python:(pypy current)' \
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

_.zpy_ui_vpy () {
    _zpy_helpmsg ${0[10,-1]}
    _arguments \
        '(- : *)--help[Show usage information]' \
        '(--help)--py[Use another interpreter and named venv]:Other Python:(pypy current)' \
        "(--help)--activate[Activate the venv (usually unnecessary, and slower)]" \
        '(-)1:Script:_files -g "*.py"' \
        '(-)*:Script Argument: '
}

_.zpy_ui_vpyshebang () {
    _zpy_helpmsg ${0[10,-1]}
    _arguments \
        '(- : *)--help[Show usage information]' \
        '(--help)--py[Use another interpreter and named venv]:Other Python:(pypy current)' \
        '(-)*:Script:_files -g "*.py"'
}

_zpy_projects () {
    local blocklist=(${line//(#m)[\[\]()\\*?#<>~\^\|]/\\$MATCH})
    # TODO: can I get properly styled "Project" header?
    # TODO: Project completions are too lenient
    _tags globbed-files
    _files -x 'Project:' -F blocklist -/ -g '${ZPY_VENVS_HOME}/*/project(@N-/:P)'
}

# TODO: profile this, compare to develop branch, fix sourcing speed

_.zpy_ui_vrun () {
    # TODO: Project completions are too lenient (again?)!
    setopt localtraps
    _zpy_helpmsg ${0[10,-1]}
    local context state state_descr line opt_args
    integer NORMARG
    _arguments -n \
        '(- * :)--help[Show usage information]' \
        '(--help)--py[Use another interpreter and named venv]:Other Python:(pypy current)' \
        '(--help)--cd[Run the command from within the project folder]' \
        "(--help)--activate[Activate the venv (usually unnecessary for venv-installed scripts, and slower)]" \
        '(-)1:Project:_zpy_projects' \
        '(-)*::: :->cmd'
    local vname=venv
    if (( words[(I)--py] )) && (( words[(i)--py] < NORMARG )) {
        local reply
        .zpy_argvenv ${words[${words[(i)--py]} + 1]} || return
        vname=$reply[1]
    }
    if [[ $line[1] ]] {
        local projdir=${${(Q)line[1]/#\~/~}:P} REPLY
        .zpy_venvs_path $projdir
        local venv=$REPLY/$vname
        if (( words[(I)--cd] )) && (( words[(i)--cd] < NORMARG )) {
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

_.zpy_ui_help () {
    _zpy_helpmsg ${0[10,-1]}
    local cmds=() cmd desc
    local -A rEpLy
    .zpy_ui_zpy subcommands
    for cmd desc ( ${(kv)rEpLy} )  cmds+=("${cmd}:${desc}")
    cmds+=('zpy:Optional launcher for all zpy functions as subcommands')
    .zpy_ui_pipz subcommands
    for cmd desc ( ${(kv)rEpLy} )  cmds+=("pipz ${cmd}:${desc}")
    _arguments \
        '(*)--help[Show usage information]' \
        '(--help)*:Function:(($cmds))'
}

_.zpy_ui_zpy () {
    local cmds=() cmd desc
    local -A rEpLy
    ${0[2,-1]} subcommands
    for cmd desc ( ${(kv)rEpLy} )  cmds+=("${cmd}:${desc}")
    local context state state_descr line opt_args
    _arguments \
        '(1 *)--help[Show usage information]' \
        '(--help)1:Function:(($cmds))' \
        '(--help)*:: :->sub_arg'
    if [[ $state != sub_arg ]] {
        _zpy_helpmsg ${0[10,-1]}
    } else {
        _.zpy_ui_${line[1]}
    }
}

_.zpy_ui_pipz () {
    setopt localtraps
    local cmds=() cmd desc
    local -A rEpLy
    ${0[2,-1]} subcommands
    for cmd desc ( ${(kv)rEpLy} )  cmds+=("${cmd}:${desc}")
    integer NORMARG
    local context state state_descr line opt_args
    _arguments \
        '(1 *)--help[Show usage information]' \
        '(--help)1:Operation:(($cmds))' \
        '(--help)*:: :->sub_arg'
    if [[ $state != sub_arg ]] {
        _zpy_helpmsg ${0[10,-1]}
    } else {
        _zpy_helpmsg "$0[10,-1] $line[1]"
        case $line[1] {
        install)
            _arguments \
                '(* -)--help[Show usage information]' \
                '(--help)--cmd[Specify commands to add to your path, rather than interactively choosing]:Command (comma-separated): ' \
                '(--help)--activate[Ensure command launchers explicitly activate the venv (usually unnecessary)]' \
                '(-)*:Package Spec:_zpy_pypi_pkg --or-local'
        ;;
        reinstall)
            local blocklist=(${(Q)words[2,-1]})
            while [[ $blocklist[1] == --(help|activate|all|cmd) ]] {
                if [[ $blocklist[1] == --cmd ]] {
                    blocklist=($blocklist[3,-1])
                } else {
                    blocklist=($blocklist[2,-1])
                }
            }
            local pkgs=($ZPY_PIPZ_PROJECTS/*(/N:t))
            pkgs=(${pkgs:|blocklist})
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
            local blocklist=(${(Q)words[2,-1]})
            local pkgs=($ZPY_PIPZ_PROJECTS/*(/N:t))
            pkgs=(${pkgs:|blocklist})
            _arguments \
                '(* -)--help[Show usage information]' \
                '(--help *)--all[Uninstall all installed apps]' \
                "(-)*:Installed Package Name:($pkgs)"
        ;;
        upgrade)
            local blocklist=(${(Q)words[2,-1]})
            local pkgs=($ZPY_PIPZ_PROJECTS/*(/N:t))
            pkgs=(${pkgs:|blocklist})
            _arguments \
                '(* -)--help[Show usage information]' \
                '(--help *)--all[Upgrade all installed apps]' \
                "(-)*:Installed Package Name:($pkgs)"
        ;;
        list)
            local blocklist=(${(Q)words[2,-1]})
            local pkgs=($ZPY_PIPZ_PROJECTS/*(/N:t))
            pkgs=(${pkgs:|blocklist})
            _arguments \
                '(* -)--help[Show usage information]' \
                '(--help *)--all[List all installed apps]' \
                "(-)*:Installed Package Name:($pkgs)"
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
                local REPLY pkgname
                .zpy_pkgspec2name ${line[1]} || return
                pkgname=$REPLY

                trap "cd ${(q-)PWD}" EXIT INT QUIT
                cd $ZPY_PIPZ_PROJECTS/${(Q)pkgname}
                _normal -P
            }
        ;;
        }
    }
}

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
    reply=(${(f)"$(<$txt)"})
}

.zpy_expose_funcs
if (( $+functions[compdef] )) {
    compdef _.zpy_ui_mkbin .zpy_ui_mkbin
    compdef _.zpy_ui_help .zpy_ui_help
}

if (( $+functions[zsh-defer] )) {
    zsh-defer .zpy_ui_zpy subcommands
    zsh-defer .zpy_pypi_pkgs
}
