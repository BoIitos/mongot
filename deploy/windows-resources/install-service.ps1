#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Installs mongot as the Windows service "mongot".

.DESCRIPTION
    - Creates %ProgramData%\mongot\{data,logs,secrets} and restricts the whole directory to
      SYSTEM (the service account) and the local Administrators group.
    - Copies config.default.yml to %ProgramData%\mongot\config.yml if no config exists yet.
    - Registers the service with the bundled WinSW wrapper (mongot-service.exe + mongot-service.xml).

.PARAMETER Start
    Start the service right after installing it. Only use this once config.yml and the
    password file are in place.

.EXAMPLE
    .\install-service.ps1
    .\install-service.ps1 -Start
#>
[CmdletBinding()]
param(
    [switch]$Start
)

$ErrorActionPreference = 'Stop'

$MongotHome = $PSScriptRoot
$ServiceExe = Join-Path $MongotHome 'mongot-service.exe'
$DataRoot = Join-Path $env:ProgramData 'mongot'
$ConfigFile = Join-Path $DataRoot 'config.yml'
$PasswordFile = Join-Path $DataRoot 'secrets\passwordFile'

if (-not (Test-Path -LiteralPath $ServiceExe)) {
    throw "Service wrapper not found: $ServiceExe"
}
if (-not (Test-Path -LiteralPath (Join-Path $MongotHome 'bin\jdk\bin\java.exe'))) {
    throw "Bundled JDK not found below $MongotHome\bin\jdk"
}

foreach ($dir in @($DataRoot, "$DataRoot\data", "$DataRoot\logs", "$DataRoot\secrets")) {
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
}

# Index data and secrets: only SYSTEM (S-1-5-18) and Administrators (S-1-5-32-544).
# SIDs instead of names keep this working on localized Windows installations.
& icacls.exe $DataRoot /inheritance:r /grant:r '*S-1-5-18:(OI)(CI)F' '*S-1-5-32-544:(OI)(CI)F' /T /Q | Out-Null
if ($LASTEXITCODE -ne 0) {
    throw "icacls failed with exit code $LASTEXITCODE"
}

if (-not (Test-Path -LiteralPath $ConfigFile)) {
    Copy-Item -LiteralPath (Join-Path $MongotHome 'config.default.yml') -Destination $ConfigFile
    Write-Host "Created $ConfigFile - adjust it to your mongod deployment."
}
if (-not (Test-Path -LiteralPath $PasswordFile)) {
    Write-Warning "Password file $PasswordFile does not exist yet. Create it (password only) before starting the service."
}

& $ServiceExe install
if ($LASTEXITCODE -ne 0) {
    throw "mongot-service.exe install failed with exit code $LASTEXITCODE"
}
Write-Host "Service 'mongot' installed. Logs: $DataRoot\logs"

if ($Start) {
    & $ServiceExe start
    if ($LASTEXITCODE -ne 0) {
        throw "mongot-service.exe start failed with exit code $LASTEXITCODE"
    }
    Write-Host "Service 'mongot' started."
} else {
    Write-Host "Start it with: Start-Service mongot"
}
