# -*-mode:powershell-*- vim:ft=powershell

# ~/.config/powershell/setup.ps1
# =============================================================================
# Idempotent manual setup script to install or update Powershell dependencies.
#
# On Windows, this file will be copied over to these locations after
# running `chezmoi apply` by the script `../../run_powershell.bat.tmpl`:
#     - %USERPROFILE%\Documents\PowerShell
#     - %USERPROFILE%\Documents\WindowsPowerShell
#
# TODO: Convert this to `~/dotfiles.ps1`

# Requires that PowerShell be running with elevated privileges to be able to
# change system properties.
#Disabled Requires -RunAsAdministrator

# Create missing $IsWindows if running Powershell 5 or below.
if (!(Test-Path variable:global:IsWindows)) {
    Set-Variable "IsWindows" -Scope "Global" -Value ([System.Environment]::OSVersion.Platform -eq "Win32NT")
}

if ($null -eq (Get-Variable "ColorInfo" -ErrorAction "Ignore")) {
    Set-Variable -Name ColorInfo -Value "DarkYellow"
}
Set-Variable -Name count -Value 0 -Scope Script

function eos {
    <#
    .SYNOPSIS
        Terminates the script and counts the actions taken.
    .INPUTS
        None
    .OUTPUTS
        None
    #>
    if ($count) {
        Write-Host "Done! $count modification(s) applied." -ForegroundColor $ColorInfo
        Write-Host "You need to restart your terminal for these changes to take effect."
    }
    else {
        Write-Host "No modifications performed." -ForegroundColor $ColorInfo
    }
    Remove-Variable -Name count -Scope Script
}

# Ask for confirmation.
$hereString = "
    This script will perform the following non-destructive adjustments to the system (if required):
        - Install package provider NuGet
        - Install/update Powershell modules"
if ($IsWindows) {
    $hereString += "
        - Enable LongPaths support for file paths above 260 characters"
}
$hereString += [Environment]::NewLine
Write-Host $hereString -ForegroundColor $ColorInfo
$confirmation = Read-Host -Prompt "Do you want to proceed? [y/N]"
if ($confirmation -notMatch '^y(es)?$') {
    eos
    exit
}
Remove-Variable -Name ("confirmation", "hereString")

#
# Dependencies
#

# Install NuGet package manager required to install WSL Interop and others.
# See https://www.nuget.org/
if (Get-PackageProvider -ListAvailable -Name NuGet -ErrorAction "Ignore") {
    Write-Host "NuGet already installed, skipping." -ForegroundColor $ColorInfo
}
else {
    Write-Host "Installing NuGet..." -ForegroundColor $ColorInfo
    Install-PackageProvider -Name NuGet -Force
    $count++
}

$AllowPrerelease = ($null -ne (Get-Command Install-Module -Syntax | Select-String "AllowPrerelease"))

# Install or update Powershell modules.
$modules = @{
    "DirColors" = @{
        Info = "colorize filenames and directories";
        Repo = "https://github.com/DHowett/DirColors";
        Install = $true;
        Force = $true;
        Prerelease = $false;
        IsCoreCLR = $false;
        AllowClobber = $false;
        SkipPublisherCheck = $true;
    };

    "PSScriptAnalyzer" = @{
        Info = "static code checker for PowerShell modules and scripts";
        Repo = "https://github.com/PowerShell/PSScriptAnalyzer";
        Install = $true;
        Force = $true;
        Prerelease = $false;
        IsCoreCLR = $false;
        AllowClobber = $false;
        SkipPublisherCheck = $false;
    };

    "Invoke-CommandAs" = @{
        Info = "Invoke Command as System/User on Local/Remote computer using ScheduleTask";
        Repo = "https://github.com/mkellerman/Invoke-CommandAs";
        Install = $true;
        Force = $true;
        Prerelease = $false;
        IsCoreCLR = $false;
        AllowClobber = $false;
        SkipPublisherCheck = $false;
    };
}

($modules.GetEnumerator() | Sort-Object -Property name) | ForEach-Object {
    if (!$_.Value.Install -or (!$IsCoreCLR -and $_.Value.IsCoreCLR)) {
        continue
    }

    if (Get-Module -ListAvailable -Name $_.Name -ErrorAction "Ignore") {
        Write-Host "Checking for $($_.Name) updates ($($_.Value.Info))..." -ForegroundColor $ColorInfo
        Update-Module $_.Name
    }
    else {
        Write-Host "Installing $($_.Name) ($($_.Value.Info))..." -ForegroundColor $ColorInfo
        if ($AllowPrerelease -and $_.Value.Prerelease) {
            Install-Module $_.Name -Scope CurrentUser -Force:$_.Value.Force -SkipPublisherCheck:$_.Value.SkipPublisherCheck -AllowClobber:$_.Value.AllowClobber -AllowPrerelease:$_.Value.Prerelease
        }
        else {
            Install-Module $_.Name -Scope CurrentUser -Force:$_.Value.Force -SkipPublisherCheck:$_.Value.SkipPublisherCheck -AllowClobber:$_.Value.AllowClobber
        }
        Get-Module -ListAvailable -Name $_.Name
        $count++
    }
}

# Setup Scoop.
# See https://github.com/lukesampson/scoop
if ($IsWindows) {
    if (!(Get-Command "scoop" -ErrorAction "Ignore")) {
        Invoke-Expression (New-Object System.Net.WebClient).DownloadString('https://get.scoop.sh')
    }
    if (Get-Command "scoop" -ErrorAction "Ignore") {
        Write-Host "Verifying the state of Scoop..." -ForegroundColor $ColorInfo
        Get-Command -Name scoop -ErrorAction Stop
        Invoke-Command -ScriptBlock { scoop checkup }

        # Install any missing bucket.
        $bucketList = Invoke-Command -ScriptBlock { scoop bucket list }
        $buckets = (
            "extras",
            "nerd-fonts"
        )
        $buckets | ForEach-Object {
            if (!$bucketList.Contains($_)) {
                Invoke-Command -ScriptBlock { scoop bucket add $_ }
            }
        }

        # Install any missing app.
        $appList = Invoke-Command -ScriptBlock { scoop export }
        $appList = $appList -replace "[\s].+",""
        $apps = (
            "1password-cli",
            "7zip",
            "chezmoi",
            "dark",
            "extras/gpg4win",
            "extras/vcredist2022",
            "gh",
            "git",
            "innounp",
            "jq",
            "less",
            "lessmsi",
            "neofetch",
            "neovim",
            "nerd-fonts/CascadiaCode-NF",
            "nodejs-lts",
            "putty",
            "ripgrep",
            "starship",
            "wget"
        )
        $apps | ForEach-Object {
            if (!$appList.Contains($_)) {
                Invoke-Command -ScriptBlock { scoop install $_ }
                $count++
            }
        }
        Invoke-Command -ScriptBlock { scoop uninstall extras/vcredist2022 }
    }
}


#
# Additional software
#

if ($IsWindows) {
    if (!Get-Command "pyenv" -ErrorAction "Ignore") {
        Write-Host "Installing pyenv and Python versions..." -ForegroundColor $ColorInfo
        git clone --quiet https://github.com/pyenv-win/pyenv-win.git "$HOME/.pyenv"
        $env:PYENV = $env:USERPROFILE + "\.pyenv\pyenv-win\"
        $env:PYENV_HOME = $env:PYENV
        $env:PYENV_ROOT = $env:PYENV
        [System.Environment]::SetEnvironmentVariable("PYENV", $env:PYENV, "User")
        [System.Environment]::SetEnvironmentVariable("PYENV_ROOT", $env:PYENV_ROOT, "User")
        [System.Environment]::SetEnvironmentVariable("PYENV_HOME", $env:PYENV_HOME, "User")
        [System.Environment]::SetEnvironmentVariable("path", $env:PYENV_ROOT + "\bin;" + $env:PYENV_ROOT + "\shims;" + [System.Environment]::GetEnvironmentVariable("path", "User"), "User")
        $count++
        Invoke-Expression -Command ($env:PYENV_ROOT + "\bin\pyenv.ps1") install 3.9.6
        $count++
        Invoke-Expression -Command ($env:PYENV_ROOT + "\bin\pyenv.ps1") install 2.7.6
        $count++
    }
}

#
# System tweaks
#

# Enable LongPaths support for file paths above 260 characters.
# See https://social.msdn.microsoft.com/Forums/en-US/fc85630e-5684-4df6-ad2f-5a128de3deef
if ($IsWindows) {
    $property = "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem"
    $name = "LongPathsEnabled"
    if ((Get-ItemPropertyValue $property -Name $name) -ne 0) {
        Write-Host "LongPaths support already enabled, skipping." -ForegroundColor $ColorInfo
    }
    else {
        Write-Host "Enabling LongPaths support for file paths above 260 characters." -ForegroundColor $ColorInfo
        Set-ItemProperty $property -Name $name -Value 1
        $count++
    }
}

# Display termination message.
eos
