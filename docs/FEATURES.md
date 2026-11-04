# GSCS 0.1.0-alpha.6

Alpha-Version. Die Pakete enthalten Master, Node und die benötigten Programmlaufzeiten; ein SDK ist nicht erforderlich.

| Bereich | Funktionen |
|---|---|
| Installation | Windows und Debian/Ubuntu, Master oder Node, lokale Ausführung oder Start ohne Nodes, PostgreSQL mit zufälligen Zugangsdaten und anschließender Web-Einrichtung. |
| Docker / Unraid | Ein gemeinsames Image. Der Master startet mit interner PostgreSQL-Datenbank in einem Container. Dieselbe Datei dient als Node oder als isolierter Spielcontainer. |
| Laufzeiten | Native Prozesse, Wine, Proton und WSL; Java, .NET und Mono. Kundenserver benötigen isolierte Spielcontainer. SteamCMD und Wine/Proton setzen x64 voraus. |
| Serververwaltung | Installation, Start, Stopp, Neustart, Konsole, RCON, Workshop, automatische Updates und Crash-Neustarts mit begrenzten Wiederholungen. |
| Konfiguration | 231 Profile mit kategorisierten Eingabefeldern, Dateizuordnung und plattformabhängigen Startparametern. Dezimalwerte und leere Schalterwerte werden korrekt verarbeitet; ungültige Eingaben öffnen den zugehörigen Tab. Eigene Startskripte mit getrennten Rechten und Änderungshistorie bleiben bei Updates erhalten. |
| Deployment | Wizard, freier JSON-Editor, Import eigener Profile sowie einstellbarer GitHub-Katalog mit automatischem Abruf und Freigabe geänderter Skripte. |
| Monitoring | Serverkarten und Tabellen, CPU/RAM/Speicher, Prozessbäume, Spielabfragen, kopierbare Spieladressen, Einzel-/Sammelaktionen und Messverläufe. Node-Karten zeigen zusätzlich Netzwerkraten, Laufzeit, Kapazität und Erreichbarkeit. Hintergrundaktualisierungen erhalten Eingaben und geladene Bilder. |
| Ressourcen | CPU-/RAM-Grenzen für Docker, RAM-/Speicherüberwachung nativer Server, monatliche Docker-Trafficlimits mit automatischer Sperrung und Monatswechsel. |
| Netzwerk | Freie Portwahl innerhalb der Pools pro Node, IP und TCP/UDP; Belegungsprüfung für Systemdienste und Docker, atomare Reservierung und Änderung bei gestoppten Servern, Portoffsets, bestätigte UPnP-Routerfreigaben mit Erneuerung und Bereinigung sowie TCP-/UDP-Weiterleitung für WSL. |
| Backups | Verschlüsselte Sicherungen, vollständige Integritätsprüfung, geschützter Restore, automatische externe S3-Kopien, Aufbewahrung und angeheftete Sicherungen. Wine-/Proton-Spielstände werden mitgesichert. |
| Systemwechsel | Verschlüsselter Systemexport mit Datenbank und optionalen Dateien, Vorschau vor Import, Rücksicherung sowie verschlüsselter Node-Umzug mit Fortschritt, Abbruch und Rückkehr bei Fehlern. |
| Hosting | Kundenrollen, Paketkarten, Preis-/Ressourcensnapshots, bestätigte Bestellungen, Bereitstellung, PayPal-Abos und Verlängerungen, Kündigung zum Laufzeitende, Zahlungsbelege und Zahlungsausfallsperren. Stripe und WHMCS sind zusätzlich angebunden. |
| Zugriff | Rollen und Serverfreigaben, getrennte Startskriptberechtigung, 2FA, Passkeys, OIDC, API-Tokens, Auditprotokoll und SFTPGo-Anbindung. |
| Automatisierung | Zeitpläne, Wartungsfenster, Auftragswarteschlange, Webhooks, SMTP-/Discord-Meldungen, DNS-/DDoS-Provideradapter. |
| Statusseite | Freigegebene Server, Störungs-/Wartungsmeldungen und tägliche Verfügbarkeit. Wartung und fehlende Messungen werden gesondert erfasst. |
| Lizenz und Updates | Single, Volumen, Hosting mit Kundenlimit und Hosting Pro. Signierte Lizenzfreigaben und Auslieferungen, regelmäßige Lizenzprüfung und Updates mit Datenbank-Rücksicherung. |

Ohne Lizenz ist ein Gameserver auf localhost möglich. Bei ungültiger Lizenz werden zusätzliche Server gestoppt und entfernte Nodes gesperrt; gespeicherte Daten bleiben erhalten. Der Lizenzcode wird unter **Systemeinstellungen → Lizenz** eingetragen.

Hytale besitzt geführte Anmeldedialoge für Downloader und Serveranbieter. Zugangsdaten werden verschlüsselt gespeichert, OAuth-Tokens erneuert und beim Serverstart eigene Spielsitzungen angefordert. Ein echtes Hytale-Konto ist für die Anmeldung erforderlich.

Die Profile wurden auf das GSCS-Format übertragen und strukturell geprüft. Das ist kein Live-Startnachweis aller Spiele. Spielberechtigungen, Anti-Cheat-Unterstützung und die Eignung für Wine/Proton unterscheiden sich je Spiel. Die zugehörigen Lizenzhinweise werden mitgeliefert.

Native Prozesse haben keine gleichwertige CPU-Begrenzung oder Mandantentrennung wie Docker. Für Kundenhosting Docker verwenden. SFTP, Zahlungs-, Speicher- und Netzwerkprovider benötigen ihre Zugangsdaten. Die tatsächliche DDoS-Abwehr erfolgt beim Netzwerkprovider.

Referenzsystem-Installationen unter Windows/Linux, längerer Hytale-Betrieb, produktive Zahlungsanbieter und reale externe Speicher sind gesondert zu prüfen. Zahlungsbelege ersetzen keine steuerliche Rechnung; dafür kann das eigene Abrechnungssystem angebunden werden.

[Ports, Spielabfragen und UPnP](NETWORK.md).

Spielbilder lassen sich über SteamGridDB automatisch per Steam-ID oder Spielname beziehen. Der API-Schlüssel wird verschlüsselt auf dem Master gespeichert. [Einrichtung und Cache](ARTWORK.md).

Native Linux-Starts verwenden bereits ausführbare Systemprogramme und Java-Laufzeiten unverändert. Fehlende Ausführungsrechte ergänzt GSCS ausschließlich an eigenen Serverdateien und Laufzeit-Downloads; vorhandene Lese- und Schreibrechte bleiben erhalten.

Docker-Updates vergleichen die signierten Programmstände auch bei gleicher Versionsnummer; ein älteres Image löst keinen automatischen Downgrade aus. Die Startprüfung und Wiederaufnahme einer unterbrochenen Übernahme prüfen das erwartete Manifest. Die Unraid-Vorlage stellt die Host-Portansicht auch für eigene br0-Container-IP-Adressen schreibgeschützt bereit.

Jeder Node ermittelt seine öffentliche IP im Hintergrund über UPnP oder feste HTTPS-Adressdienste und übermittelt sie mit seinem Status. Die Erkennung öffnet keine Routerports. Manuell eingetragene öffentliche Adressen haben Vorrang. Eine öffentliche IP belegt keine Erreichbarkeit aus dem Internet; Port- und Spielabfragen bleiben davon getrennt.

Die ausgelieferten Webinterface-Dateien verwenden an den Programmstand und Dateiinhalt gebundene URLs. Browser prüfen HTML, JavaScript und CSS erneut, damit Updates keine veraltete Oberfläche weiterverwenden. Der Cache für Spielbilder bleibt erhalten.
