#!/bin/bash

# author: Badr Elmers 2021
# description: refrenv = refresh environment. for bash
# https://github.com/badrelmers/RefrEnv
# https://stackoverflow.com/questions/171588/is-there-a-command-to-refresh-environment-variables-from-the-command-prompt-in-w


# ### USAGE ################################################################
RefrEnv_help(){
printf '
NAME
    RefrEnv - Refresh the Environment

SYNOPSIS
    source refrenv.sh [OPTION]...
    
DESCRIPTION
    By default with no arguments, this script will do a full 
    refresh (refresh all non critical variables*, and refresh the PATH).
    
    --strict       Strict mode (secure refresh) . refresh only a variable
                   if it is not already defined in the actual bash session, 
                   and refresh the PATH.
                                     
    --debug        Debug what this script do. The folder containing the 
                   files used to set the variables will be open, then see 
                   _NewEnv.sh this is the file which run inside your script
                   to setup the new variables, you can also revise the 
                   intermediate .txt files.
                              
    --help         Print this help.

    you can also put this script in windows\systems32 or another place in your $PATH then call it from an interactive console by writing source refrenv.sh

    *critical variables: are variables which belong to bash or windows and should not be refreshed normally like:
    - windows vars:
    ALLUSERSPROFILE APPDATA CommonProgramFiles CommonProgramFiles(x86) CommonProgramW6432 COMPUTERNAME ComSpec HOMEDRIVE HOMEPATH LOCALAPPDATA LOGONSERVER NUMBER_OF_PROCESSORS OS PATHEXT PROCESSOR_ARCHITECTURE PROCESSOR_ARCHITEW6432 PROCESSOR_IDENTIFIER PROCESSOR_LEVEL PROCESSOR_REVISION ProgramData ProgramFiles ProgramFiles(x86) ProgramW6432 PUBLIC SystemDrive SystemRoot TEMP TMP USERDOMAIN USERDOMAIN_ROAMINGPROFILE USERNAME USERPROFILE windir SESSIONNAME
    - bash vars:
    BASH BASHOPTS BASHPID BASH_ALIASES BASH_ARGC BASH_ARGV BASH_CMDS BASH_COMMAND BASH_COMPLETION_VERSINFO BASH_LINENO BASH_REMATCH BASH_SOURCE BASH_SUBSHELL BASH_VERSINFO BASH_VERSION COLUMNS COMP_WORDBREAKS CYGWIN CYG_SYS_BASHRC DIRSTACK EUID EXECIGNORE FUNCNAME GROUPS HISTCMD HISTCONTROL HISTFILE HISTFILESIZE HISTSIZE HISTTIMEFORMAT HOME HOSTNAME HOSTTYPE IFS INFOPATH LANG LC_ALL LC_COLLATE LC_CTYPE LC_MESSAGES LC_MONETARY LC_NUMERIC LC_TIME LINENO LINES MACHTYPE MAILCHECK OLDPWD OPTERR OPTIND ORIGINAL_PATH OSTYPE PATH PIPESTATUS POSIXLY_CORRECT PPID PRINTER PROFILEREAD PROMPT_COMMAND PS1 PS2 PS3 PS4 PWD RANDOM SECONDS SHELL SHELLOPTS SHLVL SSH_ASKPASS TERM TERM_PROGRAM TERM_PROGRAM_VERSION TZ UID USER _backup_glob
    
    
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
    # all 32 charachters: & % ' ( ) ~ + @ # $ { } [ ] ; , ` ! ^ | > < \ / " : ? * = . - _ & echo baaaad
    # and this:
    # (^.*)(Form Product=")([^"]*") FormType="[^"]*" FormID="([0-9][0-9]*)".*$
    # and use set to print those variables and see if they are saved without change
    
    
# invalid characters (illegal characters in file names) in Windows using NTFS
# \ / : * ? "  < > |  and ^ in FAT 



###############################################################################################
###############################################################################################
###############################################################################################

main(){
    echo 'RefrEnv - Refresh the Environment'
    local i
    local runme=yes
    
    if [[ "$#" -gt 0 ]] ; then
        for i in "$@" ; do
            case $i in
                --strict)
                    echo 'Strict refresh...'
                    local StrictRefresh=yes
                ;;
                --debug)
                    echo 'Debug enabled'
                    local debugme=yes
                ;;
                --help)
                    RefrEnv_help
                    local runme=no
                ;;
                *)
                    # unknown option
                    # i will not print anything because if the parent script have parametal arguments they will be passed to this script and trigguer this section
                    # echo unknown option. running with defaults
                ;;
            esac
        done
    fi
    
    [[ "$runme" = "yes" ]] && run_RefrEnv
    
}

####################################################################

run_RefrEnv(){
    
    local Temp_Dir=${TEMP}/RefrEnvBash
    # rm ${Temp_Dir}/newEnv.sh
    rm -rf ${Temp_Dir}
    mkdir -p ${Temp_Dir}
    

    getNewlyAddedVars '/HKLM/System/CurrentControlSet/Control/Session Manager/Environment'
    getNewlyAddedVars '/HKCU/Environment'
    getNewlyAddedVars '/HKCU/Volatile Environment'
    getNewPATHS
    # finally set the new variables
    source ${Temp_Dir}/newEnv.sh

    
    # cleanup
    if [[ ${debugme} = yes ]] ; then
        explorer "$(cygpath -w ${Temp_Dir})"
    else
        rm -rf ${Temp_Dir}
    fi
    
}

getNewlyAddedVars(){
    # get the newly added variables from registry which are not defined right now in bash
    local regPath="$1"

    local IFSorg=$IFS
    IFS=$'\n'
    
    # print all reg variables and remove critical ones, i created the list using: set declare compgen printenv env  
    # --list is important otherwise the reg subdirectories are printed , volatile environment for example have a folder/subkey called 1 and it is printed if i do not use --list
    local regvar=""
    local i
    for i in $(regtool list --list "${regPath}" | grep -i -v -e '^ALLUSERSPROFILE$' -e '^APPDATA$' -e '^CommonProgramFiles$' -e '^CommonProgramFiles(x86)$' -e '^CommonProgramW6432$' -e '^COMPUTERNAME$' -e '^ComSpec$' -e '^HOMEDRIVE$' -e '^HOMEPATH$' -e '^LOCALAPPDATA$' -e '^LOGONSERVER$' -e '^NUMBER_OF_PROCESSORS$' -e '^OS$' -e '^PATHEXT$' -e '^PROCESSOR_ARCHITECTURE$' -e '^PROCESSOR_ARCHITEW6432$' -e '^PROCESSOR_IDENTIFIER$' -e '^PROCESSOR_LEVEL$' -e '^PROCESSOR_REVISION$' -e '^ProgramData$' -e '^ProgramFiles$' -e '^ProgramFiles(x86)$' -e '^ProgramW6432$' -e '^PUBLIC$' -e '^SystemDrive$' -e '^SystemRoot$' -e '^TEMP$' -e '^TMP$' -e '^USERDOMAIN$' -e '^USERDOMAIN_ROAMINGPROFILE$' -e '^USERNAME$' -e '^USERPROFILE$' -e '^windir$' -e '^SESSIONNAME$'                     -e '^BASH$' -e '^BASHOPTS$' -e '^BASHPID$' -e '^BASH_ALIASES$' -e '^BASH_ARGC$' -e '^BASH_ARGV$' -e '^BASH_CMDS$' -e '^BASH_COMMAND$' -e '^BASH_COMPLETION_VERSINFO$' -e '^BASH_LINENO$' -e '^BASH_REMATCH$' -e '^BASH_SOURCE$' -e '^BASH_SUBSHELL$' -e '^BASH_VERSINFO$' -e '^BASH_VERSION$' -e '^COLUMNS$' -e '^COMP_WORDBREAKS$' -e '^CYGWIN$' -e '^CYG_SYS_BASHRC$' -e '^DIRSTACK$' -e '^EUID$' -e '^EXECIGNORE$' -e '^FUNCNAME$' -e '^GROUPS$' -e '^HISTCMD$' -e '^HISTCONTROL$' -e '^HISTFILE$' -e '^HISTFILESIZE$' -e '^HISTSIZE$' -e '^HISTTIMEFORMAT$' -e '^HOME$' -e '^HOSTNAME$' -e '^HOSTTYPE$' -e '^IFS$' -e '^INFOPATH$' -e '^LANG$' -e '^LC_ALL$' -e '^LC_COLLATE$' -e '^LC_CTYPE$' -e '^LC_MESSAGES$' -e '^LC_MONETARY$' -e '^LC_NUMERIC$' -e '^LC_TIME$' -e '^LINENO$' -e '^LINES$' -e '^MACHTYPE$' -e '^MAILCHECK$' -e '^OLDPWD$' -e '^OPTERR$' -e '^OPTIND$' -e '^ORIGINAL_PATH$' -e '^OSTYPE$' -e '^PATH$' -e '^PIPESTATUS$' -e '^POSIXLY_CORRECT$' -e '^PPID$' -e '^PRINTER$' -e '^PROFILEREAD$' -e '^PROMPT_COMMAND$' -e '^PS1$' -e '^PS2$' -e '^PS3$' -e '^PS4$' -e '^PWD$' -e '^RANDOM$' -e '^SECONDS$' -e '^SHELL$' -e '^SHELLOPTS$' -e '^SHLVL$' -e '^SSH_ASKPASS$' -e '^TERM$' -e '^TERM_PROGRAM$' -e '^TERM_PROGRAM_VERSION$' -e '^TZ$' -e '^UID$' -e '^USER$' -e '^_backup_glob$') ; do 
        local regvar+="$i"$'\n'
    done
  
    local newVars=""
    _safe_vars(){
        # remove all defined variable in bash in the actual session, with this it means if a variable is edited outside of bash and saved in reg then it will not be updated, so it is secure to use the new environment without worriying about overriting a critical variable created by bash or other tool in cygwin in the future. so only the PATH and the newly added variables to reg which are not alrady defined inside the actual bash session will be added to the actual bash session.
    
        # print all defined variables in bash
        local bashvar=""
        # met1:
        # for i in $(set -o posix; set | grep '=') ; do 
            # bashvar+=$(echo "$i" | cut -d'=' -f1)$'\n'
        # done
        
        # met2
        # The bash builtin compgen was meant to be used in completion scripts. To this end, compgen -v lists all defined variables. The downside: it lists only the variable names, not the values.
        # and compgen -v prints more things than set 
        local bashvar=$(compgen -v)

        
        
        # compare reg variables to bash variables and print only variables that exist in reg and do not exist in bash, this of course means that if a variable is already defined in bash and it is updates in reg,then this variable will not be updated using this script, this is not good of course but it is safer, because i may override a critical bash variable otherwide
        # so with this method i will get all the new added vairables but not the old variables which were recently updated
            # show lines that exist in string2 and do not exist in string1
            # grep's -x (--line-regexp) can be used to ensure the entire line is matched. So if A1 contains x and A2 contains xx, a match will not be found. 
            # You probably also need to use the option -F or --fixed-strings. Otherwise grep will be interpreting A1 as regular expressions. So if A1 contains the line .*, it will match everything. So the entire command would be: grep -vxF -f A1 A2 
            # i use grep -i because path is defined as Path in reg but defined as PATH in bash, so they will be considered diferent without -i
        newVars=$(grep -i -vxF -f <(echo "$bashvar") <(echo "$regvar"))
    }

    if [[ "${StrictRefresh}" = "yes" ]] ; then
        _safe_vars
    else
        local newVars="$regvar"
    fi
    
    # extract the values of the final key
    local ALLnewVarsKeysAndValues=""
    # dont quote $newVars i already overided IFS so no worry about space, if i quote it the multiline is considered one word
    local i
    for i in $newVars ; do 
        if [[ "$i" != "" ]] ; then
            # if the variable have ' bad things may happen so lets escape it with '\''
            local newVarKeysAndValue0=$(regtool get "${regPath}/${i}" | sed "s/'/'\\\\''/g" )
            local newVarKeysAndValue="export ${i}='${newVarKeysAndValue0}'"
            local ALLnewVarsKeysAndValues+="${newVarKeysAndValue}"$'\n'
        fi
    done

    # print vars if they do not contain variable which need to be expanded of the form %...% , because some apps may save the vars in reg unexpanded
    printf '%s' "$ALLnewVarsKeysAndValues" | grep -v -- '%.*%' >> ${Temp_Dir}/newEnv.sh
    
    # prepare vars list which need to be expanded
    # echo "" is needed to create some content in the text file otherwise the vbscript will gave error when the file is empty, (a new line here is considered a content)
    echo "" > ${Temp_Dir}/vars_need_to_expand.txt
    printf '%s' "$ALLnewVarsKeysAndValues" | grep -- '%.*%' >> ${Temp_Dir}/vars_need_to_expand.txt

    ExpandEnvironmentStrings "$(cygpath -w ${Temp_Dir}/vars_need_to_expand.txt)" "$(cygpath -w ${Temp_Dir}/vars_expanded.txt)"
    
    cat ${Temp_Dir}/vars_expanded.txt >> ${Temp_Dir}/newEnv.sh

    if [[ ${debugme} = yes ]] ; then
        echo "${regPath}" >> ${Temp_Dir}/vars_need_to_expand_all.txt
        echo "${regPath}" >> ${Temp_Dir}/vars_expanded_all.txt
        cat ${Temp_Dir}/vars_need_to_expand.txt >> ${Temp_Dir}/vars_need_to_expand_all.txt
        cat ${Temp_Dir}/vars_expanded.txt >> ${Temp_Dir}/vars_expanded_all.txt
        echo _______________________________ >> ${Temp_Dir}/vars_need_to_expand_all.txt
        echo _______________________________ >> ${Temp_Dir}/vars_expanded_all.txt
    fi
    
    rm ${Temp_Dir}/vars_need_to_expand.txt ${Temp_Dir}/vars_expanded.txt
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
    ' > ${Temp_Dir}/ExpandEnvironmentStrings.vbs

    cscript //nologo "$(cygpath -w ${Temp_Dir}/ExpandEnvironmentStrings.vbs)" "$1" "$2"
}


getNewPATHS(){
    local HKLM=$(regtool get '/HKLM/System/CurrentControlSet/Control/Session Manager/Environment/path')
    local HKCU=$(regtool get '/HKCU/Environment/path')
    local HKCUV=$(regtool get '/HKCU/Volatile Environment/path')

    # TODO test if this is safe with ' and " "
    local allPATHs="${HKLM};${HKCU};${HKCUV}"

    # TODO: delete this , i replaced it with vbscript
        # al llamar 'cmd /c echo...' abajo y si la variable tiene " ,bash anadira un slash antes " y hara ke la comparacion mas abajo no detecte ke hay un doble pk ahora sera \" en vez de " , asi ke vamos a borrar todas la letras ke no pueden existir in a dir path
        # REM porke a veces por error puede ke el path tenga charachteres malos como :
        # REM invalid characters (illegal characters) in Windows using NTFS
        # REM \ / : * ? "  < > |  and ^ in FAT 
        # REM ninguno de estos me da problemas con bash
        # REM pero para estar seguro y puesto ke estos charachteres no pueden existir in folders paths then let s just remove them except / \ and :
        # local allPATHsClean=$(printf '%s' "$allPATHs" | tr -d '*?"<>|')

        # let s expand the path variables 
        # expandir con cmd es peligroso , si la variable tiene % me dara problemas, y no puedo borrar o escape % pk batch usa % para la variables y ahora kiero expandir la variables, asi ke cmd no me sirve, asi ke vamos a hacerlo con vbs
        # local allPATHsClean=$(printf '%s' "$allPATHsClean" | sed 's/%/%%/g')
        # local AllExpandedPaths=$(cmd /c "echo ${allPATHsClean}")
        # cmd /c echo imprime \r (CR) asi ke lo borrammos
        # local AllExpandedPaths=$(printf '%s' "$AllExpandedPaths" | tr -d '\r')

        
    printf '%s' "$allPATHs" > ${Temp_Dir}/path_need_to_expand.txt
    


    ExpandEnvironmentStrings "$(cygpath -w ${Temp_Dir}/path_need_to_expand.txt)" "$(cygpath -w ${Temp_Dir}/path_expanded.txt)"

    
    local AllExpandedPaths=$(cat ${Temp_Dir}/path_expanded.txt)

    # rm ${Temp_Dir}/path_need_to_expand.txt ${Temp_Dir}/path_expanded.txt ${Temp_Dir}/ExpandEnvironmentStrings.vbs
     
    
    # I must append the new paths to the old path; its better than overrwiting the old path; otherwise i will delete any newly added path by the script who called this script
    # first lest convert the windows path to the equivalent cygwin path format: cygdrive...
    
    # clean PATH because if it contain " then bash will print it as \" y de todas formas " no debe existir in paths
    # local PATHclean=$(printf '%s' "$PATH" | tr -d '*?"<>|')
    # local PATHclean=$(printf '%s' "$PATH")
    # local PATHclean="$PATH"
    local IFSorg=$IFS
    IFS=':'
    # local mypath=( $PATHclean )
    # for i in ${mypath[@]} ; do 
    # for i in ${PATHclean} ; do 
    local i
    for i in ${PATH} ; do 
        local convertedPATHs+="$i"$'\n'
    done
    

    IFS=';'
    # local AllExpandedPaths2=( $AllExpandedPaths )
    # for i in ${AllExpandedPaths2[@]} ; do 
    local i
    for i in ${AllExpandedPaths} ; do 
        local convertedPATHs+=$(cygpath "$i")$'\n'
    done

    
   
    
    # remove the last slash / so i catch duplicates which differ in the last slash only .../:.../
    local convertedPATHs=$(printf '%s' "$convertedPATHs" | sed 's/\/$//g')


    
    # remove duplicates without sorting
    # case insensitive
    local uniqpath=$(printf '%s' "$convertedPATHs" | nl | sort --ignore-case -u -k2 | sort -n | cut -f2-)


    
    
    # convert it to cygwin PATH format ...:...:...ect
    local finalpath=$(printf '%s' "$uniqpath" | tr '\n' ':')
    # si la variable tiene ' puede pasar cosas malas asi lets escape it with '\''
    local finalpath=$(printf '%s' "$finalpath" | sed "s/'/'\\\\''/g")

    local finalpath="export PATH='${finalpath}'"

    printf '%s' "$finalpath" >> ${Temp_Dir}/newEnv.sh

    
    IFS="$IFSorg"
}



main "$@"


