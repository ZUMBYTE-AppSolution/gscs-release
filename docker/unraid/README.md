# GSCS auf Unraid

Das Docker-Paket bzw. `unraid-tools.zip` auf den Unraid-Server entpacken und im entpackten Ordner ausführen:

```bash
bash unraid/install-unraid.sh --load-image
```

Damit werden das signierte Release-Image geladen und die Vorlage samt Kanal-Dropdown eingerichtet. Anschließend unter **Docker → Container hinzufügen → GSCS** den Datenordner und die Ports festlegen. Bestehende Vorlagen und Container werden erhalten. Der Installer startet keinen Container.

Ohne `--load-image` wird nur die Vorlage mit Kanalwahl installiert. Ein neues System verwendet zunächst die feste Release-Version aus dem Downloadpaket. Für `alpha`, `beta` und `release` wird ein privater GHCR-Zugang benötigt. Die Kanalwahl ist ab Unraid 7.2 verfügbar. Noch unveröffentlichte Kanäle bleiben deaktiviert.

Alternativ unter **Plugins → Plugin installieren** die beiliegende `unraid/gscs-channel-selector.plg` installieren. Danach die feste Versionsnummer oder den gewünschten verfügbaren Kanal im Containerformular wählen.

Automatischer Start lässt sich nach der Containererstellung auf der Docker-Seite von Unraid einschalten. Einstellungen, Spielstände und Datenbank bleiben im gewählten Datenordner gespeichert.
