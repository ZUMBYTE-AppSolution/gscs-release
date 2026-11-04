# GSCS · Downloads und Installation

[Aktueller Alpha-Release](https://github.com/ZUMBYTE-AppSolution/gscs-release/releases/tag/v0.1.0-alpha.7) · [Spielvorlagen](https://github.com/ZUMBYTE-AppSolution/gscs-deployment) · [Profil-Wiki](https://github.com/ZUMBYTE-AppSolution/gscs-deployment/wiki)

GSCS verwaltet Gameserver unter Windows und Linux. Dies ist **Alpha-Software**.  [Funktionsstand](FEATURES.md) und [Startanleitung](START-HERE.md) beschreiben die Grenzen.

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

Das gemeinsame Docker-Image wird in dieser Alpha als Download-Datei für x64 verteilt. Eine Anmeldung an einer Container-Registry ist nicht erforderlich. Die Image-Namen im Compose-Paket werden durch `docker load` lokal bereitgestellt.

**docker.zip** entpacken und **bash load-images.sh** ausführen. Anschließend mit **bash prepare.sh** Master oder Node wählen und den Container mit Compose starten. Für Unraid die enthaltene **docker/unraid/gscs.xml** als Benutzervorlage ablegen und das geladene versionierte Image verwenden. Ein gemeinsamer Container enthält den Master, PostgreSQL und die Spiel-Laufzeiten. Der Node verwendet dasselbe Image und startet nur den Agenten. Isolierte Spielcontainer verwenden ebenfalls dasselbe Image und benötigen den Docker-Socket.

Für die Kanalauswahl direkt bei **Container hinzufügen** gibt es eine Vorlage **GSCS** und die kleine Unraid-Erweiterung [GSCS Kanalwahl](../docker/unraid/gscs-channel-selector.plg). Unter **Plugins → Plugin installieren** die Raw-Adresse der `.plg` eintragen. Im Dropdown stehen Alpha, Beta und Release; noch nicht veröffentlichte Kanäle sind deaktiviert. Die Auswahl setzt Repository und Spielserver-Image gemeinsam um. Private GHCR-Kanäle benötigen einen ausdrücklich freigeschalteten GitHub-Zugang. Die versionierten öffentlichen Docker-Downloads lassen sich weiterhin ohne Registry-Anmeldung laden. [Installation und Container-Updates](UNRAID-UPDATES.md).

## Vorlagen und Lizenz

231 Profile mit kategorisierten Konfigurationsfeldern sind enthalten. Für eigene Definitionen gibt es einen Wizard, einen JSON-Editor und das [Wiki](https://github.com/ZUMBYTE-AppSolution/gscs-deployment/wiki). Erfolgreiche Live-Starts aller Spiele werden damit nicht behauptet.

Ohne Lizenz ist ein eigener Gameserver auf localhost möglich. Kostenpflichtige Lizenzen sind derzeit nicht erhältlich. Bei der Ersteinrichtung kannst du über ein registriertes Zumbyte-Konto eine kostenlose 90-Tage-Testlizenz mit unbegrenzten Gameservern, Nodes und Hosting-Kunden aktivieren. Die bestätigte E-Mail-Adresse und die Hardware werden zugeordnet. Während der Alpha lässt sich dieselbe Testlizenz kostenlos jeweils für 90 Tage ab der Verlängerung erneuern. Es entsteht kein kostenpflichtiges Abo. Vorhandene Codes werden zusammen mit der E-Mail-Adresse unter **Systemeinstellungen > Lizenz** hinterlegt. [Testlizenz und Tarife](https://zumbyte.de/licenses/).

## Signaturen und Updates

Release- und Laufzeitmanifeste sind mit RSA/SHA-256 signiert. [Öffentlicher Prüfschlüssel](../release-public.pem). Beispielsweise mit OpenSSL:

```sh
openssl dgst -sha256 -verify release-public.pem -signature gscs-manifest.sig gscs-manifest.json
```

Dienstinstallationen können Updates im Webinterface vorbereiten und übernehmen. Vorher alle Gameserver und Aufträge beenden. Portable Installationen durch ein neu entpacktes Paket mit demselben Datenordner aktualisieren; Docker durch ein neues Image mit denselben Datenordnern. Vor Versions- oder Systemwechseln einen verschlüsselten Systemexport und eine externe Datensicherung anlegen.

Spielnamen, Logos und Spielserver gehören ihren jeweiligen Rechteinhabern. Es werden keine proprietären Spielserverdateien verteilt. GSCS wird unter einer Nutzungslizenz angeboten; dieses Repository enthält Download- und Installationsmaterial.

Unter Unraid für Spieldateien einen direkten Pool-/Datenträgerpfad verwenden, etwa **/mnt/cache/appdata/gscs** oder **/mnt/disk1/appdata/gscs**. Ältere 32-Bit-Spiele können über **/mnt/user** wegen der Dateisystem-Inodes fehlschlagen. Datenpfad und Host-Datenpfad im Unraid-Template müssen übereinstimmen.
