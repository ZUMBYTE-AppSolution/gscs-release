#requires -Version 5.1
[CmdletBinding()]
param([Parameter(Mandatory=$true)][string]$DataRoot)
$ErrorActionPreference='Stop'
$marker=Join-Path $DataRoot 'wsl-runtime.json'
if(Test-Path -LiteralPath $marker){Disable-ScheduledTask -TaskName 'GSCS-Linux-Runtime'|Out-Null;exit 0}
$log=Join-Path $DataRoot 'wsl-runtime.log'
# WSL distributions belong to a Windows account. Provision under SYSTEM, which also runs the GSCS service.
& wsl.exe --install --no-distribution --web-download *>> $log
if($LASTEXITCODE -notin @(0,3010)){throw 'WSL benötigt einen Neustart oder eine unterstützte Windows-Version. Details: wsl-runtime.log'}
$distributions=(& wsl.exe --list --quiet 2>$null)-replace "`0",''
if($distributions -notcontains 'GSCS-Linux'){
 $catalog=Invoke-RestMethod -UseBasicParsing -Uri 'https://raw.githubusercontent.com/microsoft/WSL/master/distributions/DistributionInfo.json'
 $distribution=$catalog.ModernDistributions.Ubuntu|Where-Object Name -eq 'Ubuntu-24.04'|Select-Object -First 1
 $download=$distribution.Amd64Url
 if(-not $download.Url.StartsWith('https://releases.ubuntu.com/') -or $download.Sha256 -notmatch '^[a-fA-F0-9]{64}$'){throw 'Ungültige Ubuntu-Distributionsdaten.'}
 $image=Join-Path $DataRoot 'runtime-installation/ubuntu.wsl'
 Invoke-WebRequest -UseBasicParsing -Uri $download.Url -OutFile $image
 if((Get-FileHash -LiteralPath $image -Algorithm SHA256).Hash -ne $download.Sha256){throw 'Ubuntu-Prüfsumme stimmt nicht.'}
 & wsl.exe --import GSCS-Linux (Join-Path $DataRoot 'wsl') $image --version 2 *>> $log
 if($LASTEXITCODE -ne 0){throw 'GSCS-Linux konnte noch nicht eingerichtet werden.'}
}
$command='set -e; export DEBIAN_FRONTEND=noninteractive; apt-get update -qq; apt-get install -y --no-install-recommends ca-certificates curl tar xz-utils unzip lib32gcc-s1 lib32stdc++6 libatomic1 libpulse0 libsdl2-2.0-0 jq mono-runtime libgdiplus; install -d -m 0755 /opt/gscs-java; for version in 17 21 25;do if [ ! -x /opt/gscs-java/$version/bin/java ];then mkdir -p /opt/gscs-java/$version; curl -fLsS --retry 3 https://api.adoptium.net/v3/binary/latest/$version/ga/linux/x64/jre/hotspot/normal/eclipse -o /tmp/gscs-java-$version.tar.gz; tar -xzf /tmp/gscs-java-$version.tar.gz --strip-components=1 -C /opt/gscs-java/$version; rm -- /tmp/gscs-java-$version.tar.gz;fi;done; ln -sf /opt/gscs-java/25/bin/java /usr/local/bin/java'
& wsl.exe --distribution GSCS-Linux --user root --exec /bin/bash -c $command *>> $log
if($LASTEXITCODE -ne 0){throw 'Linux-Java-Laufzeiten konnten noch nicht installiert werden.'}
$command=@'
set -euo pipefail
mkdir -p /opt/gscs-dotnet
for major in 8 9 10;do
 metadata=$(mktemp)
 curl -fLsS --retry 3 "https://builds.dotnet.microsoft.com/dotnet/release-metadata/$major.0/releases.json" -o "$metadata"
 version=$(jq -r '.["latest-runtime"]' "$metadata")
 asset=$(jq -c --arg version "$version" '.releases[]|select(.runtime.version==$version)|.runtime.files[]|select(.rid=="linux-x64" and (.name|startswith("dotnet-runtime-")) and (.name|endswith(".tar.gz")))' "$metadata" | head -n1)
 url=$(jq -r .url <<< "$asset");hash=$(jq -r .hash <<< "$asset")
 [[ $url == https://builds.dotnet.microsoft.com/* && $hash =~ ^[a-fA-F0-9]{128}$ ]] || exit 2
 package=$(mktemp);curl -fLsS --retry 3 "$url" -o "$package"
 printf '%s  %s\n' "$hash" "$package" | sha512sum -c -
 tar -xzf "$package" --no-same-owner -C /opt/gscs-dotnet
 rm -- "$package" "$metadata"
done
ln -sf /opt/gscs-dotnet/dotnet /usr/local/bin/dotnet
'@
& wsl.exe --distribution GSCS-Linux --user root --exec /bin/bash -c $command *>> $log
if($LASTEXITCODE -ne 0){throw 'Linux-Laufzeiten konnten noch nicht vollständig installiert werden.'}
[IO.File]::WriteAllText($marker,(@{distribution='GSCS-Linux';account='SYSTEM';installedAt=[DateTime]::UtcNow.ToString('o')}|ConvertTo-Json),(New-Object Text.UTF8Encoding($false)))
Disable-ScheduledTask -TaskName 'GSCS-Linux-Runtime'|Out-Null
