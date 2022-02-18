#!/bin/bash

# author: Badr Elmers 2021
# description: RefrEnv = refresh environment. for bash
# version: 1.1
# https://github.com/badrelmers/RefrEnv
# https://stackoverflow.com/questions/171588/is-there-a-command-to-refresh-environment-variables-from-the-command-prompt-in-w

# this script is safe to use with the bash strict mode: set -eEu -o pipefail ; shopt -s inherit_errexit 
###########################################################################################

RefrEnv_Temp_Dir="${TEMP}/RefrEnvBash"

# use subshell so we do not pollute the parent script
(

# ### USAGE ################################################################
RefrEnv_help(){
printf '%s' '
NAME
    RefrEnv - Refresh the Environment for Bash

SYNOPSIS
    source refrenv.sh
    
DESCRIPTION
    By default with no arguments, this script will do a full 
    refresh (refresh all non critical variables*, and refresh the PATH).

    use can use the following variables to change some behaviours:
    
    RefrEnv_StrictRefresh=yes   Strict mode (secure refresh). this prevent refreshing a
                                variable if it is already defined in the actual bash session. 
                                The PATH will be refreshed.
                                
    RefrEnv_ResetPath=yes       Reset the actual PATH inside bash, then refresh it with the new PATH.
                                this will delete any PATH added by the script who called RefrEnv. 
                                it is equivalent to running a new bash session.

    RefrEnv_debug=yes           Debug what this script do. The folder containing the 
                                files used to set the variables will be open, then see 
                                _NewEnv.sh this is the file which run inside your script
                                to setup the new variables, you can also revise the 
                                intermediate .txt files.
                              
    RefrEnv_help=yes            Print the help.

    you can also put this script in windows\systems32 or another place in your $PATH then call it from an interactive console by writing: source refrenv.sh

    *critical variables: are variables which belong to bash or windows and should not be refreshed normally like:
    - windows vars:
    ALLUSERSPROFILE APPDATA CommonProgramFiles CommonProgramFiles(x86) CommonProgramW6432 COMPUTERNAME ComSpec HOMEDRIVE HOMEPATH LOCALAPPDATA LOGONSERVER NUMBER_OF_PROCESSORS OS PATHEXT PROCESSOR_ARCHITECTURE PROCESSOR_ARCHITEW6432 PROCESSOR_IDENTIFIER PROCESSOR_LEVEL PROCESSOR_REVISION ProgramData ProgramFiles ProgramFiles(x86) ProgramW6432 PUBLIC SystemDrive SystemRoot TEMP TMP USERDOMAIN USERDOMAIN_ROAMINGPROFILE USERNAME USERPROFILE windir SESSIONNAME
    - bash vars:
    BASH BASHOPTS BASHPID BASH_ALIASES BASH_ARGC BASH_ARGV BASH_CMDS BASH_COMMAND BASH_COMPLETION_VERSINFO BASH_LINENO BASH_REMATCH BASH_SOURCE BASH_SUBSHELL BASH_VERSINFO BASH_VERSION COLUMNS COMP_WORDBREAKS CYGWIN CYG_SYS_BASHRC DIRSTACK EUID EXECIGNORE FUNCNAME GROUPS HISTCMD HISTCONTROL HISTFILE HISTFILESIZE HISTSIZE HISTTIMEFORMAT HOME HOSTNAME HOSTTYPE IFS INFOPATH LANG LC_ALL LC_COLLATE LC_CTYPE LC_MESSAGES LC_MONETARY LC_NUMERIC LC_TIME LINENO LINES MACHTYPE MAILCHECK OLDPWD OPTERR OPTIND ORIGINAL_PATH OSTYPE PATH PIPESTATUS POSIXLY_CORRECT PPID PRINTER PROFILEREAD PROMPT_COMMAND PS0 PS1 PS2 PS3 PS4 PWD RANDOM SECONDS SHELL SHELLOPTS SHLVL SSH_ASKPASS TERM TERM_PROGRAM TERM_PROGRAM_VERSION TZ UID USER _backup_glob CHILD_MAX BASH_COMPAT FUNCNEST COMP_TYPE COMP_KEY READLINE_LINE_BUFFER READLINE_POINT PROMPT_DIRTRIM BASH_EXECUTION_STRING COPROC_PID COPROC GLOBIGNORE HISTIGNORE SRANDOM READLINE_MARK EPOCHSECONDS EPOCHREALTIME BASH_ARGV0 COMPREPLY COMP_CWORD COMP_LINE COMP_POINT COMP_WORDS EMACS FCEDIT FIGNORE HOSTFILE IGNOREEOF INPUTRC INSIDE_EMACS MAPFILE READLINE_LINE REPLY TIMEFORMAT TMOUT TMPDIR histchars
    
    ### INFO #################################################################
    # This script reload environment variables inside bash every time you want environment changes to propagate, so you do not need to restart bash after setting a new variable with setx or when installing new apps which add new variables ...etc

    # for PATH: this script append the new paths to the old path of the parent script which called this script; its better than overwriting the old path; otherwise it will delete any newly added path by the parent script

    # ________
    # windows recreate the path using three places at less:
    # the User namespace:    HKCU\Environment
    # the System namespace:  HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment
    # the Session namespace: HKCU\Volatile Environment
    # This script will merge all the three and remove any duplicates. this is what windows do by default too

    # there is this too which cmd seems to read when first running, but it contains only TEMP and TMP,so this script will not use it
    # HKEY_USERS\.DEFAULT\Environment
    
    
'
}

### TESTING #################################################################
# To test this script with extreme cases do
    # :: Set a bad variable
    # add a var in reg HKCU\Environment as the following, and see that echo is not executed.
    # so save this in reg:
    # all 32 characters: & % ' ( ) ~ + @ # $ { } [ ] ; , ` ! ^ | > < \ / " : ? * = . - _ & echo baaaad
    # and this:
    # (^.*)(Form Product=")([^"]*") FormType="[^"]*" FormID="([0-9][0-9]*)".*$
    # and use set to print those variables and see if they are saved without change
    
    
# invalid characters (illegal characters in file names) in Windows using NTFS
# \ / : * ? "  < > |  and ^ in FAT 



###############################################################################################
###############################################################################################
###############################################################################################

refrenv_main(){
    local runme=yes
    local i
    
    if [[ ${RefrEnv_StrictRefresh:-} == yes ]] ; then
        local strict_txt=' - (Strict refresh)'
    fi
    if [[ ${RefrEnv_ResetPath:-} == yes ]] ; then
        local ResetPath_txt=' - (Reset Path)'
    fi
    if [[ ${RefrEnv_debug:-} == yes ]] ; then
        local debug_txt=' - (Debug enabled)'
    fi
    if [[ ${RefrEnv_help:-} == yes ]] ; then
        RefrEnv_help
        local runme=no
    fi

    
    if [[ "${runme:-}" = "yes" ]] ; then
        echo "RefrEnv - Refresh the Environment for Bash${strict_txt:-}${ResetPath_txt:-}${debug_txt:-}"
        
        rm -rf "${RefrEnv_Temp_Dir}" || true
        mkdir -p "${RefrEnv_Temp_Dir}"

        getNewlyAddedVars '/HKLM/System/CurrentControlSet/Control/Session Manager/Environment'
        getNewlyAddedVars '/HKCU/Environment'
        getNewlyAddedVars '/HKCU/Volatile Environment'
        getNewPATHS
    fi
    
    # unset all the functions we used in this script so we do not pollute the parent script
    # unset -f _common_functions echocolorsV3 INFOC WARNC ERRORC HIDEC INFO2C INFO3C INFO4C INFOCB WARNCB ERRORCB HIDECB INFO2CB INFO3CB INFO4CB ENDC ENDCln _trap_V5 error_handler 
    unset -f RefrEnv_help refrenv_main getNewlyAddedVars _safe_vars getNewPATHS ExpandEnvironmentStrings
         
}

####################################################################

getNewlyAddedVars(){ 
    # get the newly added variables from registry which are not defined right now in bash
    local regPath="$1"

    local IFSorg=$IFS
    IFS=$'\n'
    
    # print all reg variables and remove critical ones, i created the list using: the windows registry, set declare compgen printenv env and the bash changelog : https://github.com/bminor/bash/blob/8868edaf2250e09c4e9a1c75ffe3274f28f38581/NEWS so it is up to bash-5.1
    # i used also the manual
    # https://web.archive.org/web/20210507012307/https://gnu.org/software/bash/manual/html_node/Bash-Variables.html
    # i will not add :
    # BASH_LOADABLES_PATH
    # ENV and BASH_ENV
    # BASH_XTRACEFD

    # --list is important otherwise the reg subdirectories are printed , volatile environment for example have a folder/subkey called 1 and it is printed if i do not use --list
    local regresult
    regresult=$(regtool list --list "${regPath}")
    regresult=$(printf '%s' "${regresult}" | grep -i -v -e '^ALLUSERSPROFILE$' -e '^APPDATA$' -e '^CommonProgramFiles$' -e '^CommonProgramFiles(x86)$' -e '^CommonProgramW6432$' -e '^COMPUTERNAME$' -e '^ComSpec$' -e '^HOMEDRIVE$' -e '^HOMEPATH$' -e '^LOCALAPPDATA$' -e '^LOGONSERVER$' -e '^NUMBER_OF_PROCESSORS$' -e '^OS$' -e '^PATHEXT$' -e '^PROCESSOR_ARCHITECTURE$' -e '^PROCESSOR_ARCHITEW6432$' -e '^PROCESSOR_IDENTIFIER$' -e '^PROCESSOR_LEVEL$' -e '^PROCESSOR_REVISION$' -e '^ProgramData$' -e '^ProgramFiles$' -e '^ProgramFiles(x86)$' -e '^ProgramW6432$' -e '^PUBLIC$' -e '^SystemDrive$' -e '^SystemRoot$' -e '^TEMP$' -e '^TMP$' -e '^USERDOMAIN$' -e '^USERDOMAIN_ROAMINGPROFILE$' -e '^USERNAME$' -e '^USERPROFILE$' -e '^windir$' -e '^SESSIONNAME$'                     -e '^BASH$' -e '^BASHOPTS$' -e '^BASHPID$' -e '^BASH_ALIASES$' -e '^BASH_ARGC$' -e '^BASH_ARGV$' -e '^BASH_CMDS$' -e '^BASH_COMMAND$' -e '^BASH_COMPLETION_VERSINFO$' -e '^BASH_LINENO$' -e '^BASH_REMATCH$' -e '^BASH_SOURCE$' -e '^BASH_SUBSHELL$' -e '^BASH_VERSINFO$' -e '^BASH_VERSION$' -e '^COLUMNS$' -e '^COMP_WORDBREAKS$' -e '^CYGWIN$' -e '^CYG_SYS_BASHRC$' -e '^DIRSTACK$' -e '^EUID$' -e '^EXECIGNORE$' -e '^FUNCNAME$' -e '^GROUPS$' -e '^HISTCMD$' -e '^HISTCONTROL$' -e '^HISTFILE$' -e '^HISTFILESIZE$' -e '^HISTSIZE$' -e '^HISTTIMEFORMAT$' -e '^HOME$' -e '^HOSTNAME$' -e '^HOSTTYPE$' -e '^IFS$' -e '^INFOPATH$' -e '^LANG$' -e '^LC_ALL$' -e '^LC_COLLATE$' -e '^LC_CTYPE$' -e '^LC_MESSAGES$' -e '^LC_MONETARY$' -e '^LC_NUMERIC$' -e '^LC_TIME$' -e '^LINENO$' -e '^LINES$' -e '^MACHTYPE$' -e '^MAILCHECK$' -e '^OLDPWD$' -e '^OPTERR$' -e '^OPTIND$' -e '^ORIGINAL_PATH$' -e '^OSTYPE$' -e '^PATH$' -e '^PIPESTATUS$' -e '^POSIXLY_CORRECT$' -e '^PPID$' -e '^PRINTER$' -e '^PROFILEREAD$' -e '^PROMPT_COMMAND$' -e '^PS0$' -e '^PS1$' -e '^PS2$' -e '^PS3$' -e '^PS4$' -e '^PWD$' -e '^RANDOM$' -e '^SECONDS$' -e '^SHELL$' -e '^SHELLOPTS$' -e '^SHLVL$' -e '^SSH_ASKPASS$' -e '^TERM$' -e '^TERM_PROGRAM$' -e '^TERM_PROGRAM_VERSION$' -e '^TZ$' -e '^UID$' -e '^USER$' -e '^_backup_glob$'           -e '^CHILD_MAX$' -e '^BASH_COMPAT$' -e '^FUNCNEST$' -e '^COMP_TYPE$' -e '^COMP_KEY$' -e '^READLINE_LINE_BUFFER$' -e '^READLINE_POINT$' -e '^PROMPT_DIRTRIM$' -e '^BASH_EXECUTION_STRING$' -e '^COPROC_PID$' -e '^COPROC$' -e '^GLOBIGNORE$' -e '^HISTIGNORE$' -e '^SRANDOM$' -e '^READLINE_MARK$' -e '^EPOCHSECONDS$' -e '^EPOCHREALTIME$' -e '^BASH_ARGV0$' -e '^COMPREPLY$' -e '^COMP_CWORD$' -e '^COMP_LINE$' -e '^COMP_POINT$' -e '^COMP_WORDS$' -e '^EMACS$' -e '^FCEDIT$' -e '^FIGNORE$' -e '^HOSTFILE$' -e '^IGNOREEOF$' -e '^INPUTRC$' -e '^INSIDE_EMACS$' -e '^MAPFILE$' -e '^READLINE_LINE$' -e '^REPLY$' -e '^TIMEFORMAT$' -e '^TMOUT$' -e '^TMPDIR$' -e '^histchars$') || true
    
    local regvar=""
    local i
    for i in ${regresult} ; do 
        regvar+="$i"$'\n'
    done


    local newVars=""
    _safe_vars(){ 
        # remove all defined variable in bash in the actual session, with this it means if a variable is edited outside of bash and saved in reg then it will not be updated, so it is secure to use the new environment without worrying about overwriting a critical variable created by bash or other tool in cygwin in the future. so only the PATH and the newly added variables to reg which are not already defined inside the actual bash session will be added to the actual bash session.
    
        # print all defined variables in bash
        local bashvar=""
        # met1:
        # for i in $(set -o posix; set | grep '=') ; do 
            # bashvar+=$(echo "$i" | cut -d'=' -f1)$'\n'
        # done
        
        # met2
        # The bash builtin compgen was meant to be used in completion scripts. To this end, compgen -v lists all defined variables. The downside: it lists only the variable names, not the values.
        # and compgen -v prints more things than set 
        bashvar=$(compgen -v)

                
        # compare reg variables to bash variables and print only variables that exist in reg and do not exist in bash, this of course means that if a variable is already defined in bash and it is updates in reg,then this variable will not be updated using this script, this is not good of course but it is safer, because i may override a critical bash variable otherwise
        # so with this method i will get all the new added variables but not the old variables which were recently updated
            # show lines that exist in string2 and do not exist in string1
            # grep's -x (--line-regexp) can be used to ensure the entire line is matched. So if A1 contains x and A2 contains xx, a match will not be found. 
            # You probably also need to use the option -F or --fixed-strings. Otherwise grep will be interpreting A1 as regular expressions. So if A1 contains the line .*, it will match everything. So the entire command would be: grep -vxF -f A1 A2 
            # i use grep -i because path is defined as Path in reg but defined as PATH in bash, so they will be considered different without -i
        newVars=$(grep -i -vxF -f <(echo "$bashvar") <(echo "$regvar"))
    }

    if [[ "${RefrEnv_StrictRefresh:-}" = "yes" ]] ; then
        _safe_vars
    else
        newVars="$regvar"
    fi
    
    # extract the values of the final key
    local ALLnewVarsKeysAndValues=""
    # don t quote $newVars i already override IFS so no worry about space, if i quote it the multiline is considered one word
    local i
    for i in $newVars ; do 
        if [[ "$i" != "" ]] ; then
            # if the variable have ' bad things may happen so lets escape it with '\''
            local newVarKeysAndValue0
            newVarKeysAndValue0=$(regtool get "${regPath}/${i}" | sed "s/'/'\\\\''/g" )
            local newVarKeysAndValue="export ${i}='${newVarKeysAndValue0}'"
            local ALLnewVarsKeysAndValues+="${newVarKeysAndValue}"$'\n'
        fi
    done

    # print vars if they do not contain variable which need to be expanded of the form %...% , because some apps may save the vars in reg unexpanded
    printf '%s' "$ALLnewVarsKeysAndValues" | grep -v -- '%.*%' >> "${RefrEnv_Temp_Dir}/newEnv.sh" || true
    
    # prepare vars list which need to be expanded
    # echo "" is needed to create some content in the text file otherwise the vbscript will gave error when the file is empty, (a new line here is considered a content)
    echo "" > "${RefrEnv_Temp_Dir}/vars_need_to_expand.txt"
    printf '%s' "$ALLnewVarsKeysAndValues" | grep -- '%.*%' >> "${RefrEnv_Temp_Dir}/vars_need_to_expand.txt" || true

    ExpandEnvironmentStrings "$(cygpath -w "${RefrEnv_Temp_Dir}/vars_need_to_expand.txt")" "$(cygpath -w "${RefrEnv_Temp_Dir}/vars_expanded.txt")"
    
    cat "${RefrEnv_Temp_Dir}/vars_expanded.txt" >> "${RefrEnv_Temp_Dir}/newEnv.sh"

    if [[ ${RefrEnv_debug:-} = yes ]] ; then
        echo "${regPath}" >> "${RefrEnv_Temp_Dir}/vars_need_to_expand_all.txt"
        echo "${regPath}" >> "${RefrEnv_Temp_Dir}/vars_expanded_all.txt"
        cat "${RefrEnv_Temp_Dir}/vars_need_to_expand.txt" >> "${RefrEnv_Temp_Dir}/vars_need_to_expand_all.txt"
        cat "${RefrEnv_Temp_Dir}/vars_expanded.txt" >> "${RefrEnv_Temp_Dir}/vars_expanded_all.txt"
        echo _______________________________ >> "${RefrEnv_Temp_Dir}/vars_need_to_expand_all.txt"
        echo _______________________________ >> "${RefrEnv_Temp_Dir}/vars_expanded_all.txt"
    fi
    
    rm "${RefrEnv_Temp_Dir}/vars_need_to_expand.txt" "${RefrEnv_Temp_Dir}/vars_expanded.txt"
    IFS="$IFSorg"
}


getNewPATHS(){ 
    local HKLM HKCU HKCUV
    HKLM=$(regtool get '/HKLM/System/CurrentControlSet/Control/Session Manager/Environment/path')
    HKCU=$(regtool get '/HKCU/Environment/path')
    # volatile path is not always defined so let s hide the stderror 
    HKCUV=$(regtool get '/HKCU/Volatile Environment/path' 2>/dev/null) || true

    local allPATHs="${HKLM};${HKCU};${HKCUV}"
    
    # after installing chocolatey it adds itself to the path like that: (D:\ProgramData\chocolatey\bin;) , the last ; should not have been added by chocolatey, this is an error by chocolatey , and it cause allPATHs to have double ;; , and this will make cygpath print (cygpath: can't convert empty path) . to solve it lets replace the double ;; with one ; this is safe. this solve https://github.com/badrelmers/RefrEnv/issues/1
    printf '%s' "$allPATHs" | sed 's/;;/;/g' > "${RefrEnv_Temp_Dir}/path_need_to_expand.txt"
    ExpandEnvironmentStrings "$(cygpath -w "${RefrEnv_Temp_Dir}/path_need_to_expand.txt")" "$(cygpath -w "${RefrEnv_Temp_Dir}/path_expanded.txt")"
    local AllExpandedPaths
    AllExpandedPaths=$(cat "${RefrEnv_Temp_Dir}/path_expanded.txt")
     
    
    local IFSorg=$IFS
    IFS=':'
    local i convertedPATHs DefaultPath
    
    if [[ ${RefrEnv_ResetPath:-} != yes ]] ; then
        # append the new paths to the old path; its better than overwriting the old path; otherwise i will delete any newly added path by the script who called this script
        for i in ${PATH} ; do 
            convertedPATHs+="$i"$'\n'
        done
    fi
    
    if [[ ${RefrEnv_ResetPath:-} == yes ]] ; then
        # reset the path
        # lets open a new bash session then capture the new path then add that path to our path, otherwise the bash default path will also be reseted so no command will work after that
        # check if we are in a login shell
        if shopt -q login_shell ; then
            # we are in a login shell
            # env -i clears HOME, so even if you run bash -l on the inside, it won't read your .bash_profile etc .so to solve it we use HOME="$HOME" https://unix.stackexchange.com/questions/48994/how-to-run-a-program-in-a-clean-environment-in-bash/451389#451389
            # env -i adds a dot (.) to the path!, this is bad so lets remove that dot with sed
            DefaultPath=$(env -i HOME="$HOME" /bin/bash -lc 'echo $PATH' | sed -e 's/:\.:/:/' -e 's/:\.$//')
        else
            DefaultPath=$(env -i HOME="$HOME" /bin/bash -c 'echo $PATH' | sed -e 's/:\.:/:/' -e 's/:\.$//')
        fi
        
        for i in ${DefaultPath} ; do 
            convertedPATHs+="$i"$'\n'
        done
    fi
    
    IFS=';'
    local i convertedPATHs
    for i in ${AllExpandedPaths} ; do 
        # convert the windows path to the equivalent cygwin path format: cygdrive...
        convertedPATHs+=$(cygpath "$i")$'\n'
    done
    
    # remove the last slash / so i catch duplicates which differ in the last slash only like: abc:abc/
    convertedPATHs=$(printf '%s' "$convertedPATHs" | sed 's/\/$//g')

    # remove duplicates without sorting
    # case insensitive
    local uniqpath
    uniqpath=$(printf '%s' "$convertedPATHs" | nl | sort --ignore-case -u -k2 | sort -n | cut -f2-)
    
    # convert it to cygwin PATH format ...:...:...etc
    local finalpath
    finalpath=$(printf '%s' "$uniqpath" | tr '\n' ':')
    # if the variable have single quote ' , bad things may happen so lets escape it with '\''
    finalpath=$(printf '%s' "$finalpath" | sed "s/'/'\\\\''/g")

    finalpath="export PATH='${finalpath}'"
    printf '%s' "$finalpath" >> "${RefrEnv_Temp_Dir}/newEnv.sh"

    
    IFS="$IFSorg"
}


ExpandEnvironmentStrings(){ 
    printf '%s' '
strFilename=WScript.Arguments.Item(0)
outFilename=WScript.Arguments.Item(1)

Set fso=CreateObject("Scripting.FileSystemObject")
REM Read file
set objFile=fso.OpenTextFile(strFilename,1)
oldContent=objFile.ReadAll

REM expand variables
set WshShell = WScript.CreateObject("WScript.Shell")
newContent = WshShell.ExpandEnvironmentStrings(oldContent)

REM Write file:  ForAppending = 8 ForReading = 1 ForWriting = 2 , True=create file if not exist
set objFile=fso.OpenTextFile(outFilename,2,True)
objFile.Write newContent
objFile.Close
    ' > "${RefrEnv_Temp_Dir}/ExpandEnvironmentStrings.vbs"

    cscript //nologo "$(cygpath -w "${RefrEnv_Temp_Dir}/ExpandEnvironmentStrings.vbs")" "$1" "$2"
}

refrenv_main

# end subshell
)


#########################################################################
#########################################################################
#########################################################################

if [[ ${RefrEnv_help:-} != yes ]] ; then
    # finally set the new variables
    source "${RefrEnv_Temp_Dir}/newEnv.sh"


    # cleanup
    if [[ ${RefrEnv_debug:-} = yes ]] ; then
        # explorer exit code is 1 always!!!
        explorer "$(cygpath -w "${RefrEnv_Temp_Dir}")" || true
    else
        rm -rf "${RefrEnv_Temp_Dir}"
    fi
fi

unset RefrEnv_Temp_Dir

