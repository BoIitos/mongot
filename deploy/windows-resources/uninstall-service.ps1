#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Stops and removes the Windows service "mongot".

.DESCRIPTION
    Configuration, index data and logs in %ProgramData%\mongot are left untouched.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

$ServiceExe = Join-Path $PSScriptRoot 'mongot-service.exe'
if (-not (Test-Path -LiteralPath $ServiceExe)) {
    throw "Service wrapper not found: $ServiceExe"
}

$service = Get-Service -Name 'mongot' -ErrorAction SilentlyContinue
if ($null -eq $service) {
    Write-Host "Service 'mongot' is not installed."
    return
}

if ($service.Status -ne 'Stopped') {
    & $ServiceExe stop
    $service.WaitForStatus('Stopped', [TimeSpan]::FromSeconds(90))
}

& $ServiceExe uninstall
if ($LASTEXITCODE -ne 0) {
    throw "mongot-service.exe uninstall failed with exit code $LASTEXITCODE"
}
Write-Host "Service 'mongot' removed. Data in $env:ProgramData\mongot was kept."
