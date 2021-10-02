<!-- : Begin batch script

@echo off

REM ________________________________________________________________
REM usage: from another batch script use:
REM call refresh_env.bat

REM ________________________________________________________________
REM https://github.com/chocolatey/choco/blob/5fe1377b006e3146d2ad0d0ca5aede8354662408/src/chocolatey.resources/redirects/RefreshEnv.cmd
REM https://stackoverflow.com/questions/171588/is-there-a-command-to-refresh-environment-variables-from-the-command-prompt-in-w
::
:: RefreshEnv.cmd
::
:: Batch file to read environment variables from registry and
:: set session variables to these values.
::
:: With this batch file, there should be no need to reload command
:: environment every time you want environment changes to propagate


REM ________________________________________________________________
REM when i run a script from task scheduler using SYSTEM user the following variables are the differences between the scheduler env and a normal cmd script, so i corrected this script to not override those variables
REM APPDATA=D:\Users\LLED2\AppData\Roaming
REM APPDATA=D:\Windows\system32\config\systemprofile\AppData\Roaming

REM LOCALAPPDATA=D:\Users\LLED2\AppData\Local
REM LOCALAPPDATA=D:\Windows\system32\config\systemprofile\AppData\Local

REM TEMP=D:\Users\LLED2\AppData\Local\Temp
REM TEMP=D:\Windows\TEMP

REM TMP=D:\Users\LLED2\AppData\Local\Temp
REM TMP=D:\Windows\TEMP

REM USERDOMAIN=LLED2-PC
REM USERDOMAIN=WORKGROUP

REM USERNAME=LLED2
REM USERNAME=LLED2-PC$

REM USERPROFILE=D:\Users\LLED2
REM USERPROFILE=D:\Windows\system32\config\systemprofile

REM i know this thanks to this comment
REM The solution is good but it modifies env variables TEMP and TMP replacing them with values stored in HKCU\Environment. In my case I run the script to update env variables modified by Jenkins job on a slave that's running under SYSTEM account, so TEMP and TMP get substituted by %USERPROFILE%\AppData\Local\Temp instead of C:\Windows\Temp. This breaks build because linker cannot open system profile's Temp folder. – Gene Mayevsky Sep 26 '19 at 20:51


REM ________________________________________________________________

REM The confusing thing might be that there are a few places to start the cmd from. In my case I ran cmd from windows explorer and the environment variables did not change while when starting cmd from the "run" (windows key + r) the environment variables were changed.

REM In my case I just had to kill the windows explorer process from the task manager and then restart it again from the task manager.

REM Once I did this I had access to the new environment variable from a cmd that was spawned from windows explorer.

REM mi conclusion:
REM si anado una nueva variable con setx, la puedo ver en cmd solo si lo abro con admin, sin admin hay ke reiniciar explorer para verlo 
REM ________________________________________________________________
REM windows recreate the path using three places at less:
REM the User namespace
REM HKCU\Environment
REM the System namespace
REM HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment
REM the Session namespace
REM HKCU\Volatile Environment
REM but the original chocolatey script did not add the volatil path, so lets add it

REM there is this too which cmd seems to read when first running,but it contains only TEMP and TMP,so i will not use it
REM HKEY_USERS\.DEFAULT\Environment
REM ________________________________________________________________

::echo "RefreshEnv.cmd only works from cmd.exe, please install the Chocolatey Profile to take advantage of refreshenv from PowerShell"
echo "Refreshing environment variables from registry for cmd.exe. Please wait..."

goto main

:: Set one environment variable from registry key
:SetFromReg
    "%WinDir%\System32\Reg" QUERY "%~1" /v "%~2" > "%TEMP%\_envset.tmp" 2>NUL
    for /f "usebackq skip=2 tokens=2,*" %%A IN ("%TEMP%\_envset.tmp") do (
        echo/set "%~3=%%B"
    )
    goto :EOF

    
:SetFromRegPATHHH
    "%WinDir%\System32\Reg" QUERY "%~1" /v "%~2" > "%TEMP%\_envset.tmp" 2>NUL
    for /f "usebackq skip=2 tokens=2,*" %%A IN ("%TEMP%\_envset.tmp") do (
        echo %%B
    )
    goto :EOF
    
    
:: Get a list of environment variables from registry
:GetRegEnv
    "%WinDir%\System32\Reg" QUERY "%~1" > "%TEMP%\_envget.tmp"
    for /f "usebackq skip=2" %%A IN ("%TEMP%\_envget.tmp") do (
        if /I not "%%~A"=="Path" (
            call :SetFromReg "%~1" "%%~A" "%%~A"
        )
    )
goto :EOF

    
:addPathOLDDD
    :: Special handling for PATH - mix both User and System
    call :SetFromReg "HKLM\System\CurrentControlSet\Control\Session Manager\Environment" Path Path_HKLM >> "%TEMP%\_env.cmd"
    call :SetFromReg "HKCU\Environment" Path Path_HKCU >> "%TEMP%\_env.cmd"
    call :SetFromReg "HKCU\Volatile Environment" Path Path_HKCUV >> "%TEMP%\_env.cmd"

    :: Caution: do not insert space-chars before >> redirection sign
    echo/set "Path=%%Path_HKLM%%;%%Path_HKCU%%;%%Path_HKCUV%%" >> "%TEMP%\_env.cmd"
goto :EOF


:addPathWithoutDuplicates
    :: remove duplicates from path
    REM the maximum string length is 8191 characters. But string length doesnt mean that you can save 8191 characters in a variable because also the assignment belongs to the string. you can save 8189 characters because the remaining 2 characters are needed for "a="
    REM segun mis tests: 
    REM when i open cmd as user , windows does not remove any duplicates from the path, and adds system+user+volatil path
    REM when i open cmd as admin, windows do: system+user path (here windows do not remove duplicates wich is stupid) , then it adds volatil path after removing from it any duplicates 
    call :SetFromRegPATHHH "HKLM\System\CurrentControlSet\Control\Session Manager\Environment" Path Path_HKLM > "%TEMP%\_envPath.cmd"
    call :SetFromRegPATHHH "HKCU\Environment" Path Path_HKCU >> "%TEMP%\_envPath.cmd"
    call :SetFromRegPATHHH "HKCU\Volatile Environment" Path Path_HKCUV >> "%TEMP%\_envPath.cmd"
    
    
    REM ___________________________         
    REM aki anado el path actual asi no se resetea el path ya ke kizas haya anadido algo al path con el script ke llamara este script, si kiero resetear el path entonces comment this
        setlocal disabledelayedexpansion
        REM set "path=zzzzzzzzzzzz$$$$$$$$$;%path%"
        setlocal enabledelayedexpansion
        echo "!path!" >> "%TEMP%\_envPath.cmd"
    REM ___________________________         
           
    REM all 32 charachters: & % ' ( ) ~ + @ # $ { } [ ] ; , ` ! ^ | > < \ / " : ? * = . - _
    REM bad for FOR...()    &();,^|><"?*=   % !
    REM fine                %'~+@#${}[]`!\/:.-_
    REM invalid characters (illegal characters) in Windows using NTFS
    REM \ / : * ? "  < > |  and ^ in FAT 
 
 REM testing
    REM echo "all 32 charachters: & %% ' ( ) ~ + @ # $ { } [ ] ; , ` ! ^ | > < \ / "" : ? * = . - _" >> "%TEMP%\_envPath.cmd"
    REM echo "&_%%_'_(_)_~_+_@_#_$__[_];,`_!___^_|_>_<_\_/_:_?_* " >> "%TEMP%\_envPath.cmd"
    REM echo ;pointvergule >> "%TEMP%\_envPath.cmd"
    REM echo.>> "%TEMP%\_envPath.cmd"
    REM echo "quotess" >> "%TEMP%\_envPath.cmd"
    
    REM call cscript //Nologo  removePathDuplicates.vbs "%TEMP%\_envPath.cmd" "%TEMP%\_envPathclean.cmd"
    call cscript //nologo "%~f0?.wsf" "%TEMP%\_envPath.cmd" "%TEMP%\_envPathclean.cmd"
    type "%TEMP%\_envPathclean.cmd" >> "%TEMP%\_env_clean.cmd"
goto :EOF


:main
    REM del "%TEMP%\_env.cmd"
    type nul > "%TEMP%\_env.cmd"
    REM echo/@echo off >"%TEMP%\_env.cmd"

    :: Slowly generating final file
    call :GetRegEnv "HKLM\System\CurrentControlSet\Control\Session Manager\Environment" >> "%TEMP%\_env.cmd"
    REM call :GetRegEnv "HKCU\Environment">>"%TEMP%\_env.cmd" >> "%TEMP%\_env.cmd"
    call :GetRegEnv "HKCU\Environment" >> "%TEMP%\_env.cmd"
    call :GetRegEnv "HKCU\Volatile Environment" >> "%TEMP%\_env.cmd"

    REM delete any line containing the following variables
    type "%TEMP%\_env.cmd" | findstr /V /I /L "ALLUSERSPROFILE= APPDATA= CommonProgramFiles= CommonProgramFiles(x86)= CommonProgramW6432= COMPUTERNAME= ComSpec= HOMEDRIVE= HOMEPATH= LOCALAPPDATA= LOGONSERVER= NUMBER_OF_PROCESSORS= OS= PATHEXT= PROCESSOR_ARCHITECTURE= PROCESSOR_ARCHITEW6432= PROCESSOR_IDENTIFIER= PROCESSOR_LEVEL= PROCESSOR_REVISION= ProgramData= ProgramFiles= ProgramFiles(x86)= ProgramW6432= PUBLIC= SystemDrive= SystemRoot= TEMP= TMP= USERDOMAIN= USERDOMAIN_ROAMINGPROFILE= USERNAME= USERPROFILE= windir= SESSIONNAME=" > "%TEMP%\_env_clean.cmd"
    
    
    REM call :addPathOLDDD
    call :addPathWithoutDuplicates



REM the secure way for read all the lines with text of a file is the next way: 
REM For /f tokens^=*^ delims^=^ eol^= %%a in (%TEMP%\_envPath.cmd) do For /f tokens^=*^ delims^=;^ %%b in ("%%a") do   echo.%%b

REM del  expanded.txt
REM read line by line and ignore blank lines
REM setlocal disabledelayedexpansion
REM For /f delims^=^ eol^= %%a in (%TEMP%\_envPath.cmd) do (
    REM set var=%%a
    REM setlocal enabledelayedexpansion
        REM echo(!var! >> expanded.txt
    REM endlocal
REM )








    REM type "%TEMP%\_envPath.cmd"  | busybox sed -e "s/;/\r\n/ig"

    
   
        
    :: Set these variables
    REM met1
    REM very very bad
    REM add a var in reg as this and see that echo is executed
    REM all 32 charachters: & % ' ( ) ~ + @ # $ { } [ ] ; , ` ! ^ | > < \ / " : ? * = . - _ & echo baaaad
    REM call "%TEMP%\_env_clean.cmd"

    REM met2
    REM read line by line and ignore blank lines
    REM si activo disabledelayedexpansion las variables no pasan al script ke llama este script!
    REM setlocal disabledelayedexpansion
    REM works goooood but if a variable contain %..% it is not expanded
    For /f delims^=^ eol^= %%a in (%TEMP%\_env_clean.cmd) do %%a
     
     
    
    
    :: Cleanup
    del /f /q "%TEMP%\_envset.tmp" 2>nul
    del /f /q "%TEMP%\_envget.tmp" 2>nul
    del /f /q "%TEMP%\_env.cmd" 2>nul
    del /f /q "%TEMP%\_env_clean.cmd" 2>nul
    del /f /q "%TEMP%\_envPath.cmd" 2>nul
    del /f /q "%TEMP%\_envPathclean.cmd" 2>nul
    
    REM lets clear the var we do not need anymore
    SET "Path_HKLM="
    SET "Path_HKCU="
    SET "Path_HKCUV="
    
    REM echo | set /p dummy="Finished."
    echo .
    echo "Finished."
    echo .

    
    
:: The only restriction is the batch code cannot contain - - > (sin espacio claro)
:: The only restriction is the VBS code cannot contain </script>.
:: The only risk is the undocumented use of "%~f0?.wsf" as the script to load. Somehow the parser properly finds and loads the running .BAT script "%~f0", and the ?.wsf suffix mysteriously instructs CSCRIPT to interpret the script as WSF. Hopefully MicroSoft will never disable that "feature".
:: https://stackoverflow.com/questions/9074476/is-it-possible-to-embed-and-execute-vbscript-within-a-batch-file-without-using-a

REM cscript //nologo "%~f0?.wsf" %1
REM pause
exit /b

:: to run jscript you have to put <script language="JScript"> directly after ----- Begin wsf script --->
----- Begin wsf script --->
<job><script language="VBScript">
REM ##########################################################################################################
REM ### put you code here ####################################################################################
REM ##########################################################################################################



REM usage: removePathDuplicates.vbs sourcefile outputfile

' https://www.rosettacode.org/wiki/Remove_duplicate_elements#VBScript
' convert new lines to ; and expand variables so they become like windows do when he read reg and create path, then Remove duplicates without sorting 

 
REM Option Explicit
REM Dim fso,strFilename,outFilename,objFile,oldContent,newContent,arr,dict
    


strFilename=WScript.Arguments.Item(0)
outFilename=WScript.Arguments.Item(1)


Function remove_duplicates(list)
	arr = Split(list,";")
	Set dict = CreateObject("Scripting.Dictionary")
    dict.CompareMode = 1   ' force dictionary comapre to be case-insensitive , uncomment to force case-sensitive

	For i = 0 To UBound(arr)
		If dict.Exists(arr(i)) = False Then
			dict.Add arr(i),""
		End If
	Next
	For Each key In dict.Keys
		tmp = tmp & key & ";"
	Next
	remove_duplicates = Left(tmp,Len(tmp)-1)
End Function
 
REM WScript.Echo remove_duplicates("b;B;g;a;a;b;b;c;d;e;d;f;f;f;g;h")



 
'Does file exist?
Set fso=CreateObject("Scripting.FileSystemObject")
if fso.FileExists(strFilename)=false then
   wscript.echo "file not found!"
   wscript.Quit
end if
 
'Read file
set objFile=fso.OpenTextFile(strFilename,1)
oldContent=objFile.ReadAll
 

REM expand variables
set WshShell = WScript.CreateObject("WScript.Shell")
newContent = WshShell.ExpandEnvironmentStrings(oldContent)
REM convert new lines to ;
newContent=replace(newContent,vbCrLf,";",1,-1,0)
REM remove duplicates
newContent=remove_duplicates(newContent)
REM a veces por error puede ke el path tenga charachteres malos como ", o % , o tb estos:
REM invalid characters (illegal characters) in Windows using NTFS
REM \ / : * ? "  < > |  and ^ in FAT 
REM pero los mas peligrosos ke joden  batch segun mis tests son " % , asi ke borrare " y doblare %%
REM pero para estar seguro y puesto ke estos charachteres no pueden existir in folders paths then let s just remove them except / \ and :
REM newContent=Replace(newContent,"%","%%")
REM newContent=Replace(newContent,"*","")
REM newContent=Replace(newContent,"?","")
REM newContent=Replace(newContent,"""","")
REM newContent=Replace(newContent,"<","")
REM newContent=Replace(newContent,">","")
REM newContent=Replace(newContent,"|","")
REM add set "path=..." so it become easy to add it to "%TEMP%\_env.cmd"
newContent="set ""path=" + newContent + """"


'Write file:  ForAppending = 8 ForReading = 1 ForWriting = 2 , True=create file if not exist
set objFile=fso.OpenTextFile(outFilename,2,True)
objFile.Write newContent
REM WScript.Echo newContent


objFile.Close 





REM ### end ####################################################
REM this must be at the end
</script></job>
