# GSCS 0.1.0-alpha.8

GSCS ist Alpha-Software. Derzeit sind keine kostenpflichtigen Lizenzen erhältlich. Über ein registriertes Zumbyte-Konto mit bestätigter E-Mail-Adresse kannst du eine kostenlose 90-Tage-Testlizenz mit vollem Funktionsumfang aktivieren. Sie ist an die Hardware gebunden und während der Alpha jeweils kostenlos für 90 Tage ab der Verlängerung erneuerbar. Es entsteht kein kostenpflichtiges Abo.

Diese Alpha enthält die ausführbare Verwaltung für Windows und Linux. Ein .NET-SDK wird nicht benötigt. Der Funktionsstand steht in FEATURES.md.

## Windows: direkt starten

1. Das **master-win-x64.zip** vollständig in einen lokalen Ordner entpacken.
2. **start-master.cmd** starten und auswählen, ob Gameserver lokal ausgeführt werden sollen.
3. **http://127.0.0.1:5080** öffnen. Mit dem angezeigten Einrichtungscode den Administrator anlegen.

Die portable Installation verwendet eine mitgelieferte SQLite-Datenbank. Daten und Konfiguration liegen unter **%LOCALAPPDATA%\GSCS**. Im Webinterface kannst du direkt bei der Einrichtung eine Testlizenz freischalten oder Lizenzcode und E-Mail-Adresse unter **Systemeinstellungen > Lizenz** eintragen. Ohne Lizenz ist ein eigener Gameserver auf localhost möglich.

## Linux: direkt starten

Für eine portable Lizenzaktivierung unter Linux einmal `sudo ./GSCS --prepare-hardware` ausführen, falls GSCS die Hardwarekennung nicht direkt lesen kann. Der Dienstinstaller und das Docker-Image erledigen dies automatisch.

Das Master-Paket für x64 oder ARM64 entpacken und **bash start-master.sh** ausführen. Die Daten liegen standardmäßig unter **~/.local/share/gscs**. `GSCS_DATA` legt einen anderen Datenordner fest. Mit `GSCS_URL=http://0.0.0.0:5080` lässt sich die Bindeadresse vor der Ersteinrichtung ändern. Für öffentlichen Zugriff HTTPS über einen Reverse-Proxy einrichten.

SteamCMD-Spiele benötigen einen x64-Node. Die Dienstinstaller richten auch die Spiel- und Kompatibilitätslaufzeiten ein. Unter Windows kann WSL einen Neustart benötigen; die Einrichtung wird anschließend automatisch fortgesetzt. Bei portabler Nutzung die mitgelieferten Laufzeitinstaller verwenden.

## Installation als Dienst mit PostgreSQL

Das separate **installers.zip** entpacken. Unter Windows **install.cmd als Administrator** starten; unter Debian/Ubuntu **sudo bash install.sh**. Der Installer fragt zuerst nach Master oder Node. Beim Master kann ausdrücklich ohne Nodes begonnen oder die lokale Spielausführung aktiviert werden.

Der Master-Installer richtet PostgreSQL ein, erzeugt zufällige Datenbankzugangsdaten und gibt sie am Ende zusammen mit dem Web-Einrichtungscode aus. Die Verbindung ist für GSCS bereits hinterlegt. Beim Linux-Installer wird eine neue Rolle und Datenbank `gscs` in PostgreSQL angelegt; vorhandene gleichnamige Daten werden nicht überschrieben.

Die Dienstinstaller sind Alpha und noch nicht auf sauberen Windows-/Debian-Referenzsystemen vollständig geprüft. Für den ersten Test sind die portablen Pakete und Docker vorgesehen.

## Docker / Unraid

Das **docker-universal-linux-x64.tar.gz** herunterladen und mit `docker load --input DATEINAME.tar.gz` laden. Für die Einrichtung dienen die Compose-Datei oder das Unraid-Template aus **docker.zip**. PostgreSQL und die Spiel-Laufzeiten sind im gemeinsamen Image enthalten. Der Master fragt den Administrator und die Lizenzwahl beim ersten Aufruf des Webinterfaces ab.

Auf Unraid das geladene versionierte Image als Repository eintragen und denselben Namen bei „Spielserver-Image“ verwenden. Die privaten GHCR-Kanäle `alpha`, `beta` und `release` benötigen einen freigeschalteten GitHub-Zugang. Öffentlich steht das Docker-Downloadarchiv zur Verfügung.

Native Spiele laufen direkt im gemeinsamen Container. Für zusätzliche isolierte Spielcontainer den Docker-Socket einbinden; auch diese verwenden dasselbe GSCS-Image. Datenordner und Host-Pfad für Spielcontainer müssen übereinstimmen. Compose-Dateien und Unraid-Template liegen zusätzlich im **docker.zip**.

## Node anbinden

Zuerst eine passende Lizenz auf dem Master aktivieren und im Bereich **Nodes & Laufzeiten** den Node registrieren. Das Node-Paket entpacken und **start-node.cmd** bzw. **bash start-node.sh** ausführen. Master-Adresse, Node-ID und Registrierungsschlüssel eingeben. Der Node startet ausschließlich den Agenten, ohne Webinterface und ohne Verwaltungsdatenbank.

## Spiele bereitstellen

Lokale Ausführung aktivieren oder einen erreichbaren Node anbinden. In den Systemeinstellungen TCP-/UDP-Portbereiche für diesen Node anlegen. Danach unter **Bereitstellung** eine freigegebene Vorlage auswählen und den Server erstellen.

231 Profile sind enthalten. Einstellungen lassen sich durchsuchen und nach Kategorien öffnen. Unter **Ressourcen** übernimmt das Spielerlimit den Standardwert und die Grenzen des Spiels; dort kannst du es auch später in der Serverkonfiguration ändern. Je Spiel stehen passende Felder und Zugangsdaten zur Verfügung. Die Strukturprüfung belegt keine erfolgreichen Live-Starts aller Spiele. Spielabhängige Konten, Tokens und Zusatzdateien sind gesondert nötig. Hytale besitzt getrennte geführte Anmeldedialoge für Downloader und Serveranbieter.

## Updates und Sicherungen

Dienstinstallationen verwenden signierte Updatepakete. Lokale Gameserver und laufende Aufträge vor dem Update beenden. Im Webinterface nach Updates suchen, das Paket vorbereiten und die Zielversion bestätigen. Manuell: **update.ps1 -Latest** bzw. **sudo bash update.sh --latest**. Programmdateien und Datenbank werden gesichert; schlägt der Starttest fehl, versucht der Helfer die vorherige Version samt Datenbank wiederherzustellen.

Portable Installationen: GSCS stoppen, das neue Paket in einen neuen Programmordner entpacken und den unveränderten Datenordner weiterverwenden. Docker: neues Image laden und den GSCS-Container mit denselben Datenordnern neu erstellen.

Ab Alpha 5 prüft GSCS beim Containerstart die signierten Programmdateien des Images. Ein abweichender Programmstand wird auch bei gleicher Versionsnummer übernommen. Vorhandene Benutzer, Lizenzen, Einstellungen und Spielstände bleiben im Datenordner erhalten.

Vor einem Systemwechsel einen verschlüsselten Export anlegen. Alle Server und Agents vor dem Import stoppen. Vorherige Dateien und ein Rücksicherungsarchiv bleiben erhalten. Nach einem Import GSCS neu starten und Node-Zuordnungen prüfen. Hytale-/Software-Lizenzen können auf dem Ziel eine erneute Anmeldung bzw. Aktivierung benötigen.

Unter Unraid für Spieldateien einen direkten Pool-/Datenträgerpfad verwenden, etwa **/mnt/cache/appdata/gscs** oder **/mnt/disk1/appdata/gscs**. Ältere 32-Bit-Spiele können über **/mnt/user** wegen der Dateisystem-Inodes fehlschlagen. Datenpfad und Host-Datenpfad im Unraid-Template müssen übereinstimmen.
