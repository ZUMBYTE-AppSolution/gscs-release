# GSCS · Downloads und Installation

[Aktueller Alpha-Release](https://github.com/ZUMBYTE-AppSolution/gscs-release/releases/tag/v0.1.0-alpha.1) · [Spielvorlagen](https://github.com/ZUMBYTE-AppSolution/gscs-deployment) · [Profil-Wiki](https://github.com/ZUMBYTE-AppSolution/gscs-deployment/wiki)

GSCS verwaltet Gameserver unter Windows und Linux. Dies ist **Alpha-Software**. Der vollständige geplante Funktionsumfang ist noch nicht enthalten; [Funktionsstand](docs/FEATURES.md) und [Startanleitung](docs/START-HERE.md) beschreiben die Grenzen.

## Pakete

| Paket | Verwendung |
|---|---|
| master-win-x64.zip | Windows mit Webinterface und portabler Datenbank |
| node-win-x64.zip | Windows-Agent ohne Webinterface |
| master-linux-x64 / master-linux-arm64 | Linux mit Webinterface; ZIP und TAR.GZ |
| node-linux-x64 / node-linux-arm64 | Linux-Agent; ZIP und TAR.GZ |
| installers.zip | Windows-/Debian-/Ubuntu-Dienstinstaller, PostgreSQL und Updatehelfer |
| docker.zip | Compose, Passwortvorbereitung und Unraid-Template |

Alle Anwendungspakete enthalten die benötigte .NET-Laufzeit. Ein SDK ist nicht erforderlich. Master starten mit **start-master.cmd** bzw. **bash start-master.sh**. Die weitere Einrichtung erfolgt im Webinterface. Installer fragen nach Master/Node und lokaler Spielausführung. PostgreSQL-Zugangsdaten werden zufällig erzeugt, bereits hinterlegt und am Ende angezeigt. Nodes benötigen keine Verwaltungsdatenbank.

Die Dienstinstaller sowie deren Update-/Rollback-Abläufe sind in dieser Alpha noch nicht auf allen sauberen Referenzsystemen geprüft. Für den ersten Test sind die portablen Pakete und Docker vorgesehen. SteamCMD-Spiele benötigen x64.

## Docker und Unraid

Die Docker-Images werden als Download-Dateien für x64 und ARM64 verteilt. Eine Anmeldung an einer Container-Registry ist nicht erforderlich. Die Image-Namen im Compose-Paket werden durch `docker load` lokal bereitgestellt.

Das Docker-Bundle entpacken, zuerst **bash load-images.sh** und danach **bash prepare.sh** ausführen, in **.env** den absoluten Datenpfad festlegen und **docker compose up -d** starten. PostgreSQL läuft separat. Unter **http://SERVER-IP:5080** die Einrichtung mit dem angezeigten Code fortsetzen.

Für Unraid das [Template](docker/unraid/gscs.xml) verwenden. PostgreSQL sowie die beiden Secret-Dateien müssen vorhanden sein. Das Vorbereitungsskript im Docker-Bundle erzeugt die Dateien. Der Docker-Socket wird für die Verwaltung von Spielcontainern benötigt und gewährt dem Panel Hostrechte. Alternativ Master ohne Socket mit separatem Node betreiben.

## Vorlagen und Lizenz

61 eigene Vorlagen sind enthalten. 35 sind freigegeben, 26 benötigen zusätzliche Konfiguration und anschließende Freigabe. Für eigene Definitionen gibt es einen Wizard, einen JSON-Editor und das [Wiki](https://github.com/ZUMBYTE-AppSolution/gscs-deployment/wiki). SteamCMD-App- und Startmetadaten sind abgeglichen; erfolgreiche Live-Starts aller Spiele werden damit nicht behauptet.

Ohne Lizenz ist ein eigener Gameserver auf localhost möglich. Den Lizenzcode im Webinterface unter **Systemeinstellungen > Lizenz** hinterlegen. [Tarife](https://zumbyte.de/licenses/).

## Signaturen und Updates

Release- und Laufzeitmanifeste sind mit RSA/SHA-256 signiert. [Öffentlicher Prüfschlüssel](release-public.pem). Beispielsweise mit OpenSSL:

```sh
openssl dgst -sha256 -verify release-public.pem -signature gscs-manifest.sig gscs-manifest.json
```

Dienstinstallationen können Updates im Webinterface vorbereiten und übernehmen. Vorher alle Gameserver und Aufträge beenden. Portable Installationen durch ein neu entpacktes Paket mit demselben Datenordner aktualisieren; Docker durch ein neues Image mit denselben Datenordnern. Vor Versions- oder Systemwechseln einen verschlüsselten Systemexport und eine externe Datensicherung anlegen.

Spielnamen, Logos und Spielserver gehören ihren jeweiligen Rechteinhabern. Es werden keine proprietären Spielserverdateien verteilt. GSCS wird unter einer Nutzungslizenz angeboten; dieses Repository enthält Download- und Installationsmaterial.
