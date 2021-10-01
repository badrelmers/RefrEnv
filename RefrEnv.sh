
# usage: source refrenv.sh

getNewlyAddedVars(){
    # get the newly added variables from registry which are not defined in right now in bash
    regPath="$1"

    echo "look for new vars in $regPath"

    IFSorg=$IFS
    IFS=$'\n'
    
    # print all reg variables and remove critical ones
    # --list es importante sino se imprime tb los subfolders dentro del path, volatile por ejemplo tiene un folder/subkey llamada 1 y se imprime tb si no uso --list
    local regvar=""
    for i in $(regtool list --list "${regPath}" | grep -i -v -e '^ALLUSERSPROFILE$' -e '^APPDATA$' -e '^CommonProgramFiles$' -e '^CommonProgramFiles(x86)$' -e '^CommonProgramW6432$' -e '^COMPUTERNAME$' -e '^ComSpec$' -e '^HOMEDRIVE$' -e '^HOMEPATH$' -e '^LOCALAPPDATA$' -e '^LOGONSERVER$' -e '^NUMBER_OF_PROCESSORS$' -e '^OS$' -e '^PATHEXT$' -e '^PROCESSOR_ARCHITECTURE$' -e '^PROCESSOR_ARCHITEW6432$' -e '^PROCESSOR_IDENTIFIER$' -e '^PROCESSOR_LEVEL$' -e '^PROCESSOR_REVISION$' -e '^ProgramData$' -e '^ProgramFiles$' -e '^ProgramFiles(x86)$' -e '^ProgramW6432$' -e '^PUBLIC$' -e '^SystemDrive$' -e '^SystemRoot$' -e '^TEMP$' -e '^TMP$' -e '^USERDOMAIN$' -e '^USERDOMAIN_ROAMINGPROFILE$' -e '^USERNAME$' -e '^USERPROFILE$' -e '^windir$' -e '^SESSIONNAME$'   -e '^LINES$' -e '^COLUMNS$' -e '^OLDPWD$') ; do 
        local regvar+="$i"$'\n'
    done
  
        

    # print all defined variables in bash
    local bashvar=""
    # met1:
    # for i in $(set -o posix; set | grep '=') ; do 
        # bashvar+=$(echo "$i" | cut -d'=' -f1)$'\n'
    # done
    
    # met2
    # The bash builtin compgen was meant to be used in completion scripts. To this end, compgen -v lists all defined variables. The downside: it lists only the variable names, not the values.
    # es exactamente lo ke kiero ademas compgen -v   imprime mas cosas ke set 
    local bashvar=$(compgen -v)

    
    
    # compare reg variables to bash variables and print only variables that exist in reg and do not exist in bash, this of course means that if a variable is already defined in bash and it is updates in reg,then this variable will not be updated using this script, this is not good of course but it is safer, because i may override a critical bash variable otherwide
    # so with this method i will get all the new added vairables but not the old variables which were recently updated
        # show lines that exist in string2 and do not exist in string1
        # grep's -x (--line-regexp) can be used to ensure the entire line is matched. So if A1 contains x and A2 contains xx, a match will not be found. 
        # You probably also need to use the option -F or --fixed-strings. Otherwise grep will be interpreting A1 as regular expressions. So if A1 contains the line .*, it will match everything. So the entire command would be: grep -vxF -f A1 A2 
        # he usado grep -i sino se considera Path a new var aunque ya esta difinida en bash, pk esta in uppercase PATH not Path as in reg
    local newVars=$(grep -i -vxF -f <(echo "$bashvar") <(echo "$regvar"))


    
    
    # extract the values of the final key
    local ALLnewVarsKeysAndValues=""
    # dont quote $newVars i already overided IFS so no worry about space, if i quote it the multiline is considered one word
    for i in $newVars ; do 
        if [[ "$i" != "" ]] ; then
            # si la variable tiene ' puede pasar cosas malas asi lets escape it with '\''
            local newVarKeysAndValue0=$(regtool get "${regPath}/${i}" | sed "s/'/'\\\\''/g" )
            local newVarKeysAndValue="export ${i}='${newVarKeysAndValue0}'"
            local ALLnewVarsKeysAndValues+="${newVarKeysAndValue}"$'\n'
        fi
    done

    printf '%s' "$ALLnewVarsKeysAndValues" >> ${TEMP}/newEnv.sh
    
    IFS="$IFSorg"
}



getNewPATHS(){
    local HKLM=$(regtool get '/HKLM/System/CurrentControlSet/Control/Session Manager/Environment/path')
    local HKCU=$(regtool get '/HKCU/Environment/path')
    local HKCUV=$(regtool get '/HKCU/Volatile Environment/path')

    local allPATHs="${HKLM};${HKCU};${HKCUV}"

    # al llamar 'cmd /c echo...' abajo y si la variable tiene " ,bash anadira un slash antes " y hara ke la comparacion mas abajo no detecte ke hay un doble pk ahora sera \" en vez de " , asi ke vamos a borrar todas la letras ke no pueden existir in a dir path
    # REM porke a veces por error puede ke el path tenga charachteres malos como :
    # REM invalid characters (illegal characters) in Windows using NTFS
    # REM \ / : * ? "  < > |  and ^ in FAT 
    # REM ninguno de estos me da problemas con bash
    # REM pero para estar seguro y puesto ke estos charachteres no pueden existir in folders paths then let s just remove them except / \ and :
    local allPATHsClean=$(printf '%s' "$allPATHs" | tr -d '*?"<>|')

    # let s expand the path variables 
    # expandir con cmd es peligroso , si la variable tiene % me dara problemas, y no puedo borrar o escape % pk batch usa % para la variables y ahora kiero expandir la variables, asi ke cmd no me sirve, asi ke vamos a hacerlo con vbs
    # local allPATHsClean=$(printf '%s' "$allPATHsClean" | sed 's/%/%%/g')
    # local AllExpandedPaths=$(cmd /c "echo ${allPATHsClean}")
    # cmd /c echo imprime \r (CR) asi ke lo borrammos
    # local AllExpandedPaths=$(printf '%s' "$AllExpandedPaths" | tr -d '\r')

    printf '%s' "$allPATHsClean" > ${TEMP}/sssource.txt
    
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
objFile.Close' > ${TEMP}/rrrr.vbs

    cscript //nologo $(cygpath -w ${TEMP}/rrrr.vbs) $(cygpath -w ${TEMP}/sssource.txt)  $(cygpath -w ${TEMP}/outtt.txt) 

    
    AllExpandedPaths=$(cat ${TEMP}/outtt.txt)

    rm ${TEMP}/sssource.txt ${TEMP}/outtt.txt ${TEMP}/rrrr.vbs
     
    
    # I must append the new paths to the old path; its better than overrwiting the old path; otherwise i will delete any newly added path by the script who called this script
    # first lest convert the windows path to the equivalent cygwin path format: cygdrive...
    
    # clean PATH because if it contain " then bash will print it as \" y de todas formas " no debe existir in paths
    local PATHclean=$(printf '%s' "$PATH" | tr -d '*?"<>|')
    IFSorg=$IFS
    IFS=':'
    # local mypath=( $PATHclean )
    # for i in ${mypath[@]} ; do 
    for i in ${PATHclean} ; do 
        local convertedPATHs+="$i"$'\n'
    done
    

    IFS=';'
    # local AllExpandedPaths2=( $AllExpandedPaths )
    # for i in ${AllExpandedPaths2[@]} ; do 
    for i in ${AllExpandedPaths} ; do 
        local convertedPATHs+=$(cygpath "$i")$'\n'
    done

    
   
    
    # remove the last slash / so i catch duplicates which differ in the last slash only .../:.../
    local convertedPATHs=$(printf '%s' "$convertedPATHs" | sed 's/\/$//g')


    
    # remove duplicates without sorting
    # case sensitive
    # local uniqpath=$(printf '%s' "$convertedPATHs" | nl | sort -u -k2 | sort -n | cut -f2-)
    # case insensitive
    local uniqpath=$(printf '%s' "$convertedPATHs" | nl | sort --ignore-case -u -k2 | sort -n | cut -f2-)


    
    
    # convert it to cygwin PATH format ...:...:...ect
    local finalpath=$(printf '%s' "$uniqpath" | tr '\n' ':')
    # si la variable tiene ' puede pasar cosas malas asi lets escape it with '\''
    local finalpath=$(printf '%s' "$finalpath" | sed "s/'/'\\\\''/g")

    local finalpath="export PATH='${finalpath}'"

    printf '%s' "$finalpath" >> ${TEMP}/newEnv.sh

    
    IFS="$IFSorg"
}


main(){
    rm ${TEMP}/newEnv.sh
    getNewlyAddedVars '/HKLM/System/CurrentControlSet/Control/Session Manager/Environment'
    getNewlyAddedVars '/HKCU/Environment'
    getNewlyAddedVars '/HKCU/Volatile Environment'


    getNewPATHS
    # finally set the new variables
    source ${TEMP}/newEnv.sh

    # cat  ${TEMP}/newEnv.sh
    # env | sort

    # del ${TEMP}/newEnv.sh
}

main
# read -p endddddd



