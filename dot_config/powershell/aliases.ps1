# -*-mode:powershell-*- vim:ft=powershell

# ~/.config/powershell/aliases.ps1
# =============================================================================
# PowerShell aliases sourced by `./profile.ps1`.
#
# On Windows, this file will be copied over to these locations after
# running `chezmoi apply` by the script `../../run_powershell.bat.tmpl`:
#     - %USERPROFILE%\Documents\PowerShell
#     - %USERPROFILE%\Documents\WindowsPowerShell
#
# Since PowerShell does not allow aliases to contain parameters, most of the
# logic is wrapped in `./functions.ps1`.

# Create missing $IsWindows if running Powershell 5 or below.
if (!(Test-Path variable:global:IsWindows)) {
    Set-Variable "IsWindows" -Scope "Global" -Value ([System.Environment]::OSVersion.Platform -eq "Win32NT")
}

if (!(Get-Command "ls" -ErrorAction "Ignore")) {
    Set-Alias -Name "ls" -Value Get-ChildItemSimple -Description "Lists visible files in wide format."
}

Set-Alias -Name "l" -Value Get-ChildItemVisible -Description "Lists visible files in long format."
Set-Alias -Name "ll" -Value Get-ChildItemAll -Description "Lists all files in long format."
Set-Alias -Name "lsd" -Value Get-ChildItemDirectory -Description "Lists only directories in long format."
Set-Alias -Name "lsh" -Value Get-ChildItemHidden -Description "Lists only hidden files in long format."

Set-Alias -Name "alias" -Value Get-Aliases -Description "Lists aliases."

if (Get-Command "chezmoi" -ErrorAction "Ignore") {
    Set-Alias -Name "cz" -Value chezmoi
    Set-Alias -Name "czg" -Value Use-ChezmoiGit
}

if (Get-Command "git" -ErrorAction "Ignore") {
    Set-Alias -Name "g" -Value git
    Set-Alias -Name "nah" -Value Reset-Git
}

if (Get-Command "nvim" -ErrorAction "Ignore") {
    Set-Alias -Name "vim" -Value nvim
}
