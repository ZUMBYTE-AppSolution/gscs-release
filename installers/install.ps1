#requires -Version 5.1
[CmdletBinding()]
param(
 [ValidateSet('Master','Node')][string]$Role,
 [Nullable[bool]]$LocalNode=$null,
 [string]$InstallRoot='C:\Program Files\GSCS',
 [string]$DataRoot='C:\ProgramData\GSCS',
 [string]$Package,
 [string]$PackageSha256,
 [int]$DatabasePort=5433,
 [string]$MasterUrl,
 [string]$NodeId,
 [string]$AgentKeyFile,
 [string]$ListenUrl='http://127.0.0.1:5080',
 [string]$InstallerDirectory=$PSScriptRoot,
 [switch]$NonInteractive
)
$ErrorActionPreference='Stop'
if(-not $InstallerDirectory -and $env:GSCS_INSTALL_SCRIPT){$InstallerDirectory=[IO.Path]::GetDirectoryName($env:GSCS_INSTALL_SCRIPT)}
if(-not $InstallerDirectory){throw 'Installerverzeichnis fehlt.'}
[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12
$repository='ZUMBYTE-AppSolution/gscs-release'
$pgVersion='18.6-5'
$pgHash='227e2bc08091b4c2b8338c7d61b11d057f895711480b006f90bfcfcd2410a58a'
function Random-Secret { $bytes=New-Object byte[] 36; $rng=[Security.Cryptography.RandomNumberGenerator]::Create(); try{$rng.GetBytes($bytes)}finally{$rng.Dispose()}; return [Convert]::ToBase64String($bytes).TrimEnd('=').Replace('+','-').Replace('/','_') }
function Hash-Text([string]$Value){$sha=[Security.Cryptography.SHA256]::Create();try{return ([BitConverter]::ToString($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($Value)))).Replace('-','')}finally{$sha.Dispose()}}
function Write-Utf8([string]$Path,[string]$Value){[IO.File]::WriteAllText($Path,$Value,(New-Object Text.UTF8Encoding($false)))}
function Protect-Directory([string]$Path){New-Item -ItemType Directory -Force -Path $Path | Out-Null;$acl=New-Object Security.AccessControl.DirectorySecurity;$acl.SetAccessRuleProtection($true,$false);foreach($sid in @('S-1-5-18','S-1-5-32-544')){$identity=New-Object Security.Principal.SecurityIdentifier($sid);$rule=New-Object Security.AccessControl.FileSystemAccessRule($identity,'FullControl','ContainerInherit,ObjectInherit','None','Allow');$acl.AddAccessRule($rule)};Set-Acl -LiteralPath $Path -AclObject $acl}
function Require-Success([int]$Code,[string]$Step){if($Code -ne 0){throw ($Step+' fehlgeschlagen (Exit '+$Code+'). Bestehende Daten bleiben erhalten.')}}
function Expand-Safe([string]$File,[string]$Destination){Add-Type -AssemblyName System.IO.Compression.FileSystem;$root=[IO.Path]::GetFullPath($Destination).TrimEnd('\')+'\';New-Item -ItemType Directory -Force -Path $Destination|Out-Null;$zip=[IO.Compression.ZipFile]::OpenRead($File);try{foreach($entry in $zip.Entries){$target=[IO.Path]::GetFullPath((Join-Path $Destination $entry.FullName));if(-not $target.StartsWith($root,[StringComparison]::OrdinalIgnoreCase)){throw 'Unzulaessiger Archivpfad'};if((($entry.ExternalAttributes -shr 16) -band 0xf000) -eq 0xa000){throw 'Symbolischer Link im Installationspaket'};if($entry.FullName.EndsWith('/')){New-Item -ItemType Directory -Force -Path $target|Out-Null;continue};New-Item -ItemType Directory -Force -Path ([IO.Path]::GetDirectoryName($target))|Out-Null;[IO.Compression.ZipFileExtensions]::ExtractToFile($entry,$target,$true)}}finally{$zip.Dispose()}}
function Download-Package([string]$TargetRole,[string]$Destination){
 $release=Invoke-RestMethod -UseBasicParsing -Uri ('https://api.github.com/repos/'+$repository+'/releases?per_page=20') -Headers @{'User-Agent'='GSCS-Installer'}
 $release=$release|Where-Object {-not $_.draft}|Select-Object -First 1
 $manifestAsset=$release.assets|Where-Object name -eq 'gscs-manifest.json'|Select-Object -First 1;$signatureAsset=$release.assets|Where-Object name -eq 'gscs-manifest.sig'|Select-Object -First 1
 if(-not $manifestAsset -or -not $signatureAsset){throw 'Signiertes Releasemanifest fehlt.'}
 $manifestPath=Join-Path $Destination 'manifest.json';$signaturePath=Join-Path $Destination 'manifest.sig'
 Invoke-WebRequest -UseBasicParsing -Uri $manifestAsset.browser_download_url -OutFile $manifestPath
 Invoke-WebRequest -UseBasicParsing -Uri $signatureAsset.browser_download_url -OutFile $signaturePath
 $keyPath=Join-Path $InstallerDirectory 'release-public.json';if(-not(Test-Path -LiteralPath $keyPath)){Invoke-WebRequest -UseBasicParsing -Uri ('https://raw.githubusercontent.com/'+$repository+'/main/release-public.json') -OutFile (Join-Path $Destination 'release-public.json');$keyPath=Join-Path $Destination 'release-public.json'}
 $key=Get-Content -LiteralPath $keyPath -Raw|ConvertFrom-Json;$parameters=New-Object Security.Cryptography.RSAParameters;$parameters.Modulus=[Convert]::FromBase64String($key.modulus);$parameters.Exponent=[Convert]::FromBase64String($key.exponent);$rsa=New-Object Security.Cryptography.RSACryptoServiceProvider
 try{$rsa.ImportParameters($parameters);if(-not $rsa.VerifyData([IO.File]::ReadAllBytes($manifestPath),'SHA256',[IO.File]::ReadAllBytes($signaturePath))){throw 'Release-Signatur ungueltig.'}}finally{$rsa.Dispose()}
 $manifest=Get-Content -LiteralPath $manifestPath -Raw|ConvertFrom-Json;$asset=$manifest.packages|Where-Object {$_.role -eq $TargetRole -and $_.rid -eq 'win-x64'}|Select-Object -First 1
 if(-not $asset){throw 'Kein passendes Windows-Paket vorhanden.'};if(-not $asset.url.StartsWith('https://github.com/'+$repository+'/releases/download/')){throw 'Unzulaessige Paketquelle.'}
 $path=Join-Path $Destination 'package.zip';Invoke-WebRequest -UseBasicParsing -Uri $asset.url -OutFile $path
 if((Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash -ne $asset.sha256){throw 'Paketpruefsumme stimmt nicht.'};return $path
}
function Invoke-Psql([string]$Executable,[string]$Passfile,[string]$Sql){$info=New-Object Diagnostics.ProcessStartInfo;$info.FileName=$Executable;$info.Arguments='-h 127.0.0.1 -p '+$DatabasePort+' -U postgres -d postgres -X -v ON_ERROR_STOP=1';$info.UseShellExecute=$false;$info.CreateNoWindow=$true;$info.RedirectStandardInput=$true;$info.RedirectStandardOutput=$true;$info.RedirectStandardError=$true;$info.EnvironmentVariables['PGPASSFILE']=$Passfile;$process=[Diagnostics.Process]::Start($info);$process.StandardInput.WriteLine($Sql);$process.StandardInput.Close();$out=$process.StandardOutput.ReadToEnd();$err=$process.StandardError.ReadToEnd();$process.WaitForExit();Require-Success $process.ExitCode 'Datenbankeinrichtung';$process.Dispose()}

$principal=New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if(-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)){throw 'Den Installer als Administrator starten.'}
if(-not [Environment]::Is64BitOperatingSystem){throw 'Windows x64 wird benoetigt.'}
if(-not $Role){if($NonInteractive){throw '-Role Master oder -Role Node angeben.'};Write-Host 'GSCS installieren';Write-Host '1 Masterserver (Webinterface + Datenbank)';Write-Host '2 Node (nur Agent, kein Panel, keine Verwaltungsdatenbank)';$choice=Read-Host 'Rolle';if($choice -eq '1'){$Role='Master'}elseif($choice -eq '2'){$Role='Node'}else{throw 'Rolle ungueltig.'}}
if($Role -eq 'Master' -and $null -eq $LocalNode){if($NonInteractive){throw '-LocalNode $true oder -LocalNode $false explizit angeben.'};Write-Host '0 Vorerst ohne Nodes';Write-Host '1 Auch lokale Spielausfuehrung';Write-Host '2 Zunaechst nur Master, Remote-Nodes spaeter im Webinterface';Write-Host '3 Lokale Ausfuehrung und spaeter Remote-Nodes';$choice=Read-Host 'Node-Plan [0]';$LocalNode=$choice -in @('1','3')}
if($DatabasePort -lt 1024 -or $DatabasePort -gt 65535){throw 'Datenbankport ungueltig.'}
$InstallRoot=[IO.Path]::GetFullPath($InstallRoot);$DataRoot=[IO.Path]::GetFullPath($DataRoot)
if($InstallRoot.StartsWith('\\') -or $DataRoot.StartsWith('\\')){throw 'Fuer Dienste lokale Laufwerke verwenden; keine SMB-Freigabe.'}
if(Test-Path -LiteralPath (Join-Path $DataRoot 'bootstrap.json')){throw 'Eine Installation ist bereits konfiguriert. Die Updatefunktion verwenden; Zugangsdaten werden nicht ueberschrieben.'}
Protect-Directory $DataRoot;$work=Join-Path $DataRoot ('installation-'+[Guid]::NewGuid().ToString('N'));Protect-Directory $work
$current=Join-Path $InstallRoot 'current';New-Item -ItemType Directory -Force -Path $InstallRoot|Out-Null
if($Package){$Package=[IO.Path]::GetFullPath($Package);if(-not $PackageSha256){throw 'Fuer ein lokales Paket -PackageSha256 aus dem signierten Manifest angeben.'};if((Get-FileHash -LiteralPath $Package -Algorithm SHA256).Hash -ne $PackageSha256){throw 'Paketpruefsumme stimmt nicht.'}}else{$Package=Download-Package $Role.ToLowerInvariant() $work}
Expand-Safe $Package $current
$masterKey=Random-Secret;$masterBytes=New-Object byte[] 32;$rng=[Security.Cryptography.RandomNumberGenerator]::Create();$rng.GetBytes($masterBytes);$rng.Dispose();$masterKey=[Convert]::ToBase64String($masterBytes)
$bootstrap=@{provider='None';connectionString='';masterKey=$masterKey;setupTokenHash='';role=$Role.ToLowerInvariant();enableLocalNode=$false;dataRoot=$DataRoot;installRoot=$InstallRoot;serviceName=$(if($Role -eq 'Master'){'GSCS'}else{'GSCS-Node'});listenUrl=$ListenUrl;controllerUrl='';nodeId='';agentKey=''}
$credentials=@()
if($Role -eq 'Node'){
 if(-not $MasterUrl){if($NonInteractive){throw '-MasterUrl fehlt.'};$MasterUrl=Read-Host 'HTTPS-Adresse des Masters'}
 $master=[Uri]$MasterUrl;if($master.Scheme -ne 'https' -and -not $master.IsLoopback){throw 'Der Node benoetigt eine HTTPS-Verbindung zum Master.'}
 if(-not $NodeId){if($NonInteractive){throw '-NodeId fehlt.'};$NodeId=Read-Host 'Node-ID aus dem Webinterface'}
 if($AgentKeyFile){$agentKey=[IO.File]::ReadAllText([IO.Path]::GetFullPath($AgentKeyFile)).Trim()}else{if($NonInteractive){throw '-AgentKeyFile fehlt.'};$secure=Read-Host 'Registrierungsschluessel aus dem Webinterface' -AsSecureString;$pointer=[Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure);try{$agentKey=[Runtime.InteropServices.Marshal]::PtrToStringBSTR($pointer)}finally{[Runtime.InteropServices.Marshal]::ZeroFreeBSTR($pointer)}}
 if($NodeId -notmatch '^[a-zA-Z0-9_-]{1,100}$' -or $agentKey.Length -lt 24){throw 'Node-ID oder Registrierungsschluessel ungueltig.'}
 $bootstrap.controllerUrl=$master.AbsoluteUri;$bootstrap.nodeId=$NodeId;$bootstrap.agentKey=$agentKey
}else{
 Write-Host 'PostgreSQL wird als eigener GSCS-Dienst eingerichtet. Bestehende PostgreSQL-Instanzen bleiben erhalten.'
 if(Get-Service -Name 'GSCS-PostgreSQL' -ErrorAction SilentlyContinue){throw 'GSCS-PostgreSQL ist bereits vorhanden. Keine automatische Neuinitialisierung.'}
 if(Get-LocalUser -Name 'gscs-postgres' -ErrorAction SilentlyContinue){throw 'Das Dienstkonto gscs-postgres existiert bereits. Kein vorhandenes Konto wird uebernommen.'}
 $listener=New-Object Net.Sockets.TcpListener([Net.IPAddress]::Loopback,$DatabasePort);try{$listener.Start()}finally{$listener.Stop()}
 $pgInstaller=Join-Path $work 'postgresql.exe';Invoke-WebRequest -UseBasicParsing -Uri ('https://get.enterprisedb.com/postgresql/postgresql-'+$pgVersion+'-windows-x64.exe') -OutFile $pgInstaller
 if((Get-FileHash -LiteralPath $pgInstaller -Algorithm SHA256).Hash.ToLowerInvariant() -ne $pgHash){throw 'PostgreSQL-Pruefsumme stimmt nicht.'}
 $signature=Get-AuthenticodeSignature -LiteralPath $pgInstaller;if($signature.Status -ne 'Valid' -or $signature.SignerCertificate.Subject -notmatch 'EnterpriseDB'){throw 'PostgreSQL-Herstellersignatur konnte nicht bestaetigt werden.'}
 $pgRoot=Join-Path $InstallRoot 'PostgreSQL';$pgData=Join-Path $DataRoot 'PostgreSQL';$rootPassword=Random-Secret;$dbPassword=Random-Secret;$servicePassword=Random-Secret;$setupToken=Random-Secret
 $options=Join-Path $work 'postgres-options.ini';$optionText="prefix=$pgRoot`ndatadir=$pgData`nserverport=$DatabasePort`nservicename=GSCS-PostgreSQL`nsuperaccount=postgres`nsuperpassword=$rootPassword`nserviceaccount=gscs-postgres`nservicepassword=$servicePassword`nenable-components=server,commandlinetools`ndisable-components=pgAdmin,stackbuilder`ncreate_shortcuts=0`ndebuglevel=0`n"
 try{Write-Utf8 $options $optionText;$installation=Start-Process -FilePath $pgInstaller -ArgumentList @('--mode','unattended','--unattendedmodeui','none','--optionfile',('"'+$options+'"')) -WindowStyle Hidden -PassThru -Wait;Require-Success $installation.ExitCode 'PostgreSQL-Installation'}finally{if(Test-Path -LiteralPath $options){Remove-Item -LiteralPath $options -Force}}
 $postgresUser=Get-LocalUser -Name 'gscs-postgres';$dataAcl=Get-Acl -LiteralPath $DataRoot;$dataAcl.AddAccessRule((New-Object Security.AccessControl.FileSystemAccessRule($postgresUser.SID,'ReadAndExecute','None','None','Allow')));Set-Acl -LiteralPath $DataRoot -AclObject $dataAcl
 Add-Content -LiteralPath (Join-Path $pgData 'postgresql.conf') -Value "`n# GSCS: database only on loopback`nlisten_addresses = '127.0.0.1,::1'" -Encoding Ascii
 Restart-Service -Name 'GSCS-PostgreSQL';$pass=Join-Path $work 'pgpass';try{Write-Utf8 $pass ('127.0.0.1:'+$DatabasePort+':*:postgres:'+$rootPassword+"`n");$psql=Join-Path $pgRoot 'bin\psql.exe';Invoke-Psql $psql $pass ("SET log_statement='none'; SET log_min_error_statement='panic'; CREATE ROLE gscs LOGIN PASSWORD '"+$dbPassword+"';");Invoke-Psql $psql $pass 'CREATE DATABASE gscs OWNER gscs;'}finally{if(Test-Path -LiteralPath $pass){Remove-Item -LiteralPath $pass -Force}}
 $bootstrap.provider='PostgreSQL';$bootstrap.connectionString='Host=127.0.0.1;Port='+$DatabasePort+';Database=gscs;Username=gscs;Password='+$dbPassword+';Include Error Detail=false';$bootstrap.setupTokenHash=Hash-Text $setupToken;$bootstrap.enableLocalNode=[bool]$LocalNode
 $credentials=@('Panel: '+$ListenUrl,'Einmaliger Web-Einrichtungscode: '+$setupToken,'DB-Host: 127.0.0.1','DB-Port: '+$DatabasePort,'Datenbank: gscs','DB-Benutzer: gscs','DB-Passwort: '+$dbPassword,'PostgreSQL-Administrator postgres: '+$rootPassword,'PostgreSQL-Dienstkonto gscs-postgres: '+$servicePassword)
}
Write-Utf8 (Join-Path $DataRoot 'bootstrap.json') ($bootstrap|ConvertTo-Json -Depth 8)
$service=$bootstrap.serviceName;$binary='"'+(Join-Path $current 'GSCS.exe')+'" --data-root "'+$DataRoot+'"'
& sc.exe create $service binPath= $binary start= auto DisplayName= $service | Out-Null;Require-Success $LASTEXITCODE 'Dienstregistrierung'
if($Role -eq 'Master'){& sc.exe config $service depend= 'GSCS-PostgreSQL'|Out-Null}
& sc.exe failure $service reset= 86400 actions= restart/15000/restart/30000/restart/60000 | Out-Null
Copy-Item -LiteralPath (Join-Path $InstallerDirectory 'update.ps1') -Destination (Join-Path $InstallRoot 'update.ps1') -Force
Copy-Item -LiteralPath (Join-Path $InstallerDirectory 'release-public.json') -Destination (Join-Path $InstallRoot 'release-public.json') -Force
Start-Service -Name $service
if($Role -eq 'Master'){$ready=$false;for($attempt=0;$attempt -lt 90;$attempt++){try{$health=Invoke-RestMethod -UseBasicParsing -Uri ($ListenUrl.Replace('0.0.0.0','127.0.0.1').TrimEnd('/')+'/health');if($health.app -eq 'GSCS'){$ready=$true;break}}catch{};Start-Sleep -Seconds 1};if(-not $ready){throw 'Der Dienst wurde installiert, der Master ist aber noch nicht bereit. Ereignisprotokoll pruefen; keine Daten wurden geloescht.'}}
Write-Host '';Write-Host ('GSCS '+$Role+' installiert.');Write-Host '----------------------------------------'
if($Role -eq 'Master'){foreach($line in $credentials){Write-Host $line};Write-Host '';Write-Host 'Datenbankdaten sind geschuetzt hinterlegt. Im Webinterface den Einrichtungscode eingeben und den ersten Administrator anlegen.';Write-Host 'Fuer oeffentliche Erreichbarkeit HTTPS per Reverse-Proxy einrichten; Beispielkonfiguration liegt beim Paket.';if(-not $LocalNode){Write-Host 'Installation ohne lokale Nodes. Weitere Nodes spaeter im Webinterface registrieren.'}}else{Write-Host ('Master: '+$MasterUrl);Write-Host ('Node-ID: '+$NodeId);Write-Host 'Nur Agent installiert. Kein Webinterface und keine Verwaltungsdatenbank. Verbindungsstatus im Master pruefen.'}
Write-Host ('Konfiguration: '+(Join-Path $DataRoot 'bootstrap.json'));Write-Host 'Zugangsdaten jetzt sicher aufbewahren.'
