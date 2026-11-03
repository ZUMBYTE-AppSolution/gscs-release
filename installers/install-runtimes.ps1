#requires -Version 5.1
[CmdletBinding()]
param([Parameter(Mandatory=$true)][string]$InstallRoot,[Parameter(Mandatory=$true)][string]$DataRoot,[string]$InstallerDirectory=$PSScriptRoot)
$ErrorActionPreference='Stop'
[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12
$work=Join-Path $DataRoot 'runtime-installation';New-Item -ItemType Directory -Path $work -Force|Out-Null
foreach($architecture in @('x64','x86')){
 $file=Join-Path $work ('vc_redist.'+$architecture+'.exe')
 Invoke-WebRequest -UseBasicParsing -Uri ('https://aka.ms/vs/17/release/vc_redist.'+$architecture+'.exe') -OutFile $file
 $signature=Get-AuthenticodeSignature -LiteralPath $file
 if($signature.Status -ne 'Valid' -or $signature.SignerCertificate.Subject -notmatch 'Microsoft Corporation'){throw 'Die Microsoft-Laufzeit ist nicht gültig signiert.'}
 $process=Start-Process -FilePath $file -ArgumentList @('/install','/quiet','/norestart') -WindowStyle Hidden -PassThru -Wait
 if($process.ExitCode -notin @(0,1638,3010)){throw ('Visual C++ Runtime Installation fehlgeschlagen: '+$process.ExitCode)}
}
foreach($major in @(8,9,10)){
 $metadata=Invoke-RestMethod -UseBasicParsing -Uri ('https://builds.dotnet.microsoft.com/dotnet/release-metadata/'+$major+'.0/releases.json')
 $release=$metadata.releases|Where-Object {$_.runtime.version -eq $metadata.'latest-runtime'}|Select-Object -First 1
 $asset=$release.runtime.files|Where-Object {$_.rid -eq 'win-x64' -and $_.name -like 'dotnet-runtime-*.exe'}|Select-Object -First 1
 if(-not $asset.url.StartsWith('https://builds.dotnet.microsoft.com/') -or $asset.hash -notmatch '^[a-fA-F0-9]{128}$'){throw 'Ungültige .NET-Laufzeitdaten.'}
 $file=Join-Path $work ('dotnet-runtime-'+$major+'.exe');Invoke-WebRequest -UseBasicParsing -Uri $asset.url -OutFile $file
 if((Get-FileHash -LiteralPath $file -Algorithm SHA512).Hash -ne $asset.hash){throw '.NET-Prüfsumme stimmt nicht.'}
 $signature=Get-AuthenticodeSignature -LiteralPath $file
 if($signature.Status -ne 'Valid' -or $signature.SignerCertificate.Subject -notmatch 'Microsoft Corporation'){throw 'Die .NET-Laufzeit ist nicht gültig signiert.'}
 $process=Start-Process -FilePath $file -ArgumentList @('/install','/quiet','/norestart') -WindowStyle Hidden -PassThru -Wait
 if($process.ExitCode -notin @(0,1638,3010)){throw ('.NET Runtime Installation fehlgeschlagen: '+$process.ExitCode)}
}
$pending=$false
foreach($feature in @('VirtualMachinePlatform','Microsoft-Windows-Subsystem-Linux')){
 $state=Get-WindowsOptionalFeature -Online -FeatureName $feature
 if($state.State -ne 'Enabled'){$result=Enable-WindowsOptionalFeature -Online -FeatureName $feature -All -NoRestart;$pending=$pending -or $result.RestartNeeded}
}
$helper=Join-Path $InstallRoot 'configure-wsl.ps1';Copy-Item -LiteralPath (Join-Path $InstallerDirectory 'configure-wsl.ps1') -Destination $helper -Force
$action=New-ScheduledTaskAction -Execute 'powershell.exe' -Argument ('-NoProfile -NonInteractive -ExecutionPolicy Bypass -File "'+$helper+'" -DataRoot "'+$DataRoot+'"')
$principal=New-ScheduledTaskPrincipal -UserId 'SYSTEM' -LogonType ServiceAccount -RunLevel Highest
$trigger=New-ScheduledTaskTrigger -AtStartup
$settings=New-ScheduledTaskSettingsSet -ExecutionTimeLimit (New-TimeSpan -Hours 2) -RestartCount 3 -RestartInterval (New-TimeSpan -Minutes 5) -StartWhenAvailable
Register-ScheduledTask -TaskName 'GSCS-Linux-Runtime' -Action $action -Principal $principal -Trigger $trigger -Settings $settings -Force|Out-Null
if(-not $pending){Start-ScheduledTask -TaskName 'GSCS-Linux-Runtime'}
if($pending){Write-Host 'Linux-Laufzeit vorbereitet. Nach dem nächsten Windows-Neustart wird die WSL-Umgebung automatisch fertig eingerichtet.'}else{Write-Host 'Linux-Laufzeit wird im Hintergrund für das GSCS-Dienstkonto eingerichtet.'}
