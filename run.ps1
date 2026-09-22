<#
.SYNOPSIS
    Windows setup script for this dotfiles repo (counterpart to ./run.sh).

.DESCRIPTION
    Uses GNU Stow to link this repo's packages into your home directory, with
    first-class support for the `emacs` package (i.e. the Doom Emacs config at
    ~/.config/doom).

    What it does, in order:
      1. Checks for Git for Windows (bash + perl are required for Stow).
      2. Ensures real symlink support (Windows Developer Mode). Without it,
         MSYS silently *copies* files instead of linking and Stow is useless.
      3. Installs GNU Stow into %USERPROFILE%\.local\share\stow and puts a
         `stow` wrapper on %USERPROFILE%\bin (which Git Bash already has on
         PATH). The wrapper forces MSYS=winsymlinks:nativestrict so links are
         real NTFS symlinks.
      4. Applies the selected stow packages (default: emacs).
      5. Optionally installs the latest GNU Emacs via winget (or Chocolatey).
      6. Optionally clones Doom Emacs to ~/.emacs.d and runs `doom install`.
         This never touches your stowed config (it runs with --no-config), and
         it also drops a bin\doom.cmd shim, because PowerShell's PATHEXT has no
         .PS1 entry and Doom's own scripts call bare `doom`.
      7. Sets HOME=%USERPROFILE% so Emacs and Git Bash agree on what ~ means,
         and adds Emacs/Doom to your user PATH.
      8. Optionally registers the Emacs daemon to start at login, and creates
         Emacs shortcuts in the Start Menu, on the desktop, and on the taskbar.

    Safe to re-run: every step is idempotent.

.PARAMETER Yes
    Non-interactive mode: answer "yes" to every prompt.

.PARAMETER Packages
    Explicit list of stow packages to apply. Defaults to `emacs`.

.PARAMETER NoEmacs
    Skip installing Emacs and Doom Emacs.

.PARAMETER NoDaemon
    Skip registering the Emacs daemon at login.

.PARAMETER NoShortcuts
    Skip creating Emacs shortcuts (Start Menu, desktop, taskbar).

.PARAMETER DryRun
    Run stow in simulation mode (-n). Installs nothing, changes nothing.

.PARAMETER Force
    Reinstall GNU Stow even if it is already present.

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File .\run.ps1

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File .\run.ps1 -Yes -NoDaemon

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File .\run.ps1 -DryRun
#>
[CmdletBinding()]
param(
    [switch] $Yes,
    [string[]] $Packages,
    [switch] $NoEmacs,
    [switch] $NoDaemon,
    [switch] $NoShortcuts,
    [switch] $DryRun,
    [switch] $Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Packages that only make sense on Linux (Hyprland/Waybar/keyd/etc.).
$LinuxOnlyPackages = @(
    'hypr', 'waybar', 'keyd',
    'xdg-desktop-portal', 'xdg-desktop-portal-termfilechooser'
)

$StowVersion = '2.4.1'
$UserHome    = $env:USERPROFILE
$RepoRoot    = $PSScriptRoot
$StowRoot    = Join-Path $UserHome '.local\share\stow'
$UserBin     = Join-Path $UserHome 'bin'
$BashExe     = $null

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

function Write-Step  { param([string] $Message) Write-Host "`n==> $Message" -ForegroundColor Cyan }
function Write-Ok    { param([string] $Message) Write-Host "    $Message" -ForegroundColor Green }
function Write-Warn2 { param([string] $Message) Write-Host "    $Message" -ForegroundColor Yellow }
function Write-Info  { param([string] $Message) Write-Host "    $Message" }

function Confirm-Action {
    param([string] $Prompt, [bool] $Default = $true)
    if ($Yes) { return $true }
    $suffix = if ($Default) { '[Y/n]' } else { '[y/N]' }
    $answer = Read-Host "    $Prompt $suffix"
    if ([string]::IsNullOrWhiteSpace($answer)) { return $Default }
    return ($answer -match '^(y|yes)$')
}

function Test-Admin {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    return (New-Object Security.Principal.WindowsPrincipal($id)).IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Invoke-Elevated {
    param([string] $Command, [string] $Label = 'elevated command')
    if (Test-Admin) {
        & powershell.exe -NoProfile -ExecutionPolicy Bypass -Command $Command
        return $LASTEXITCODE
    }
    Write-Info "Requesting administrator rights for $Label (accept the UAC prompt)..."
    $p = Start-Process -FilePath 'powershell.exe' -Verb RunAs -Wait -PassThru `
                       -ArgumentList '-NoProfile', '-ExecutionPolicy', 'Bypass', '-Command', $Command
    return $p.ExitCode
}

function Get-GitBashPath {
    $candidates = @(
        (Join-Path $env:ProgramFiles 'Git\bin\bash.exe'),
        (Join-Path $env:ProgramFiles 'Git\usr\bin\bash.exe'),
        (Join-Path ${env:ProgramFiles(x86)} 'Git\bin\bash.exe')
    )
    foreach ($c in $candidates) {
        if ($c -and (Test-Path $c)) { return $c }
    }
    $cmd = Get-Command bash.exe -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    return $null
}

function ConvertTo-MsysPath {
    param([string] $WindowsPath)
    $normalised = $WindowsPath -replace '\\', '/'
    return (& $BashExe -lc "cygpath -u '$normalised'").Trim()
}

function Test-SymlinkSupport {
    # Probe with MSYS + perl, i.e. the exact mechanism GNU Stow uses.
    # Notes:
    #  * .NET Framework / Windows PowerShell 5.1's own SymbolicLink API does not
    #    pass SYMBOLIC_LINK_FLAG_ALLOW_UNPRIVILEGED_CREATE, so it reports failure
    #    even with Developer Mode enabled -- a false negative. Hence perl.
    #  * The perl code deliberately avoids double quotes: PowerShell 5.1 mangles
    #    embedded double quotes when passing arguments to native commands.
    $probeDir = Join-Path $env:TEMP ("linkprobe_" + [guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $probeDir -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $probeDir 'target') -Force | Out-Null

    $result = $false
    try {
        $msys = ConvertTo-MsysPath $probeDir
        $code = 'symlink(q{target},q{link}) or exit 1; exit(-l q{link} ? 0 : 2);'
        & $BashExe -lc "cd '$msys' && MSYS=winsymlinks:nativestrict perl -e '$code' 2>/dev/null"
        $result = ($LASTEXITCODE -eq 0)
    } catch {
        $result = $false
    }
    Remove-Item -Recurse -Force $probeDir -ErrorAction SilentlyContinue
    return $result
}

function Set-UserEnv {
    param([string] $Name, [string] $Value)
    $current = [Environment]::GetEnvironmentVariable($Name, 'User')
    if ($current -ne $Value) {
        [Environment]::SetEnvironmentVariable($Name, $Value, 'User')
        Write-Ok "Set user environment variable $Name=$Value"
    }
}

function Add-UserPath {
    param([string] $Directory)
    if (-not (Test-Path $Directory)) { return }
    $current = [Environment]::GetEnvironmentVariable('Path', 'User')
    if ($null -eq $current) { $current = '' }
    $entries = @($current -split ';' | Where-Object { $_ -ne '' })
    if ($entries -notcontains $Directory) {
        $updated = (($entries + $Directory) -join ';')
        [Environment]::SetEnvironmentVariable('Path', $updated, 'User')
        Write-Ok "Added to user PATH: $Directory"
    }
}

# ---------------------------------------------------------------------------
# Steps
# ---------------------------------------------------------------------------

function Install-Stow {
    Write-Step 'Installing GNU Stow'

    $stowScript = Join-Path $UserBin 'stow'
    if ((Test-Path $stowScript) -and -not $Force) {
        $version = (& $BashExe -lc 'stow --version' 2>&1) -join ' '
        if ($LASTEXITCODE -eq 0 -and $version -match 'GNU Stow') {
            Write-Ok "Already installed ($version)"
            return
        }
    }

    if ($DryRun) { Write-Info "Dry run: would install GNU Stow $StowVersion"; return }

    if (-not (Get-Command tar.exe -ErrorAction SilentlyContinue)) {
        throw 'tar.exe not found. Windows 10 build 17063+ is required.'
    }

    $tmp = Join-Path $env:TEMP ("stow-" + [guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $tmp -Force | Out-Null
    try {
        $tarball = Join-Path $tmp 'stow.tar.gz'
        $urls = @(
            "https://ftp.gnu.org/gnu/stow/stow-$StowVersion.tar.gz",
            'https://ftp.gnu.org/gnu/stow/stow-latest.tar.gz'
        )
        $downloaded = $false
        foreach ($url in $urls) {
            try {
                Write-Info "Downloading $url"
                Invoke-WebRequest -Uri $url -OutFile $tarball -UseBasicParsing
                $downloaded = $true
                break
            } catch {
                Write-Warn2 "Download failed: $url"
            }
        }
        if (-not $downloaded) { throw 'Could not download GNU Stow.' }

        tar -xzf $tarball -C $tmp
        $srcDir = Get-ChildItem -Path $tmp -Directory -Filter 'stow-*' |
                  Select-Object -First 1
        if (-not $srcDir) { throw 'Unexpected Stow tarball layout.' }
        $src = $srcDir.FullName

        $libDir = Join-Path $StowRoot 'lib'
        $binDir = Join-Path $StowRoot 'bin'
        New-Item -ItemType Directory -Path (Join-Path $libDir 'Stow') -Force | Out-Null
        New-Item -ItemType Directory -Path $binDir -Force | Out-Null
        New-Item -ItemType Directory -Path $UserBin -Force | Out-Null

        $utf8 = New-Object System.Text.UTF8Encoding($false)
        function Write-Lf {
            param([string] $Path, [string] $Text)
            [System.IO.File]::WriteAllText($Path, $Text, $utf8)
        }

        # Stow.pm is generated by appending the default ignore list (see the
        # upstream Makefile: $(edit) < Stow.pm.in; cat default-ignore-list).
        $util = [System.IO.File]::ReadAllText((Join-Path $src 'lib\Stow\Util.pm.in')) `
                    -replace '@VERSION@', $StowVersion
        Write-Lf (Join-Path $libDir 'Stow\Util.pm') $util

        $stowPm = [System.IO.File]::ReadAllText((Join-Path $src 'lib\Stow.pm.in')) `
                    -replace '@VERSION@', $StowVersion
        $stowPm += [System.IO.File]::ReadAllText((Join-Path $src 'default-ignore-list'))
        Write-Lf (Join-Path $libDir 'Stow.pm') $stowPm

        # The bin/stow script is an .in template too. Substituting @PERL@ with a
        # shebang of our own; the wrapper below supplies the interpreter anyway.
        $libWin = ($libDir -replace '\\', '/')
        $script = [System.IO.File]::ReadAllText((Join-Path $src 'bin\stow.in')) `
                    -replace '#!@PERL@', '#!/usr/bin/perl' `
                    -replace '@VERSION@', $StowVersion `
                    -replace '@USE_LIB_PMDIR@', "use lib '$libWin';"
        $scriptPath = Join-Path $binDir 'stow.pl'
        Write-Lf $scriptPath $script

        # Wrapper: run under Git Bash's perl and force native symlinks.
        $wrapper = @"
#!/bin/sh
# GNU Stow wrapper for Git Bash on Windows.
# MSYS=winsymlinks:nativestrict forces real NTFS symlinks instead of MSYS
# silently copying files, which would defeat the point of Stow.
# (Requires Windows Developer Mode -- see `run.ps1`.)
export MSYS=winsymlinks:nativestrict
exec perl "$(($scriptPath -replace '\\', '/'))" "`$@"
"@
        [System.IO.File]::WriteAllText($stowScript, ($wrapper -replace "`r`n", "`n"), $utf8)

        $version = (& $BashExe -lc 'stow --version' 2>&1) -join ' '
        if ($LASTEXITCODE -ne 0) { throw "Stow installed but not runnable: $version" }
        Write-Ok $version
    }
    finally {
        Remove-Item -Recurse -Force $tmp -ErrorAction SilentlyContinue
    }
}

function Select-Packages {
    if ($Packages) { return $Packages }

    $available = @(
        Get-ChildItem -Path $RepoRoot -Directory |
            Where-Object { $_.Name -notlike '.*' } |
            Select-Object -ExpandProperty Name
    )
    if ($available.Count -eq 0) { throw "No stow packages found in $RepoRoot" }

    $compatible = @($available | Where-Object { $LinuxOnlyPackages -notcontains $_ })

    if (Confirm-Action 'Set up just the Emacs/Doom config (package: emacs)?' $true) {
        return @('emacs')
    }

    Write-Info "Available on Windows: $($compatible -join ', ')"
    Write-Info "(Skipping Linux-only: $($LinuxOnlyPackages | Where-Object { $available -contains $_ } -join ', '))"
    $answer = Read-Host "    Packages (comma separated, Enter for emacs)"
    if ([string]::IsNullOrWhiteSpace($answer)) { return @('emacs') }
    return @($answer -split '[, ]+' | Where-Object { $_ -ne '' })
}

function Invoke-Stow {
    param([string[]] $Selected)

    Write-Step "Applying stow packages: $($Selected -join ', ')"

    $repoMsys = ConvertTo-MsysPath $RepoRoot
    $flags    = '-v -t ~ --dotfiles'
    if ($DryRun) { $flags = '-n ' + $flags }

    $pkgList = ($Selected -join ' ')
    & $BashExe -lc "cd '$repoMsys' && stow $flags $pkgList"
    if ($LASTEXITCODE -ne 0) { throw "stow failed (exit $LASTEXITCODE)" }

    $doomLink = Join-Path $UserHome '.config\doom'
    if (Test-Path $doomLink) {
        $item = Get-Item $doomLink -Force
        Write-Ok "$doomLink ($($item.LinkType)) -> $($item.Target)"
    }
}

function Find-EmacsBin {
    $cmd = Get-Command emacs.exe -ErrorAction SilentlyContinue
    if ($cmd) { return (Split-Path $cmd.Source) }
    $found = Get-ChildItem -Path (Join-Path $env:ProgramFiles 'Emacs') `
                           -Directory -Filter 'emacs-*' -ErrorAction SilentlyContinue |
             Sort-Object Name -Descending |
             ForEach-Object { Join-Path $_.FullName 'bin' } |
             Where-Object { Test-Path (Join-Path $_ 'emacs.exe') }
    if ($found) { return @($found)[0] }
    return $null
}

function Install-Emacs {
    Write-Step 'Installing GNU Emacs'

    $emacsBin = Find-EmacsBin
    if ($emacsBin) {
        $version = (& (Join-Path $emacsBin 'emacs.exe') --version 2>&1 | Select-Object -First 1)
        Write-Ok "Already installed: $version"
        return $emacsBin
    }

    if ($DryRun) { Write-Info 'Dry run: would install GNU Emacs'; return $null }

    if (-not (Confirm-Action 'Install the latest GNU Emacs via winget?' $true)) {
        Write-Warn2 'Skipping Emacs install.'
        return $null
    }

    if (Get-Command winget.exe -ErrorAction SilentlyContinue) {
        $wingetArgs = 'install --id GNU.Emacs --exact --silent --disable-interactivity ' +
                      '--accept-package-agreements --accept-source-agreements'
        if (Test-Admin) {
            & winget.exe $wingetArgs.Split(' ') | Write-Host
        } else {
            Invoke-Elevated "winget.exe $wingetArgs" 'winget install GNU.Emacs' | Out-Null
        }
    } elseif (Get-Command choco.exe -ErrorAction SilentlyContinue) {
        if (Test-Admin) { & choco.exe install emacs -y | Write-Host }
        else { Invoke-Elevated 'choco.exe install emacs -y' 'choco install emacs' | Out-Null }
    } else {
        Write-Warn2 'Neither winget nor choco found; install Emacs manually.'
        return $null
    }

    $emacsBin = Find-EmacsBin
    if (-not $emacsBin) {
        $emacsBin = Get-ChildItem -Path (Join-Path $env:ProgramFiles 'Emacs') `
                                  -Directory -ErrorAction SilentlyContinue |
                    Sort-Object Name -Descending |
                    ForEach-Object { Join-Path $_.FullName 'bin' } |
                    Where-Object { Test-Path (Join-Path $_ 'emacs.exe') } |
                    Select-Object -First 1
    }
    if (-not $emacsBin) { Write-Warn2 'Could not locate emacs.exe after install.'; return $null }

    Write-Ok "Emacs installed at $emacsBin"
    return $emacsBin
}

function Install-Doom {
    param([string] $EmacsBin)
    if ($NoEmacs) { return }

    Write-Step 'Setting up Doom Emacs'

    if (-not $EmacsBin) {
        Write-Warn2 'No Emacs found; skipping Doom.'
        return
    }
    if (-not (Confirm-Action 'Install/update Doom Emacs in ~/.emacs.d?' $true)) {
        Write-Warn2 'Skipping Doom.'
        return
    }
    if ($DryRun) { Write-Info 'Dry run: would set up Doom Emacs'; return }

    $doomDir = Join-Path $UserHome '.emacs.d'
    if (Test-Path (Join-Path $doomDir 'bin\doom.ps1')) {
        Write-Ok "Doom already present at $doomDir"
    } else {
        Write-Info "Cloning Doom Emacs into $doomDir"
        & git.exe clone --depth 1 https://github.com/doomemacs/doomemacs $doomDir
        if ($LASTEXITCODE -ne 0) { throw 'Failed to clone Doom Emacs.' }
    }

    # Doom ships bin\doom.ps1 but PowerShell's PATHEXT has no .PS1 entry, so bare
    # `doom` would not resolve -- yet Doom's own restart scripts call `doom ...`.
    $shim = Join-Path $doomDir 'bin\doom.cmd'
    if (-not (Test-Path $shim)) {
        $shimBody = @'
@echo off
REM Shim so the `doom` CLI is callable from cmd.exe and PowerShell.
REM Doom ships bin\doom.ps1, but PowerShell's PATHEXT has no .PS1 entry, so
REM bare `doom` would not resolve. Doom's own restart scripts call `doom ...`.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0doom.ps1" %*
exit /b %ERRORLEVEL%
'@
        [System.IO.File]::WriteAllText($shim, ($shimBody -replace "`r`n", "`r`n"),
            (New-Object System.Text.UTF8Encoding($false)))
        Write-Ok "Created $shim"
    }

    Add-UserPath (Join-Path $doomDir 'bin')
    Add-UserPath $EmacsBin

    # Make sure the current session matches what we just persisted.
    $env:HOME = $UserHome
    $env:Path = (Join-Path $doomDir 'bin') + ';' + $EmacsBin + ';' + $env:Path

    # Run in a child PowerShell: bin/doom.ps1 calls `exit`, and its CLI may
    # re-exec itself through a generated script (that is how Doom works).
    Write-Info 'Running `doom install` (your stowed config is left untouched)...'
    $doomPs1 = Join-Path $doomDir 'bin\doom.ps1'
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $doomPs1 install --no-config -!
    if ($LASTEXITCODE -ne 0) { throw "doom install failed (exit $LASTEXITCODE)" }
    Write-Ok 'Doom Emacs installed.'
}

function Register-EmacsDaemon {
    param([string] $EmacsBin)
    if ($NoDaemon) { return }

    Write-Step 'Emacs daemon at login'
    if (-not $EmacsBin) { Write-Warn2 'No Emacs found; skipping daemon.'; return }
    if (-not (Confirm-Action 'Start the Emacs daemon at login?' $true)) {
        Write-Warn2 'Skipping daemon.'
        return
    }
    if ($DryRun) { Write-Info 'Dry run: would register the Emacs daemon'; return }

    $runemacs = Join-Path $EmacsBin 'runemacs.exe'
    if (-not (Test-Path $runemacs)) { $runemacs = Join-Path $EmacsBin 'emacs.exe' }

    # runemacs.exe starts the daemon without leaving a console window around.
    $command = """$runemacs"" --daemon"
    $key = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run'
    New-Item -Path $key -Force | Out-Null
    New-ItemProperty -Path $key -Name 'EmacsDaemon' -Value $command `
                     -PropertyType String -Force | Out-Null
    Write-Ok "Registered HKCU\...\Run\EmacsDaemon = $command"

    # Bring it up now as well, so this run leaves you with a usable daemon.
    $ec = Join-Path $EmacsBin 'emacsclient.exe'
    $running = $false
    if (Test-Path $ec) {
        & $ec -e '(emacs-pid)' 2>&1 | Out-Null
        $running = ($LASTEXITCODE -eq 0)
    }
    if ($running) {
        Write-Ok 'Emacs daemon is already running.'
    } else {
        $env:HOME = $UserHome
        Start-Process -FilePath $runemacs -ArgumentList '--daemon'
        Write-Ok 'Started the Emacs daemon.'
    }
    Write-Info 'Connect with: emacsclientw.exe -c   (or emacsclient -t)'
}

function Install-Shortcuts {
    param([string] $EmacsBin)
    if ($NoShortcuts) { return }
    if (-not $EmacsBin) { $EmacsBin = Find-EmacsBin }
    if (-not $EmacsBin) { return }

    Write-Step 'Emacs shortcuts'
    $client = Join-Path $EmacsBin 'emacsclientw.exe'
    if (-not (Test-Path $client)) {
        Write-Warn2 "emacsclientw.exe not found in $EmacsBin; skipping shortcuts."
        return
    }
    if (-not (Confirm-Action 'Create Emacs shortcuts (Start Menu, desktop, taskbar)?' $true)) {
        Write-Warn2 'Skipping shortcuts.'
        return
    }
    if ($DryRun) { Write-Info "Dry run: would create shortcuts to $client"; return }

    # Emacs ships emacs.ico in a couple of places; pick the first valid one.
    $emacsRoot = Split-Path $EmacsBin -Parent
    $icon = $null
    foreach ($c in @((Join-Path $emacsRoot 'share\icons\hicolor\scalable\apps\emacs.ico'))) {
        if ((Test-Path $c) -and -not $icon) { $icon = $c }
    }
    if (-not $icon) {
        $hit = Get-ChildItem -Path (Join-Path $emacsRoot 'share\emacs') -Recurse `
                             -Filter 'emacs.ico' -ErrorAction SilentlyContinue |
               Select-Object -First 1
        if ($hit) { $icon = $hit.FullName }
    }
    if ($icon) {
        $sig = [System.IO.File]::ReadAllBytes($icon)
        if (-not ($sig[0] -eq 0 -and $sig[1] -eq 0 -and $sig[2] -eq 1 -and $sig[3] -eq 0)) {
            $icon = $null
        }
    }

    # A new GUI frame; -a "" (empty alternate editor) starts the daemon if it
    # isn't already running, so the shortcut works even after a fresh boot.
    $clientArgs = '-c -n -a ""'

    $ws = New-Object -ComObject WScript.Shell
    function New-EmacsShortcut {
        param([string] $Path)
        $sc = $ws.CreateShortcut($Path)
        $sc.TargetPath       = $client
        $sc.Arguments        = $clientArgs
        $sc.WorkingDirectory = $UserHome
        if ($icon) { $sc.IconLocation = "$icon,0" }
        $sc.Description = 'Emacs (emacsclient new frame)'
        $sc.Save()
        Write-Ok $Path
    }

    $desktop    = [Environment]::GetFolderPath('Desktop')
    $programs   = [Environment]::GetFolderPath('Programs')
    $taskbarDir = Join-Path $env:APPDATA 'Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar'

    New-EmacsShortcut (Join-Path $desktop  'Emacs.lnk')
    New-EmacsShortcut (Join-Path $programs 'Emacs.lnk')

    if (Test-Path $taskbarDir) {
        New-EmacsShortcut (Join-Path $taskbarDir 'Emacs.lnk')
        if (Confirm-Action 'Restart Explorer so the taskbar pin appears? (closes open File Explorer windows)' $true) {
            Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
            Start-Sleep -Seconds 5
            if (-not (Get-Process explorer -ErrorAction SilentlyContinue)) {
                Start-Process explorer.exe
                Start-Sleep -Seconds 4
            }
            Write-Ok 'Explorer restarted; Emacs should now be pinned to the taskbar.'
        } else {
            Write-Warn2 'The pin appears after Explorer restarts or you sign out and back in.'
        }
    } else {
        Write-Warn2 'Taskbar pinned-shortcuts folder not found; skipping the taskbar pin.'
    }
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

Write-Host "Dotfiles setup (Windows)" -ForegroundColor White
Write-Host "Repository: $RepoRoot"
Write-Host "Mode: $(if ($DryRun) { 'dry run' } else { 'apply' })"

Write-Step 'Checking prerequisites'

$BashExe = Get-GitBashPath
if (-not $BashExe) {
    throw 'Git for Windows not found. Install it first: winget install Git.Git'
}
Write-Ok "Git Bash: $BashExe"

$perl = (& $BashExe -lc 'command -v perl' 2>&1) -join ''
if (-not $perl) { throw 'perl not found in Git Bash (required by GNU Stow).' }
Write-Ok "perl: $perl"

# HOME must match Git Bash's notion of ~ so both agree where dotfiles live.
Set-UserEnv 'HOME' $UserHome
$env:HOME = $UserHome   # and for this session, so child processes agree

if ([Environment]::GetEnvironmentVariable('DOOMDIR', 'User')) {
    Write-Warn2 'DOOMDIR is set; Doom will use it instead of ~/.config/doom.'
    Write-Warn2 'Unset it (setx DOOMDIR "") if you want the stowed config to be used.'
}

Write-Step 'Checking symlink support'
if (Test-SymlinkSupport) {
    Write-Ok 'Symlinks work.'
} elseif ($DryRun) {
    Write-Warn2 'Symlinks unavailable (dry run: not fixing).'
} else {
    Write-Warn2 'Symlinks require Administrator rights or Developer Mode.'
    if (Confirm-Action 'Enable Developer Mode now (needs admin/UAC)?' $true) {
        $cmd = 'New-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock" -Force | Out-Null; ' +
               'New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock" ' +
               '-Name AllowDevelopmentWithoutDevLicense -PropertyType DWord -Value 1 -Force | Out-Null'
        Invoke-Elevated $cmd 'Windows Developer Mode' | Out-Null
        if (Test-SymlinkSupport) {
            Write-Ok 'Developer Mode enabled; symlinks now work.'
        } else {
            Write-Warn2 'Still cannot create symlinks. Sign out and back in, then re-run this script.'
        }
    } else {
        Write-Warn2 'Without symlinks, stow will create copies instead of links.'
    }
}

Install-Stow

$selected = Select-Packages
Invoke-Stow -Selected $selected

$emacsBin = $null
if ($DryRun) {
    Write-Step 'Emacs / Doom'
    Write-Info 'Dry run: would offer to install Emacs + Doom Emacs.'
    $emacsBin = Find-EmacsBin
    if ($emacsBin) { Write-Ok "Found Emacs at $emacsBin" }
} else {
    $emacsBin = Install-Emacs
    Install-Doom -EmacsBin $emacsBin
}

if ($emacsBin -and -not $DryRun) {
    Add-UserPath (Join-Path $UserHome 'bin')
}

Register-EmacsDaemon -EmacsBin $emacsBin
Install-Shortcuts -EmacsBin $emacsBin

Write-Host ''
Write-Host 'Done.' -ForegroundColor Green
Write-Host 'Next steps:'
Write-Host '  - Open a new terminal so PATH/HOME changes take effect.'
Write-Host '  - `emacs` (GUI), `emacsclientw -c` (new frame), `emacsclient -t` (terminal frame).'
Write-Host '  - `doom sync` after editing ~/.config/doom.'
Write-Host '  - Fonts: this config expects "SF Mono" and "JetBrainsMono Nerd Font Mono".'
