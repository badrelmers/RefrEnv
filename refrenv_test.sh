#!/bin/bash

# set -xv
# export LC_ALL=en_US.UTF-8 ; export LC_CTYPE=en_US.UTF-8 ; export LANG=en_US.UTF-8
# export PYTHONIOENCODING=utf-8

# Set magic variables for current file & dir
__dir="$(cd "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# __mydir="$(cygpath -w "${__dir}" | tr '\\' '/')" # this convert the path to use the universal path that both win and cygwin accept like: F:/path/
# __file="${__dir}/$(basename -- "${BASH_SOURCE[0]}")"
# __base="$(basename -- ${__file} .sh)"
# __root="$(cd "$(dirname -- "${__dir}")" && pwd)" # <-- change this as it depends on your app

cd "${__dir}" || exit


# Better handling of white space
# standardIFS="$IFS"
# IFS=$'\n\t'
# Disable filename expansion (globbing).
# set -o noglob


########################################################
_common_functions(){ 
    # puesto ke abro este script usando otro script entonces uso -n para ver si la variable datenow es definida para no sobreescribirla
    [[ -n ${datenow:-} ]] || { datenow=$(date +%Y%m%d_%H%M%S) ; export datenow ; }

    echocolorsV3(){ 
        # ___forground______________________________________
        INFOC()    { echo -ne "\e[32m" ; }              # green
        WARNC()    { echo -ne "\e[33m" ; }              # yellow
        ERRORC()   { echo -ne "\e[0;1;31m" ; }          # bright red
        HIDEC()    { echo -ne "\e[37m" ; }              # white: do not use bright white because of my mintty white template
        INFO2C()   { echo -ne "\e[36m" ; }              # bright cyan
        INFO3C()   { echo -ne "\e[0;1;35m" ; }          # bright purple
        INFO4C()   { echo -ne "\e[0;1;34m" ; }          # blue
        
        # ___background______________________________________
        INFOCB()   { echo -ne "\e[0;30m\e[42m" ; }      # black on green 
        WARNCB()   { echo -ne "\e[0;1;33;40;7m" ; }     # black on yellow ;usa invert 7; y light text 1 
        ERRORCB()  { echo -ne "\e[0;1;37m\e[41m" ; }    # bright white on red
        HIDECB()   { echo -ne "\e[0;1;30m\e[47m" ; }    # hide color: white on grey (bright)
        # HIDEC()   { echo -ne "\e[0;1;7;30m\e[47m" ; }   # hide color: white on grey (darker)
        INFO2CB()  { echo -ne "\e[0;30m\e[46m" ; }      # black on white blue (cyan)
        INFO3CB()  { echo -ne "\e[0;1;37m\e[45m"; }     # bright white on purple
        INFO4CB()  { echo -ne "\e[0;1;37m\e[44m" ; }    # bright white on blue; 1  is needed sino 37 vuelve grey in mintty

        ENDC()     { echo -ne "\e[0m" ; }               # reset colors
        ENDCnl()   { echo -e "\e[0m" ; }                # reset colors + newline
    }
    echocolorsV3
    export -f echocolorsV3


    _trap_V5(){ 
        ###################################################
        # unofficial strict mode v5
        # author: Badr Elmers
        ###################################################
        # change this as needed
        local exit_on_error pause_the_trap
        # exit_on_error=yes  # comment this so the script never exit on errors
        pause_the_trap=yes # if exit_on_error is commented, comment this so the script never pause
        
        ###################################################
        # Bugs & solutions
        ###################################################
        # bug1: undefined variables must be  ${var:-}
        # bug2: grep -q / grep -m1 / head -1  fail with pipefail  ; Do not use -q option with grep, but redirect output: 1> /dev/null 2>&1 . for grep -m1 / head ..Etc use || true 
        # bug3: don't allow a short-circuit expression '[[ -f file ]] && command' to be on the last line of a script, or use || true, or use if..then..fi ; otherwise the script or function will exit with non 0 exit code if the short-circuit is false 
        # bug4: remember that errexit is disabled with if, ||, &&, !, while, until. even if i put set -e inside the subshell or function, set -e will be disabled, so the script will never stop on errors
        # bug5: dont use export/local/somecommand $(...) , separate them
        # bug6: use <<< instead of <() process substitution. set -e indeed applies to the commands inside a process substitution as well (as opposed to a command substitution), though a failure there won't abort the script as a whole
        # bug7: use i=$((i+1)) or bc instead of  let i++,  ((i++)), expr 
        # bug8: read aborts if it reads from a file with a missing end of line, so always add the EOL
        # bug9: Bash 4.3 and older chokes on empty arrays with set -u ; disable it with set +u if needed. xp have bash 4.3
        # bug10: don t use exit 0 inside trap ERR, if i must use exit (which is not needed when we use set- e) then use exit 1 not exit nor exit 0
        # bug11: set -u does not trigger ERR traps, but it is not important to trap the undefined variables because it happens the first time i write a script only.
        # bug12: use set +u to Source/. A Nonconforming script
        ###################################################
        # do not change anything bellow

        if [[ ${exit_on_error:-} == yes ]] ; then
            set -o errexit   # -e: exit script on error
        fi
        set -o nounset   # -u: unset variables force exit.
        set -o pipefail  # failure on any command errors in pipeline
        set -o errtrace  # -E: functions/command substitutions/sub-shell inherit ERR trap
        set -o functrace # -T: shell functions inherit DEBUG trap
        shopt -s inherit_errexit 2>/dev/null || true # In Bash 4.4+ only. causes command substitutions to inherit the -e option.  By default, those sub-shells disable -e.

        error_handler(){ 
        # run the trap inside a sub-shell, useful for use in scripts running in interactive shell,so errores commands Iwrite in the shell do not call this trap
        # error_handler()(
        
            local _lasterr _BASH_COMMAND _BASH_SOURCE _BASH_LINENO _FUNCNAME
            _lasterr=$1
            # _LINENO=${LINENO}
            _BASH_COMMAND="${BASH_COMMAND:-unkownnnCOM}"
            _BASH_SOURCE=( "${BASH_SOURCE[@]:-unkownnnSRC}" )
            _BASH_LINENO=( "${BASH_LINENO[@]:-unkownnnLN}" )
            _FUNCNAME=( "${FUNCNAME[@]:-unkownnnFUNC}" )

            # print only first 3 lines of the command
            local ___bash_command
            ___bash_command=$( printf '%s' "${_BASH_COMMAND}" | head -3)
            echo ""
            # HIDECB ; echo "trap..._Func: ${_FUNCNAME[1]}" ; ENDC
            # TODO: delete this because i will never use trap '...' ERR EXIT
            # [[ $1 -eq 0 ]] is to prevent running the trap because of trap EXIT when there is no error, i can use use trap ERR instead of trap ERR EXIT, but trap ERR do not trigger trap with undefined variables error; that s why i use trap ERR EXIT and [[ $1 -eq 0 ]]
            # [[ $1 -eq 0 ]] && return 0
                    
            # set +x # disable tracing so the trap messages will be seen cleaner
            ERRORCB ; printf '%s' "Error ${_BASH_SOURCE[1]}" ; WARNCB ; printf '%s' " ${_BASH_LINENO[0]} " ; ERRORCB ; printf '%s' "Exit status" ; ENDC ; WARNCB ; printf '%s' " ${_lasterr} " ; ENDCnl

            if [ ${#_FUNCNAME[@]} -gt 2 ]; then
                local _funcnamee
                for ((i=0; i < ${#_FUNCNAME[@]} - 1; i++)); do
                    _funcnamee="${_FUNCNAME[$i]}()"
                    [ "$i" -eq "0" ] && _funcnamee=$(printf '%s' "${_BASH_COMMAND}" | head -1) # get 1 line only of the command
                    ERRORC ; printf '%s' "  |__ " ; ENDC ; printf '%s' "${_BASH_SOURCE[$i+1]} "; ERRORC ; printf '%s' "${_BASH_LINENO[$i]}" ; WARNC ; printf '%s\n' " $_funcnamee" ; ENDC
                done
            fi
            ERRORCB ; printf '%s' "Command:" ; ENDC ; WARNCB ; printf '%s' " ${___bash_command} " ; ENDCnl
            echo " "


            if [[ ${pause_the_trap:-} == yes ]] ; then
                read -p 'Press enter to exit the trap'
                
                # read -p 'Press enter to exit the trap' < /dev/tty
                
                # tty=$(readlink /proc/$$/fd/2)
                # read -p 'Press enter to exit the trap' < $tty
            fi
        
            # exit 0 will prevent triggering trap again in outside function after running in an inner function
            # exit 0 do not seem to do anything,set -e already makes the script exit , so i do no think i need to use exit here
            # exit 1 will trigger trap EXIT if trap ERR was triggered first, so the trap is run twice
            # exit 0 will perturb sub-shell,see this will print ccc when it should not (if i use exit 1 it works fine) ,bash 4.4.12(3) of 2017:
            # set -o errtrace; set -o errexit; trap 'echo errrrr;exit ' ERR; aaa=$(badddd); echo "ccc" 
        # )
        }

        # v2
        # trap - EXIT is needed to prevent running the trap twice when ERR is triggered
        # why use ERR and EXIT? because undefined variables will not trigger the trap
        # trap 'error_handlerV2 $? ${LINENO}; trap - EXIT' EXIT ERR
        # v3
        # bueno no usare EXIT sino usare solo ERR pk necesito usar EXIT para llamar la function ke mata los procesos, y no es importante trap the undefined variables ya ke pasa solo la primera vez ke escribo el script
        trap 'error_handler $?' ERR
        export -f error_handler
    }
    _trap_V5
    
    
    
    # TODO do i need this today? no creo pk veo ke todo se cierra bien today even tail
    list_offchilds(){ 
        # use it like this: list_offchilds PIDofProcess
        # create a list pid's of a parent's child process(es). Recursively till it finds the last child process which does not have any childs. It does not give you a tree view. It just lists all pid's.
        [[ "$1" ]] || return      # exit if no PID exist
        tp=$(pgrep -P $1 || true) # get childs pids of parent pid
        for i in $tp; do          # loop through childs
            if [ -z $i ]; then    # check if empty list
                # read -p 'there is nothing to kill, press enter to exit'
                # exit #if empty: exit
                return
            else
                echo -n "$i "     # print childs pid. cuidado no anades nada a este echo ya ke es el ke imprime el proceso para matarlo luego...
                list_offchilds $i # call list_offchilds again with child pid as the parent
            fi
        done
    }
    export -f list_offchilds

    cleanupV2(){ 
        # this close all when i close this bash
        
        # Generally, send 15, and wait a second or two, and if that doesn't work, send 2, and if that doesn't work, send 1. If that doesn't, REMOVE THE BINARY because the program is badly behaved!
        # Don't use kill -9.

        # ==>  You may need to specify the full path to use kill from within some shells, including bash, the default Cygwin shell. This is because bash defines a kill builtin function; see the bash man page under BUILTIN COMMANDS for more information. To make sure you are using the Cygwin version, try /bin/kill --version

        # to kill mintty with this method tengo ke abrirlo asi :mintty --nodaemon
        HIDEC
        printf '\n\n\n\n'
        allprocesses=$( list_offchilds $$ )
        echo "____killing processes $allprocesses _____________________"
        # kill $( list_offchilds $$ ) 
        kill $allprocesses || true
        sleep 3
        kill -9 $allprocesses || true
        printf '\n'
        read -p 'we finished killing all processes, press enter to exit'
        exit # https://unix.stackexchange.com/questions/230421/unable-to-stop-a-bash-script-with-ctrlc/230731#230731
        ENDC
    }
    
    function trap_cleaning { 
        ### cleaning and trap ####
        # trap "cleanupV2" INT QUIT TERM EXIT
        # trap "cleanupV2; trap - INT QUIT TERM EXIT" INT QUIT TERM EXIT
        # the trap is called twice when I use ctrl-c with both methods above so i use trap EXIT to solve it, it seems to work fine
        trap "cleanupV2" EXIT
    }
    # trap_cleaning
    export -f trap_cleaning

}
_common_functions
export -f _common_functions


change_priority(){ 
    # if run with admin right it change priority to:     cpu:24  I/O:high    mem: 5
    # if run without admin right it change priority to:  cpu:13  I/O:normal  mem: 5
    # this will change the priority of this bash and what run from it
    # if i run this exe without PID it doesn t change the IO priority in cygwin, because priority.exe get a diferent PID of bash!!! solucion: use the pid and convert it to win pid
    # $BINBINLIN/_bin/priority.exe /realtime $(</proc/$$/winpid)
    $BINBINLIN/_bin/priority.exe /normal $(</proc/$$/winpid)  # es mejor dejarlo en normal he notado ke el pc se ralentiza como decian por internet, asi lo dejare en normal salvo si lo necesito obligatoriamente
}
# change_priority

################################################################################



trap 'setx refrenv_test "" >/dev/null' EXIT

INFO2CB ; echo run me from bash ; ENDCnl
echo "";echo "";echo ""


##### met1: 
# echo '  if you want to test refreshing a variable too, then create now a variable in'
# echo '  windows using the Control Panel or regedit then press enter, and do not forget' 
# echo '  to delete it before you start this script again.'
# printf '  the variable key should be: ' ; INFO2C ; printf refrenv_test ; ENDCnl
# echo ""
# if test -n "${refrenv_test:-}" ; then
    # INFO2C ; printf 'refrenv_test '; ENDC; printf 'is: '; INFO3C ; printf '%s' ${refrenv_test:-} ; ENDC ; echo ' you have to change it now to see if it will be refreshed... then press enter' ; ENDCnl
# fi
# echo ""
# INFOC ; read -p 'press enter to start the test' ; ENDCnl



##### met2: better
if [[ ${refrenv_test:-} == goooooooood ]] ; then
    WARNCB; printf '   the variable: '; INFO2C ; printf refrenv_test ; WARNCB; printf ' is already setup, I need it to be undefined to test this script. You have to delete it first using the Control Panel, or simply run this script again and it should be solved. press enter to exit...'; ENDCnl
    read -p '' 
    exit
fi

# do not use reg to touch the env ,windows does not refresh the env list like it does with setx
# reg delete 'HKEY_CURRENT_USER\Environment' /v refrenv_test /f >/dev/null
# reg add 'HKEY_CURRENT_USER\Environment' /v refrenv_test /t REG_SZ /d goooooooood /f >/dev/null
setx refrenv_test goooooooood




INFO4CB ; echo '# test refrenv.sh in bash #############################' ; ENDCnl
INFOC ; echo _ test 1 _________________________________________ ; ENDC
(source refrenv.sh; printf '%s\n' "---> refrenv_test is: ${refrenv_test:-}")
INFOC ; echo _ test 2 _________________________________________ ; ENDC
(RefrEnv_StrictRefresh=yes ; source refrenv.sh; printf '%s\n' "---> refrenv_test is: ${refrenv_test:-}")
INFOC ; echo _ test 3 _________________________________________ ; ENDC
(RefrEnv_ResetPath=yes ; source refrenv.sh; printf '%s\n' "---> refrenv_test is: ${refrenv_test:-}")
INFOC ; echo _ test 4 _________________________________________ ; ENDC
(RefrEnv_ResetPath=yes ; RefrEnv_StrictRefresh=yes; source refrenv.sh; printf '%s\n' "---> refrenv_test is: ${refrenv_test:-}")
# (RefrEnv_debug=yes ; source refrenv.sh)
INFOC ; echo _ test 5 _________________________________________ ; ENDC
(RefrEnv_help=yes ; source refrenv.sh >/dev/null)
echo "";echo "";echo ""



INFO4CB ; echo '# test refrenvz.sh in zsh #############################' ; ENDCnl
if command -v zsh >/dev/null; then
    INFOC ; echo _ test 1 _________________________________________ ; ENDC
    zsh -l -c "cd '${__dir}' ; source refrenvz.sh; printf '%s\\n' \"---> refrenv_test is: \$refrenv_test\""
    INFOC ; echo _ test 2 _________________________________________ ; ENDC
    zsh -l -c "cd '${__dir}' ; RefrEnv_StrictRefresh=yes ; source refrenvz.sh; printf '%s\\n' \"---> refrenv_test is: \$refrenv_test\""
    INFOC ; echo _ test 3 _________________________________________ ; ENDC
    zsh -l -c "cd '${__dir}' ; RefrEnv_ResetPath=yes ; source refrenvz.sh; printf '%s\\n' \"---> refrenv_test is: \$refrenv_test\""
    INFOC ; echo _ test 4 _________________________________________ ; ENDC
    zsh -l -c "cd '${__dir}' ; RefrEnv_ResetPath=yes ; RefrEnv_StrictRefresh=yes; source refrenvz.sh; printf '%s\\n' \"---> refrenv_test is: \$refrenv_test\""
    INFOC ; echo _ test 5 _________________________________________ ; ENDC
    zsh -l -c "cd '${__dir}' ; RefrEnv_help=yes ; source refrenvz.sh >/dev/null"
else
    WARNCB ; echo zsh was not found; ENDCnl
fi
echo "";echo "";echo ""



INFO4CB ; echo '# test refrenv.bat in cmd #############################' ; ENDCnl
INFOC ; echo _ test 1 _________________________________________ ; ENDC
cmd /V:ON /S /C "call refrenv.bat & echo ---^>  refrenv_test is: !refrenv_test!"
echo "";echo "";echo ""



INFO4CB ; echo '# test refrenv.ps1 in powershell #############################' ; ENDCnl
if command -v powershell >/dev/null; then
    INFOC ; echo _ test 1 _________________________________________ ; ENDC
    # powerhsell 2 when run from bash does not exit after running the command! so we use  echo "" |
    # echo "" | powershell -NoExit -ExecutionPolicy Unrestricted -Command "& { . .\refrenv.ps1 ; exit }"
    echo "" | powershell -ExecutionPolicy Unrestricted -Command '& { . .\refrenv.ps1 ; echo "---> refrenv_test is: $env:refrenv_test" }'
else
    WARNCB ; echo powershell was not found; ENDCnl
fi
echo "";echo "";echo ""



INFO4CB ; echo '# test refrenv.ps1 in powershell core pwsh #############################' ; ENDCnl
if command -v pwsh >/dev/null; then
    pwsh_exe=pwsh
else
    my_pwsh_exe="/cygdrive/f/_inst_/powershell/PS7/pwsh.exe"
    if test -f "$my_pwsh_exe"; then
    pwsh_exe="$my_pwsh_exe"
    else
        WARNCB ; echo pwsh was not found; edit this script to point to the correct pwsh if you need to test it; ENDCnl
    fi
fi
if [[ -n "${pwsh_exe:-}" ]] ; then
    INFOC ; echo _ test 1 _________________________________________ ; ENDC
    "$pwsh_exe" -ExecutionPolicy Unrestricted -Command '& { . .\refrenv.ps1 ; echo "---> refrenv_test is: $env:refrenv_test" }'
fi
echo "";echo "";echo ""



setx refrenv_test "" >/dev/null
# do not use reg to touch the env ,windows does not refresh the env list like it does with setx
# reg delete 'HKEY_CURRENT_USER\Environment' /v refrenv_test /f >/dev/null

echo "";echo "";echo ""
echo 'you should see in all the tests this: ---> refrenv_test is: goooooooood'
echo 'and there should not be any red color, otherwise there is a bug.'
echo "";echo "";echo ""

INFOC ; read -p 'test finished... press enter to exist' ; ENDCnl

