# RefrEnv - **Refr**esh the **Env**ironment
Reload environment variables inside `CMD`, `Bash`, `Powershell` or `Zsh` every time you want environment changes to propagate, so you do not need to restart them after setting a new variable with setx or after installing a new app which adds new variables.

This is a better alternative to the `Chocolatey` `refreshenv` for cmd (and works for `bash` and `zsh` too (`cygwin`, `Msys2` and `GitBash`)), which solves several problems in the chocolatey's refreshenv, like:
 - The Chocolatey **refreshenv** act **bad** if the variable have some
   cmd meta-characters, see this test:
   
   add this to the path in HKCU\Environment: `test & echo baaaaaaaaaad`,
   and run the chocolatey `refreshenv` you will see that it prints
   `baaaaaaaaaad` which is very bad, and the new path is not added to
   your path variable.
   
   `RefrEnv` solves this and you can test it with any meta-character, even something so bad like: 
   ```
   ; & % ' ( ) ~ + @ # $ { } [ ] , ` ! ^ | > < \ / " : ? * = . - _ & echo baaaad
   ```
 - `refreshenv` adds only **system** and **user**
   environment variables, but CMD adds **volatile** variables too
   (HKCU\Volatile Environment). `RefrEnv` will merge all the three and
   **remove any duplicates**.

 - `refreshenv` resets your PATH. `RefrEnv` appends the new path to the
   old path of the parent script which called `RefrEnv`. It is better
   than overwriting the old path, otherwise it will delete any newly
   added path by the parent script. (this can be changed by user choice
   to reset the path, see the description)

 - `RefrEnv` solve this problem described in a comment [here][1] by @Gene Mayevsky: 
     > refreshenv *modifies env variables TEMP and TMP replacing them with values stored in HKCU\Environment. In my case I run the script to update env variables modified by Jenkins job on a slave that's running under SYSTEM account, so TEMP and TMP get substituted by %USERPROFILE%\AppData\Local\Temp instead of C:\Windows\Temp. This breaks build because linker cannot open system profile's Temp folder.*

and more...


# Usage:
```batch
git clone https://github.com/badrelmers/RefrEnv
cd RefrEnv
```

## cmd
Works in all windows versions **xp+**

```batch
call refrenv.bat
```

## Powershell
Works in all Powershell versions **V2+**
```powershell
. .\refrenv.ps1
```

## bash:
```bash
source refrenv.sh
```

## Zsh:
```bash
source refrenvz.sh
```

______
# Details:
## Opciones for RefrEnv in CMD 
```
NAME
   RefrEnv - Refresh the Environment for CMD

SYNOPSIS
   call refrenv.bat

DESCRIPTION
   By default with no arguments, this script will do a full 
   refresh (refresh all non critical variables*, and refresh the PATH).

   you can use the following variables to change the default behaviour:

   RefrEnv_ResetPath=yes       Reset the actual PATH inside CMD, then refresh
                               it with a new PATH. This will delete any PATH 
                               added by the script who called RefrEnv. It is 
                               equivalent to running a new CMD session.

   RefrEnv_debug=yes           Debug what this script do. The folder containing
                               the files used to set the variables will be
                               open, then see _NewEnv.sh, this is the file
                               which run inside your script to setup the new
                               variables, you can also revise the intermediate
                               .txt files.
```


## Opciones for RefrEnv in Powershell 
```
NAME
    RefrEnv - Refresh the Environment for Powershell/Pwsh

SYNOPSIS
    . .\refrenv.ps1
    
DESCRIPTION
    By default with no arguments, this script will do a full 
    refresh (refresh all non critical variables*, and refresh the PATH).

    you can use the following variables to change the default behaviour:
                                
    RefrEnv_ResetPath=yes       Reset the actual PATH inside Powershell, then refresh
                                it with a new PATH. This will delete any PATH 
                                added by the script who called RefrEnv. It is 
                                equivalent to running a new Powershell session.
```


## Opciones for RefrEnv in Bash and Zsh 
```
SYNOPSIS
    source refrenv.sh
    source refrenvz.sh

DESCRIPTION
    By default with no arguments, RefrEnv will do a full 
    refresh (refresh all non critical variables*, and refresh the PATH).

    you can use the following variables to change the default behaviour:
    
    RefrEnv_StrictRefresh=yes   Strict mode (secure refresh). this prevent refreshing a
                                variable if it is already defined in the actual bash/zsh session. 
                                The PATH will be refreshed.
                                
    RefrEnv_ResetPath=yes       Reset the actual PATH inside bash/zsh, then refresh it with a new PATH.
                                this will delete any PATH added by the script who called RefrEnv. 
                                it is equivalent to running a new bash/zsh session.

    RefrEnv_debug=yes           Debug what RefrEnv do. The folder containing the 
                                files used to set the variables will be open, then see 
                                _NewEnv.sh this is the file which run inside your script
                                to setup the new variables, you can also revise the 
                                intermediate .txt files.
                              
    RefrEnv_help=yes            Print the help.

        
    RefrEnv support the so called bash Strict Mode like: "set -eEu -o pipefail ; shopt -s inherit_errexit"
    you can use the Strict Mode safely in your parent script without worry.

```
 ______
> [!NOTE]
> __*critical variables__: are the built-in variables which belong to cmd/bash/zsh or windows and should not be refreshed normally like:

<details>
    <summary>Expand for details</summary>
 
    - windows vars:
        ALLUSERSPROFILE APPDATA CommonProgramFiles CommonProgramFiles(x86)
        CommonProgramW6432 COMPUTERNAME ComSpec HOMEDRIVE HOMEPATH LOCALAPPDATA 
        LOGONSERVER NUMBER_OF_PROCESSORS OS PATHEXT PROCESSOR_ARCHITECTURE 
        PROCESSOR_ARCHITEW6432 PROCESSOR_IDENTIFIER PROCESSOR_LEVEL 
        PROCESSOR_REVISION ProgramData ProgramFiles ProgramFiles(x86) 
        ProgramW6432 PUBLIC SystemDrive SystemRoot TEMP TMP USERDOMAIN 
        USERDOMAIN_ROAMINGPROFILE USERNAME USERPROFILE windir SESSIONNAME
        
    - bash vars:
        BASH BASHOPTS BASHPID BASH_ALIASES BASH_ARGC BASH_ARGV BASH_CMDS 
        BASH_COMMAND BASH_COMPLETION_VERSINFO BASH_LINENO BASH_REMATCH 
        BASH_SOURCE BASH_SUBSHELL BASH_VERSINFO BASH_VERSION COLUMNS 
        COMP_WORDBREAKS CYGWIN CYG_SYS_BASHRC DIRSTACK EUID EXECIGNORE 
        FUNCNAME GROUPS HISTCMD HISTCONTROL HISTFILE HISTFILESIZE HISTSIZE 
        HISTTIMEFORMAT HOME HOSTNAME HOSTTYPE IFS INFOPATH LANG LC_ALL 
        LC_COLLATE LC_CTYPE LC_MESSAGES LC_MONETARY LC_NUMERIC LC_TIME LINENO 
        LINES MACHTYPE MAILCHECK OLDPWD OPTERR OPTIND ORIGINAL_PATH OSTYPE PATH 
        PIPESTATUS POSIXLY_CORRECT PPID PRINTER PROFILEREAD PROMPT_COMMAND PS0 
        PS1 PS2 PS3 PS4 PWD RANDOM SECONDS SHELL SHELLOPTS SHLVL SSH_ASKPASS 
        TERM TERM_PROGRAM TERM_PROGRAM_VERSION TZ UID USER _backup_glob 
        CHILD_MAX BASH_COMPAT FUNCNEST COMP_TYPE COMP_KEY READLINE_LINE_BUFFER 
        READLINE_POINT PROMPT_DIRTRIM BASH_EXECUTION_STRING COPROC_PID COPROC 
        GLOBIGNORE HISTIGNORE SRANDOM READLINE_MARK EPOCHSECONDS EPOCHREALTIME 
        BASH_ARGV0 COMPREPLY COMP_CWORD COMP_LINE COMP_POINT COMP_WORDS EMACS 
        FCEDIT FIGNORE HOSTFILE IGNOREEOF INPUTRC INSIDE_EMACS MAPFILE 
        READLINE_LINE REPLY TIMEFORMAT TMOUT TMPDIR histchars
</details>

<br>
<br>
RefrEnv was created to respond to this Stackoverflow thread: https://stackoverflow.com/questions/171588/is-there-a-command-to-refresh-environment-variables-from-the-command-prompt-in-w


  [1]: https://stackoverflow.com/questions/171588/is-there-a-command-to-refresh-environment-variables-from-the-command-prompt-in-w

