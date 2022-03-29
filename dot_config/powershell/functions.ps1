# -*-mode:powershell-*- vim:ft=powershell

# ~/.config/powershell/profile.ps1
# =============================================================================
# PowerShell functions sourced by `./profile.ps1`.
#
# On Windows, this file will be copied over to these locations after
# running `chezmoi apply` by the script `../../run_powershell.bat.tmpl`:
#     - %USERPROFILE%\Documents\PowerShell
#     - %USERPROFILE%\Documents\WindowsPowerShell

# Create missing $IsWindows if running Powershell 5 or below.
if (!(Test-Path variable:global:IsWindows)) {
    Set-Variable "IsWindows" -Scope "Global" -Value ([System.Environment]::OSVersion.Platform -eq "Win32NT")
}

if ($null -eq (Get-Variable "ColorInfo" -ErrorAction "Ignore")) {
    Set-Variable -Name "ColorInfo" -Value "DarkYellow"
}

function Add-EnvPath {
    <#
    .SYNOPSIS
        Adds a path to the global path list.
    .DESCRIPTION
        Allows adding a new path to the beginning of end of the path list,
        whether it be for the session (default), the user or the machine.
    .PARAMETER Path
        The path to add.
    .PARAMETER Container
        The persistence of the path's inclusion: "Session", "User", or "Machine".
    .PARAMETER Position
        "Append" (default) or "Prepend" the new path.
    .EXAMPLE
        Add-EnvPath -Path /usr/local/bin -Container User -Position Prepend
    .INPUTS
        System.String
    .OUTPUTS
        None
    .LINK
        https://gist.github.com/mkropat/c1226e0cc2ca941b23a9
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Path,

        [ValidateSet('Machine', 'User', 'Session')]
        [string]$Container = 'Session',

        [ValidateSet('Append', 'Prepend')]
        [string]$Position = 'Append'
    )

    begin {
        $separator = ';'
        if (!$IsWindows) {
            $separator = ':'
        }
    }

    process {
        if ($Container -ne 'Session') {
            $containerMapping = @{
                Machine = [EnvironmentVariableTarget]::Machine
                User = [EnvironmentVariableTarget]::User
            }
            $containerType = $containerMapping[$Container]

            $persistedPaths = [Environment]::GetEnvironmentVariable('Path', $containerType) -Split $separator
            if ($persistedPaths -NotContains $Path) {
                if ($Position -eq 'Append') {
                    $persistedPaths = $persistedPaths + $Path | Where-Object { $_ }
                }
                else {
                    $persistedPaths = @($Path | Where-Object { $_ }) + $persistedPaths
                }
                [Environment]::SetEnvironmentVariable('Path', $persistedPaths -Join ';', $containerType)
            }
        }

        $envPaths = $env:PATH -Split $separator
        if ($envPaths -NotContains $Path) {
            if ($Position -eq 'Append') {
                $envPaths = $envPaths + $Path | Where-Object { $_ }
            }
            else {
                $envPaths = @($Path | Where-Object { $_ }) + $envPaths
            }
            $env:PATH = $envPaths -Join $separator
        }
    }
}

function Reset-Git { git reset --hard; git clean -df; }

function Use-ScoopGpg {
    Invoke-Expression -Command $(scoop which gpg) -PipelineVariable
}

function Use-ChezmoiGit {
    [CmdletBinding(PositionalBinding=$False)]
    param (
        [Parameter(ValueFromRemainingArguments=$True)]
        [string[]]
        $Remaining
    )

    process {
        chezmoi.exe git -- @Remaining
    }
}
