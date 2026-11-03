# GSCS auf Unraid aktualisieren

Unter **Docker → Container hinzufügen** stehen die Vorlagen **GSCS-alpha**, **GSCS-beta** und **GSCS-release** zur Auswahl. Jede Vorlage setzt das Repository und das Spielserver-Image auf denselben Kanal. Alle drei verwenden standardmäßig den Containernamen `GSCS`; für parallele Installationen eigene Namen und getrennte Datenordner wählen.

`alpha` enthält neue Funktionen in Erprobung, `beta` Vorabversionen vor der stabilen Freigabe und `release` stabile Versionen. Ein Kanal lässt sich erst installieren, wenn ein entsprechender Build veröffentlicht wurde. Solange ausschließlich Alpha-Builds freigegeben sind, bleiben Beta und Release unbefüllt. Alle GHCR-Pakete bleiben privat.

Die private Registry verwendet auf Unraid einen separaten klassischen GitHub-Token mit ausschließlich `read:packages`. Die Anmeldedaten werden unter `/mnt/disk1/appdata/.gscs-registry-auth` mit Root-Zugriff gespeichert. `/boot/config/plugins/gscs/restore-ghcr-auth.sh` stellt nach dem Einhängen des Datenträgers die GHCR-Anmeldung in `/root/.docker/config.json` wieder her und erhält andere Registry-Einträge. Der Schreibzugang des Herausgebers wird nicht dauerhaft auf Unraid gespeichert.

Nach dem Bereitstellen einer neuen Version unter dem gewählten Kanal findet **Docker → Nach Updates suchen** das neue Image. Vor der Übernahme die auf diesem GSCS-System laufenden Gameserver stoppen und ein Backup erstellen. Das Update erstellt den GSCS-Container mit dem neuen Image und denselben Datenordnern neu. Die Einstellungen im Webinterface, Spielstände, Lizenzen und Datenbank liegen im Datenordner.

Für einen späteren Kanalwechsel den Container bearbeiten und sowohl **Repository** als auch **Spielserver-Image** auf `ghcr.io/zumbyte-appsolution/gscs:KANAL` setzen. Datenpfad und Host-Datenpfad bleiben identisch. Ein Wechsel auf eine ältere Programmversion ist kein unterstützter Datenbank-Downgrade; dafür ein passendes Backup verwenden.

Der GSCS-interne Software-Updater aktualisiert die Anwendung. Ein vollständiges Container-Update erneuert zusätzlich die im Image enthaltenen Laufzeiten und Systempakete. Die Veröffentlichung eines GHCR-Images gibt weder Quellcode noch GitHub-Releaseentwürfe öffentlich frei.
