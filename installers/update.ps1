#requires -Version 5.1
[CmdletBinding()]
param([string]$InstallRoot='C:\Program Files\GSCS',[string]$DataRoot='C:\ProgramData\GSCS',[switch]$Latest)
$ErrorActionPreference='Stop'
$identity=New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if(-not $identity.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)){throw 'Das Update als Administrator starten.'}
$binary=Join-Path $InstallRoot 'current\GSCS.exe'
if($Latest){& $binary --stage-latest-update --data-root $DataRoot;if($LASTEXITCODE -ne 0){throw 'Update konnte nicht vorbereitet werden.'}}
if(-not(Test-Path -LiteralPath (Join-Path $DataRoot 'update-plan.json'))){Write-Host 'Kein vorbereitetes Update.';exit 0}
$helper=& $binary --copy-update-helper --data-root $DataRoot
if($LASTEXITCODE -ne 0 -or -not(Test-Path -LiteralPath $helper)){throw 'Signierter Updatehelfer konnte nicht vorbereitet werden.'}
& $helper --apply-update --data-root $DataRoot
if($LASTEXITCODE -ne 0){throw 'Das Update wurde abgebrochen. Vorherige Version und Datenbank wurden soweit möglich wiederhergestellt; Dienststatus prüfen.'}
