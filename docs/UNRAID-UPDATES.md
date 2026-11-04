# GSCS auf Unraid aktualisieren

Unter **Docker → Container hinzufügen** die Vorlage **GSCS** auswählen. Die Erweiterung **GSCS Kanalwahl** ergänzt dort und beim Bearbeiten eines GSCS-Containers das Dropdown **Updatekanal**. Es setzt das Repository und das Spielserver-Image gemeinsam auf `alpha`, `beta` oder `release`. Andere Container werden nicht verändert.

Die Erweiterung ab Unraid 7.2 unter **Plugins → Plugin installieren** über diese Adresse installieren:

```
https://raw.githubusercontent.com/ZUMBYTE-AppSolution/gscs-release/main/docker/unraid/gscs-channel-selector.plg
```

Sie verwendet Unraids Erweiterungsschnittstelle und verändert keine Systemdateien. Die Installation bleibt über Neustarts erhalten. Unter **Plugins** kann sie wieder entfernt werden; anschließend lässt sich das Repository wie gewohnt als Text bearbeiten.

Es gibt ein GSCS-Image-Repository. Die Kanäle sind unterschiedliche Tags; gemeinsame Docker-Schichten werden wiederverwendet. `alpha` enthält neue Funktionen in Erprobung, `beta` Vorabversionen vor der stabilen Freigabe und `release` stabile Versionen. Noch nicht veröffentlichte Kanäle sind im Dropdown deaktiviert. Die Verfügbarkeit steht in `docker/unraid/channels.json` und wird bei einer Kanalveröffentlichung aktualisiert. Alle GHCR-Pakete bleiben privat.

Eine feste Versionsangabe, etwa nach dem Laden eines öffentlichen Docker-Downloadarchivs, bleibt im Dropdown als **Version … (fest)** erhalten. Ein Wechsel auf einen privaten Kanal benötigt den passenden GHCR-Zugang.

Die private Registry verwendet auf Unraid einen separaten klassischen GitHub-Token mit ausschließlich `read:packages`. Die Anmeldedaten werden unter `/mnt/disk1/appdata/.gscs-registry-auth` mit Root-Zugriff gespeichert. `/boot/config/plugins/gscs/restore-ghcr-auth.sh` stellt nach dem Einhängen des Datenträgers die GHCR-Anmeldung in `/root/.docker/config.json` wieder her und erhält andere Registry-Einträge. Der Schreibzugang des Herausgebers wird nicht dauerhaft auf Unraid gespeichert.

Nach dem Bereitstellen einer neuen Version unter dem gewählten Kanal findet **Docker → Nach Updates suchen** das neue Image. Vor der Übernahme die auf diesem GSCS-System laufenden Gameserver stoppen und ein Backup erstellen. Das Update erstellt den GSCS-Container mit dem neuen Image und denselben Datenordnern neu. Die Einstellungen im Webinterface, Spielstände, Lizenzen und Datenbank liegen im Datenordner.

Ab Alpha 5 prüft GSCS beim Start, ob die signierten Programmdateien des Images vom bisher installierten Stand abweichen. Dadurch werden neue Programme auch dann übernommen, wenn beide dieselbe Versionsnummer tragen. Das gilt auch für vorhandene Alpha-4-Datenordner. Eine bereits übernommene Anwendung wird beim nächsten Start nicht erneut ersetzt.

Für einen späteren Kanalwechsel den Container bearbeiten und **Updatekanal** ändern. Datenpfad und Host-Datenpfad bleiben identisch. Ein Wechsel auf eine ältere Programmversion ist kein unterstützter Datenbank-Downgrade; dafür ein passendes Backup verwenden. Ohne die Erweiterung sowohl **Repository** als auch **Spielserver-Image** auf `ghcr.io/zumbyte-appsolution/gscs:KANAL` setzen.

Bei der bisherigen Einrichtung mit drei Vorlagen werden die gespeicherten Werte in **GSCS** übernommen und die alten Einträge gesichert. Bestehende Container werden dabei weder neu erstellt noch neu gestartet.

Der GSCS-interne Software-Updater aktualisiert die Anwendung. Ein vollständiges Container-Update erneuert zusätzlich die im Image enthaltenen Laufzeiten und Systempakete. Die Veröffentlichung eines GHCR-Images gibt weder Quellcode noch GitHub-Releaseentwürfe öffentlich frei.

Bei einer eigenen Container-IP über **br0** bleibt dieses Netzwerk erhalten. Die Vorlage bindet **/proc/1/net** schreibgeschützt nach **/run/gscs-host-net** ein, damit GSCS zusätzlich die tatsächliche TCP-/UDP-Belegung des Unraid-Hosts prüfen kann. Bei älteren eigenen Vorlagen diese Pfadzuordnung ergänzen und den Container mit unverändertem Datenpfad neu erstellen. Die Portprüfung wird bei fehlender Hostsicht nicht umgangen.
