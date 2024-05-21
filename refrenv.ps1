
# description: refrenv = refresh environment. for powershell
# https://github.com/badrelmers/RefrEnv
# usage: . .\refrenv.ps1

# based on Chocolatey powershell refreshenv 
##################################################################

# Copyright © 2017 - 2021 Chocolatey Software, Inc.
# Copyright © 2015 - 2017 RealDimensions Software, LLC
# Copyright © 2011 - 2015 RealDimensions Software, LLC & original authors/contributors from https://github.com/chocolatey/chocolatey
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

function Get-EnvironmentVariableNames([System.EnvironmentVariableTarget] $Scope) {
<#
.SYNOPSIS
Gets all environment variable names.

.DESCRIPTION
Provides a list of environment variable names based on the scope. This
can be used to loop through the list and generate names.

.NOTES
Process dumps the current environment variable names in memory /
session. The other scopes refer to the registry values.

.INPUTS
None

.OUTPUTS
A list of environment variables names.

.PARAMETER Scope
The environment variable target scope. This is `Process`, `User`, or
`Machine`.

.EXAMPLE
Get-EnvironmentVariableNames -Scope Machine

.LINK
Get-EnvironmentVariable

.LINK
Set-EnvironmentVariable
#>

  # Do not log function call

  # HKCU:\Environment may not exist in all Windows OSes (such as Server Core).
  switch ($Scope) {
    'User' { Get-Item 'HKCU:\Environment' -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Property }
    'Machine' { Get-Item 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment' | Select-Object -ExpandProperty Property }
    'Process' { Get-ChildItem Env:\ | Select-Object -ExpandProperty Key }
    default { throw "Unsupported environment scope: $Scope" }
  }
}


# Copyright © 2017 - 2021 Chocolatey Software, Inc.
# Copyright © 2015 - 2017 RealDimensions Software, LLC
# Copyright © 2011 - 2015 RealDimensions Software, LLC & original authors/contributors from https://github.com/chocolatey/chocolatey
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

function Get-EnvironmentVariable {
<#
.SYNOPSIS
Gets an Environment Variable.

.DESCRIPTION
This will will get an environment variable based on the variable name
and scope while accounting whether to expand the variable or not
(e.g.: `%TEMP%`-> `C:\User\Username\AppData\Local\Temp`).

.NOTES
This helper reduces the number of lines one would have to write to get
environment variables, mainly when not expanding the variables is a
must.

.PARAMETER Name
The environment variable you want to get the value from.

.PARAMETER Scope
The environment variable target scope. This is `Process`, `User`, or
`Machine`.

.PARAMETER PreserveVariables
A switch parameter stating whether you want to expand the variables or
not. Defaults to false. Available in 0.9.10+.

.PARAMETER IgnoredArguments
Allows splatting with arguments that do not apply. Do not use directly.

.EXAMPLE
Get-EnvironmentVariable -Name 'TEMP' -Scope User -PreserveVariables

.EXAMPLE
Get-EnvironmentVariable -Name 'PATH' -Scope Machine

.LINK
Get-EnvironmentVariableNames

.LINK
Set-EnvironmentVariable
#>
[CmdletBinding()]
[OutputType([string])]
param(
  [Parameter(Mandatory=$true)][string] $Name,
  [Parameter(Mandatory=$true)][System.EnvironmentVariableTarget] $Scope,
  [Parameter(Mandatory=$false)][switch] $PreserveVariables = $false,
  [parameter(ValueFromRemainingArguments = $true)][Object[]] $ignoredArguments
)

  # Do not log function call, it may expose variable names
  ## Called from chocolateysetup.psm1 - wrap any Write-Host in try/catch

  [string] $MACHINE_ENVIRONMENT_REGISTRY_KEY_NAME = "SYSTEM\CurrentControlSet\Control\Session Manager\Environment\";
  [Microsoft.Win32.RegistryKey] $win32RegistryKey = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey($MACHINE_ENVIRONMENT_REGISTRY_KEY_NAME)
  if ($Scope -eq [System.EnvironmentVariableTarget]::User) {
    [string] $USER_ENVIRONMENT_REGISTRY_KEY_NAME = "Environment";
    [Microsoft.Win32.RegistryKey] $win32RegistryKey = [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey($USER_ENVIRONMENT_REGISTRY_KEY_NAME)
  } elseif ($Scope -eq [System.EnvironmentVariableTarget]::Process) {
    return [Environment]::GetEnvironmentVariable($Name, $Scope)
  }

  [Microsoft.Win32.RegistryValueOptions] $registryValueOptions = [Microsoft.Win32.RegistryValueOptions]::None

  if ($PreserveVariables) {
    Write-Verbose "Choosing not to expand environment names"
    $registryValueOptions = [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames
  }

  [string] $environmentVariableValue = [string]::Empty

  try {
    #Write-Verbose "Getting environment variable $Name"
    if ($win32RegistryKey -ne $null) {
      # Some versions of Windows do not have HKCU:\Environment
      $environmentVariableValue = $win32RegistryKey.GetValue($Name, [string]::Empty, $registryValueOptions)
    }
  } catch {
    Write-Debug "Unable to retrieve the $Name environment variable. Details: $_"
  } finally {
    if ($win32RegistryKey -ne $null) {
      $win32RegistryKey.Close()
    }
  }

  if ($environmentVariableValue -eq $null -or $environmentVariableValue -eq '') {
    $environmentVariableValue = [Environment]::GetEnvironmentVariable($Name, $Scope)
  }

  return $environmentVariableValue
}



#https://github.com/chocolatey/choco/blob/f6d6140dd7abf7f99751cff6bb76c69ed834c9e7/src/chocolatey.resources/helpers/functions/Update-SessionEnvironment.ps1

# Copyright © 2017 - 2021 Chocolatey Software, Inc.
# Copyright © 2015 - 2017 RealDimensions Software, LLC
# Copyright © 2011 - 2015 RealDimensions Software, LLC & original authors/contributors from https://github.com/chocolatey/chocolatey
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

function Update-SessionEnvironment {
<#
.SYNOPSIS
Updates the environment variables of the current powershell session with
any environment variable changes that may have occured during a
Chocolatey package install.

.DESCRIPTION
When Chocolatey installs a package, the package author may add or change
certain environment variables that will affect how the application runs
or how it is accessed. Often, these changes are not visible to the
current PowerShell session. This means the user needs to open a new
PowerShell session before these settings take effect which can render
the installed application nonfunctional until that time.

Use the Update-SessionEnvironment command to refresh the current
PowerShell session with all environment settings possibly performed by
Chocolatey package installs.

.NOTES
This method is also added to the user's PowerShell profile as
`refreshenv`. When called as `refreshenv`, the method will provide
additional output.

Preserves `PSModulePath` as set by the process starting in 0.9.10.

.INPUTS
None

.OUTPUTS
None
#>

#  Write-FunctionCallLogMessage -Invocation $MyInvocation -Parameters $PSBoundParameters

  #ordering is important here, $user should override $machine...
  $ScopeList = 'Process', 'Machine'
  #powershell v2 which come preinstalled in win 7 do not have  -notin
  # the -notin operator is not available in the version of PowerShell running on Windows 7 system. The -notin operator was introduced in PowerShell 3.0
  #To work around this issue, you can use the -notcontains operator, which is available in earlier versions of PowerShell
  # TODO: i do not like this method at all, read the commit comment here for why they did it like that https://github.com/chocolatey/choco/commit/c408d1299b6f5f7e3e285d17f9e2d1719dfac122   should we really exclude User vars if we are using SYSTEM user? i aleady solved there fear about TMP by using excludedVariables so why do i need to exclude User var here? i probably do not need this check anymore but need to test it
  # if ($userName -notin ('SYSTEM', "${env:COMPUTERNAME}`$")) {
  # if ('SYSTEM', "${env:COMPUTERNAME}`$" -notcontains $userName) {
  if (-not ($userName -contains 'SYSTEM' -or $userName -contains "${env:COMPUTERNAME}`$")) {
    # but only if not running as the SYSTEM/machine in which case user can be ignored.
    $ScopeList += 'User'
  }

  # Define a list of environment variables to exclude, this is the same list i m using in cmd
  # TODO: do i need to exclude some special powershell env like i did in bash?
  $excludedVariables = @(
    'Path',   'ALLUSERSPROFILE', 'APPDATA', 'CommonProgramFiles', 'CommonProgramFiles(x86)', 
    'CommonProgramW6432', 'COMPUTERNAME', 'ComSpec', 'HOMEDRIVE', 'HOMEPATH', 
    'LOCALAPPDATA', 'LOGONSERVER', 'NUMBER_OF_PROCESSORS', 'OS', 'PATHEXT', 
    'PROCESSOR_ARCHITECTURE', 'PROCESSOR_ARCHITEW6432', 'PROCESSOR_IDENTIFIER', 
    'PROCESSOR_LEVEL', 'PROCESSOR_REVISION', 'ProgramData', 'ProgramFiles', 
    'ProgramFiles(x86)', 'ProgramW6432', 'PUBLIC', 'SystemDrive', 'SystemRoot', 
    'TEMP', 'TMP', 'USERDOMAIN', 'USERDOMAIN_ROAMINGPROFILE', 'USERNAME', 
    'USERPROFILE', 'windir', 'SESSIONNAME'
  )

  foreach ($Scope in $ScopeList) {
    Get-EnvironmentVariableNames -Scope $Scope | ForEach-Object {
      # Skip setting the PATH and the dangerous environment variables (case-insensitive comparison)
      if ($excludedVariables -inotcontains $_) {
        Set-Item "Env:$_" -Value (Get-EnvironmentVariable -Scope $Scope -Name $_)
      }
    }
  }

  
  if ($env:RefrEnv_ResetPath -eq 'yes') {
    $scopes = 'Machine', 'User'
  } else {
    $scopes = 'Process', 'Machine', 'User'
  }

  #Path gets special treatment b/c it munges the two together
  $paths = $scopes |
    ForEach-Object {
      (Get-EnvironmentVariable -Name 'PATH' -Scope $_) -split ';'
    } |
    Select-Object -Unique
  $Env:PATH = $paths -join ';'
 
  # PSModulePath is almost always updated by process, so we want to preserve it.
  # TODO: should i exclude this? what happens when an app adds a path to PSModulePath in the hklm reg? so i think i should not prevent updating this
  # $env:PSModulePath = $psModulePath

}

# Set-Alias refreshenv Update-SessionEnvironment

echo 'RefrEnv - Refresh the Environment for powershell/pwsh'

Update-SessionEnvironment
