# Netzwerk, Erreichbarkeit und UPnP

Ports werden ausschließlich aus dem Pool des jeweiligen Nodes vergeben. Pro Rolle kann ein freier Port gewählt oder automatisch vergeben werden. Reservierungen anderer GSCS-Server, lokale TCP-/UDP-Belegungen und veröffentlichte Docker-Ports werden berücksichtigt. Zusammengehörige Ports werden gemeinsam reserviert. Ein bestehender Server muss zum Ändern seiner Ports gestoppt sein.

## Adresse und Status

Karten und Tabelle zeigen Spieladresse und Port. Unter **Nodes & Laufzeiten** kann eine öffentliche IP-Adresse oder ein Hostname hinterlegt werden. Ohne Vorgabe verwendet GSCS eine bestätigte UPnP-Adresse oder die ermittelte Node-Adresse. Das Kopiersymbol übernimmt die vollständige Adresse.

Prozessstatus und Spielabfrage werden getrennt angezeigt. GSCS unterstützt Source A2S, Minecraft Java, Bedrock RakNet, FiveM/RedM und Hytale QUIC. Eine Hytale-QUIC-Antwort bestätigt das Protokoll, liefert aber keine Spielerzahl. Bei anderen TCP-Profilen bestätigt ein erfolgreicher Verbindungsaufbau nur den Port. Ohne passendes Abfrageprotokoll wird keine Spielantwort behauptet.

Die Abfrage erfolgt vom ausführenden Node. Sie bestätigt keine Erreichbarkeit aus dem Internet. Öffentliche Firewallregeln, vorgeschaltete Router, CGNAT und Providerfreigaben müssen dazu passen.

## UPnP einschalten

Unter **Nodes & Laufzeiten → Node bearbeiten** UPnP aktivieren und den Router suchen lassen. Der Router muss UPnP IGD erlauben. GSCS richtet TCP- und UDP-Freigaben nur für zugewiesene Ports laufender, freigegebener Gameserver ein und liest jede Regel zur Bestätigung zurück. Der Netzwerkdialog des Servers zeigt den Zustand jeder Freigabe.

Vorhandene fremde Routerregeln werden weder überschrieben noch gelöscht. GSCS erneuert eigene Regeln, stellt sie nach einem Routerneustart wieder her und entfernt sie beim Stoppen, Löschen oder Abschalten von UPnP. Fehlgeschlagene Bereinigungen bleiben zur Wiederholung gespeichert.

Docker benötigt direkten Zugang zum Router, vorzugsweise das Hostnetzwerk. Bei Bridge-Netzen sind die Host-Portzuordnungen und die Sicht auf die Host-Belegung erforderlich. IPv4-UPnP ersetzt keine IPv6-Firewallkonfiguration.

## Bedienung und Bilder

Starten, Stoppen, Neustarten, Aktualisieren und Konfigurieren stehen pro Server und gemeinsam über der Liste bereit. Sammelaktionen prüfen die Berechtigungen für jeden Server und zeigen einzelne Ergebnisse. Ein bestätigtes manuelles Update legt vorher eine Sicherung an und startet zuvor laufende Server anschließend wieder. Fehlgeschlagene Installationen werden nicht automatisch gestartet.

Spielbilder werden im Hintergrund geladen und auf dem Master zwischengespeichert. Der Browser speichert vorhandene Bilder einen Tag lokal und kann sie danach über ETag erneut bestätigen. Fehlende oder langsame Bilder blockieren die Bedienung nicht. Karten und kompakte Tabellenzeilen verwenden dasselbe Titelbild.

Die Übersicht lädt Status und Aufträge auch bei geöffneten Dialogen asynchron nach. Ungespeicherte Formulare bleiben erhalten. Start, Stopp, Neustart, Installation, Sicherung und Updates zeigen eine animierte Meldung bis zum Ergebnis; diese bleibt über Dialogen sichtbar und läuft nach dem Schließen des Auftragsfensters weiter. Bildabrufe besitzen ein getrenntes Anfragelimit und können die Steuerung oder Node-Signale nicht aufbrauchen.
