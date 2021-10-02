# RefrEnv - *Refr*esh the *Env*ironment
Reload environment variables inside cmd/bash every time you want environment changes to propagate, so you do not need to restart cmd/bash after setting a new variable with setx or after installing a new app which adds new variables.

This is a better alternative to the chocolatey refreshenv for cmd (and works for bash (cygwin) too), which solves a lot of problems like:
 - The Chocolatey **refreshenv** is so **bad** if the variable have some
   cmd meta-characters, see this test:
   
   add this to the path in HKCU\Environment: `test & echo baaaaaaaaaad`,
   and run the chocolatey `refreshenv` you will see that it prints
   `baaaaaaaaaad` which is very bad, and the new path is not added to
   your path variable.
   
   This script solve this and you can test it with any meta-character, even something so bad like: 
   ```
   ; & % ' ( ) ~ + @ # $ { } [ ] , ` ! ^ | > < \ / " : ? * = . - _ & echo baaaad
   ```
 - refreshenv adds only **system** and **user**
   environment variables, but CMD adds **volatile** variables too
   (HKCU\Volatile Environment). This script will merge all the three and
   **remove any duplicates**.

 - refreshenv reset your PATH. This script append the new path to the
   old path of the parent script which called this script. It is better
   than overwriting the old path, otherwise it will delete any newly
   added path by the parent script.

 - This script solve this problem described in a comment [here][1] by @Gene Mayevsky: refreshenv *modifies env variables TEMP and TMP replacing
   them with values stored in HKCU\Environment. In my case I run the
   script to update env variables modified by Jenkins job on a slave
   that's running under SYSTEM account, so TEMP and TMP get substituted
   by %USERPROFILE%\AppData\Local\Temp instead of C:\Windows\Temp. This
   breaks build because linker cannot open system profile's Temp folder.*

https://stackoverflow.com/questions/171588/is-there-a-command-to-refresh-environment-variables-from-the-command-prompt-in-w

## For cmd
This script uses vbscript so it works in all windows versions **xp+**

Call it from cmd with: 
```batch
call refrenv.bat
```

## For cygwin/bash:
Call it from bash with: 
```bash
source refrenv.sh
```
or 
```bash
source refrenv.sh --strict
```
For more info see: 
```bash
refrenv.sh --help
``` 

  [1]: https://stackoverflow.com/questions/171588/is-there-a-command-to-refresh-environment-variables-from-the-command-prompt-in-w
