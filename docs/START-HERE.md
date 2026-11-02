# GSCS 0.1.0-alpha.1

Diese Alpha enthält die ausführbare Verwaltung für Windows und Linux. Ein .NET-SDK wird nicht benötigt. Der Funktionsstand steht in FEATURES.md.

## Windows: direkt starten

1. Das **master-win-x64.zip** vollständig in einen lokalen Ordner entpacken.
2. **start-master.cmd** starten und auswählen, ob Gameserver lokal ausgeführt werden sollen.
3. **http://127.0.0.1:5080** öffnen. Mit dem angezeigten Einrichtungscode den Administrator anlegen.

Die portable Installation verwendet eine mitgelieferte SQLite-Datenbank. Daten und Konfiguration liegen unter **%LOCALAPPDATA%\GSCS**. Der Lizenzcode wird im Webinterface unter **Systemeinstellungen > Lizenz** eingetragen. Ohne Lizenz ist ein eigener Gameserver auf localhost möglich.

## Linux: direkt starten

Das Master-Paket für x64 oder ARM64 entpacken und **bash start-master.sh** ausführen. Die Daten liegen standardmäßig unter **~/.local/share/gscs**. `GSCS_DATA` legt einen anderen Datenordner fest. Mit `GSCS_URL=http://0.0.0.0:5080` lässt sich die Bindeadresse vor der Ersteinrichtung ändern. Für öffentlichen Zugriff HTTPS über einen Reverse-Proxy einrichten.

SteamCMD-Spiele benötigen einen x64-Node. Wine/Proton und WSL müssen auf dem jeweiligen Node eingerichtet sein; ihre Spielkompatibilität ist nicht pauschal garantiert.

## Installation als Dienst mit PostgreSQL

Das separate **installers.zip** entpacken. Unter Windows **install.cmd als Administrator** starten; unter Debian/Ubuntu **sudo bash install.sh**. Der Installer fragt zuerst nach Master oder Node. Beim Master kann ausdrücklich ohne Nodes begonnen oder die lokale Spielausführung aktiviert werden.

Der Master-Installer richtet PostgreSQL ein, erzeugt zufällige Datenbankzugangsdaten und gibt sie am Ende zusammen mit dem Web-Einrichtungscode aus. Die Verbindung ist für GSCS bereits hinterlegt. Beim Linux-Installer wird eine neue Rolle und Datenbank `gscs` in PostgreSQL angelegt; vorhandene gleichnamige Daten werden nicht überschrieben.

Die Dienstinstaller sind Alpha und noch nicht auf sauberen Windows-/Debian-Referenzsystemen vollständig geprüft. Für den ersten Test sind die portablen Pakete und Docker vorgesehen.

## Docker / Unraid

Das **docker.zip** enthält Compose-Dateien, Vorbereitungsskript und das Unraid-Template. `bash prepare.sh` erzeugt geschützte Passwortdateien. Anschließend `GSCS_HOST_DATA` auf den absoluten Host-Datenpfad setzen und `docker compose up -d` ausführen. PostgreSQL wird als separater Container gestartet. Die Einrichtung geht unter **http://SERVER-IP:5080** weiter.

Der Master kann mit oder ohne lokale Spielausführung betrieben werden. Nur für die Verwaltung von Spielcontainern wird der Docker-Socket benötigt. Datenordner und Host-Pfad für Spielcontainer müssen übereinstimmen. Ohne Socket einen separaten Node verwenden.

## Node anbinden

Zuerst eine passende Lizenz auf dem Master aktivieren und im Bereich **Nodes & Laufzeiten** den Node registrieren. Das Node-Paket entpacken und **start-node.cmd** bzw. **bash start-node.sh** ausführen. Master-Adresse, Node-ID und Registrierungsschlüssel eingeben. Der Node startet ausschließlich den Agenten, ohne Webinterface und ohne Verwaltungsdatenbank.

## Spiele bereitstellen

Lokale Ausführung aktivieren oder einen erreichbaren Node anbinden. In den Systemeinstellungen TCP-/UDP-Portbereiche für diesen Node anlegen. Danach unter **Bereitstellung** eine freigegebene Vorlage auswählen und den Server erstellen.

61 eigene Profile sind enthalten: 35 sind freigegeben, 26 benötigen zusätzliche Konfiguration und anschließende Administratorfreigabe. Steam-App-IDs und Startmetadaten wurden direkt mit Valve SteamCMD abgeglichen. Das belegt keine erfolgreichen Live-Starts aller Spiele. Spielabhängige Konten, Tokens und Zusatzdateien sind gesondert nötig. Hytale hat einen geführten Gerätecode-Dialog; der offizielle Downloader besitzt eine getrennte Anmeldung.

## Updates und Sicherungen

Dienstinstallationen verwenden signierte Updatepakete. Lokale Gameserver und laufende Aufträge vor dem Update beenden. Im Webinterface nach Updates suchen, das Paket vorbereiten und die Zielversion bestätigen. Manuell: **update.ps1 -Latest** bzw. **sudo bash update.sh --latest**. Programmdateien und Datenbank werden gesichert; schlägt der Starttest fehl, versucht der Helfer die vorherige Version samt Datenbank wiederherzustellen.

Portable Installationen: GSCS stoppen, das neue Paket in einen neuen Programmordner entpacken und den unveränderten Datenordner weiterverwenden. Docker: neues Image laden und den GSCS-Container mit denselben Datenordnern neu erstellen.

Vor einem Systemwechsel einen verschlüsselten Export anlegen. Alle Server und Agents vor dem Import stoppen. Vorherige Dateien und ein Rücksicherungsarchiv bleiben erhalten. Nach einem Import GSCS neu starten und Node-Zuordnungen prüfen. Hytale-/Software-Lizenzen können auf dem Ziel eine erneute Anmeldung bzw. Aktivierung benötigen.
