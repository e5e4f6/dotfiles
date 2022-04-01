# -*-mode:powershell-*- vim:ft=powershell

# ~/.config/powershell/profile.ps1
# =============================================================================
# Executed when PowerShell starts.
#
# On Windows, this file will be copied over to these locations after
# running `chezmoi apply` by the script `../../run_powershell.bat.tmpl`:
#     - %USERPROFILE%\Documents\PowerShell
#     - %USERPROFILE%\Documents\WindowsPowerShell
#
# See https://docs.microsoft.com/en/powershell/module/microsoft.powershell.core/about/about_profiles

# Determine user profile parent directory.
$ProfilePath=Split-Path -parent $profile

# Load functions declarations from separate configuration file.
if (Test-Path $ProfilePath/functions.ps1) {
    . $ProfilePath/functions.ps1
}

Import-Module DirColors

if (Test-Path "$env:AppData\gnupg") {
    $env:GNUPGHOME = "$env:AppData\gnupg"
    [System.Environment]::SetEnvironmentVariable('GNUPGHOME', $env:GNUPGHOME)
}


# Add missing user paths.
# if (Get-Command Add-EnvPath -errorAction Ignore) {
#     if ($IsWindows) {
#         Add-EnvPath -Path "${Env:Programfiles}\Git\cmd\" -Position "Append"
#     }
#     else {
#         Add-EnvPath -Path "/usr/local/sbin" -Position "Prepend"
#         Add-EnvPath -Path "/usr/local/bin" -Position "Prepend"
#     }
# }

# Load chezmoi completion from separate configuration file.
if (Test-Path $ProfilePath/chezmoi-completion.ps1) {
    . $ProfilePath/chezmoi-completion.ps1
}

# Load alias definitions from separate configuration file.
if (Test-Path $ProfilePath/aliases.ps1) {
    . $ProfilePath/aliases.ps1
}

# Configure editor for various tasks
if (Get-Command "nvim" -ErrorAction "Ignore") {
    $env:EDITOR = "nvim"
}

$env:STARSHIP_CONFIG = "$HOME\.starship\config.toml"

Invoke-Expression (&starship init powershell)
