# RefrEnv - *Refr*esh the *Env*ironment
Reload environment variables inside `CMD`, `Bash`, `Powershell` or `Zsh` every time you want environment changes to propagate, so you do not need to restart them after setting a new variable with setx or after installing a new app which adds new variables.

This is a better alternative to the chocolatey refreshenv for cmd (and works for `bash` and `zsh` too (`cygwin`, `Msys2` and `GitBash`)), which solves several problems in the chocolatey refreshenv, like:
 - The Chocolatey **refreshenv** act **bad** if the variable have some
   cmd meta-characters, see this test:
   
   add this to the path in HKCU\Environment: `test & echo baaaaaaaaaad`,
   and run the chocolatey `refreshenv` you will see that it prints
   `baaaaaaaaaad` which is very bad, and the new path is not added to
   your path variable.
   
   `RefrEnv` solve this and you can test it with any meta-character, even something so bad like: 
   ```
   ; & % ' ( ) ~ + @ # $ { } [ ] , ` ! ^ | > < \ / " : ? * = . - _ & echo baaaad
   ```
 - refreshenv adds only **system** and **user**
   environment variables, but CMD adds **volatile** variables too
   (HKCU\Volatile Environment). `RefrEnv` will merge all the three and
   **remove any duplicates**.

 - refreshenv reset your PATH. `RefrEnv` append the new path to the
   old path of the parent script which called `RefrEnv`. It is better
   than overwriting the old path, otherwise it will delete any newly
   added path by the parent script.

 - `RefrEnv` solve this problem described in a comment [here][1] by @Gene Mayevsky: 
     > refreshenv *modifies env variables TEMP and TMP replacing them with values stored in HKCU\Environment. In my case I run the script to update env variables modified by Jenkins job on a slave that's running under SYSTEM account, so TEMP and TMP get substituted by %USERPROFILE%\AppData\Local\Temp instead of C:\Windows\Temp. This breaks build because linker cannot open system profile's Temp folder.*

[more info][2]

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
#### Opciones for RefrEnv in bash and zsh 
```
SYNOPSIS
    source refrenv.sh
    source refrenvz.sh

DESCRIPTION
    By default with no arguments, RefrEnv will do a full 
    refresh (refresh all non critical variables*, and refresh the PATH).

    use can use the following variables to change some behaviours:
    
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

    *critical variables: are the built-in variables which belong to bash/zsh or windows and should 
    not be refreshed normally like:
    - windows vars: ALLUSERSPROFILE APPDATA CommonProgramFiles ...
    - bash/zsh vars: BASH BASHOPTS BASHPID BASH_ALIASES BASH_ARGC ...
    
    
    RefrEnv support the so called bash Strict Mode like: "set -eEu -o pipefail ; shopt -s inherit_errexit"
    you can use the Strict Mode safely in your parent script without worry.

```
 


  [1]: https://stackoverflow.com/questions/171588/is-there-a-command-to-refresh-environment-variables-from-the-command-prompt-in-w
  [2]: https://stackoverflow.com/questions/171588/is-there-a-command-to-refresh-environment-variables-from-the-command-prompt-in-w

