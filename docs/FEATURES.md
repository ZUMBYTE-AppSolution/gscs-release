# Funktionsstand – 0.1.0-alpha.1

Die Alpha ist nutzbar, enthält aber noch nicht den vollständigen geplanten Umfang. Zusätzliche Anbieter und Laufzeiten benötigen ihre jeweiligen Dienste, Zugangsdaten und Voraussetzungen.

| Bereich | In dieser Alpha | Noch offen / Einschränkung |
|---|---|---|
| Docker und Ressourcen | Container pro Server, CPU/RAM-Vorgaben, getrennte Netzwerke, persistente Spieldateien | Native Prozesse haben keine gleichwertige vollständige Containerisolation. |
| Windows und Linux | Eigene Master-/Node-Pakete; native Ausführung; Adapter für Wine, Proton und WSL | Keine automatische Windows-VM-Provisionierung. Kompatibilität muss pro Spiel geprüft werden. |
| Backups | Verschlüsselte lokale Sicherungen, Integritätsprüfung, bewusster Restore, verschlüsselter Systemexport/-import | Automatische externe S3-Sicherung und vollständige Aufbewahrungsautomatik fehlen. |
| Updates | SteamCMD-Updates, Wartungsfenster, Vorab-Sicherung; signierter GSCS-Updater mit Datenbank-Rücksicherung | Kein garantierter Rückwechsel von bereits geänderten Spielstandformaten. |
| Hosting | Kundenrollen, Pakete, bestätigte Bestellungen, Zuordnung, Sperrung, Lizenzgrenzen; Abrechnungsadapter | Externe Hosting-Zahlungsanbieter sind nicht mit echten Zahlungen geprüft. Vollständige Hosting-Abrechnung bleibt im Ausbau. |
| Deployment | 61 eigene Vorlagen, Wizard, JSON-Editor, manuelle Importe, GitHub-Katalog mit Prüf-/Freigabeschritt | 26 Vorlagen benötigen zusätzliche Konfiguration. Katalogabgleich wird im Interface angestoßen. |
| Workshop und Mods | Workshop-Downloads, IDs, Reihenfolge und konfigurierbare Zielverzeichnisse | Kein vollständiger Modpack-Abhängigkeitslöser für sämtliche Spiele. |
| Monitoring | CPU/RAM/Speicher, Prozessstatus, Minecraft-/A2S-Abfragen, begrenzter Crash-Watchdog | Spielmetriken unterscheiden sich; Hytale-Spielerzahl und QUIC-Erreichbarkeit sind nicht vollständig angebunden. |
| Benutzer und Sicherheit | Rollen, Serverrechte, 2FA, Passkeys, OIDC, API-Tokens und Auditprotokoll | Passkey-Hardware und produktive SSO-Anbieter müssen am Ziel geprüft werden. |
| Dateien und Konsole | Browser-Dateien/Editor/Upload, Konsole, RCON, SFTPGo-Anbindung | SFTPGo ist separat bereitzustellen. Native Konsolen nach einem Agent-Neustart ggf. über RCON oder Serverneustart verbinden. |
| Node-Umzug | Master und Nodes werden getrennt verwaltet | Automatischer verschlüsselter Node-zu-Node-Umzug ist noch nicht enthalten. |
| Netzwerk | Portpools pro Node/IP und TCP/UDP, atomare Portbündel, DNS-/Provideradapter | NAT, Firewall und externe Erreichbarkeit müssen passend eingerichtet sein. |
| Automatisierung | Zeitpläne, Auftragswarteschlange, API, Webhook-/Provideranbindungen | Anbieterabhängige Abläufe benötigen Konfiguration und Prüfung. |
| Statusseite | Freigegebene Server und öffentliche Störungs-/Wartungsmeldungen | Kein vollständiges öffentliches Langzeit-SLA-Reporting. |
| Speicher | Speicherquoten, Downloadcache, lokale Daten-/Backupverwaltung | Vollständige Traffic-Abrechnung, Storage-Tiering und standortübergreifende Cache-Verteilung fehlen. |
| DDoS und externe Tests | Schnittstellen für externe Provider und Erreichbarkeitstests | Der tatsächliche Schutz muss vom Netzwerkprovider kommen. |

Die Lizenzverwaltung unterscheidet kostenloses Single, Volumen, Hosting mit Kundenlimit und Hosting Pro. Lizenzprüfung spätestens alle 48 Stunden; bei ungültiger Freigabe werden zusätzliche Server gestoppt und entfernte Nodes gesperrt. Die Daten bleiben erhalten. Lifetime benötigt ebenfalls die regelmäßige Prüfung.

Die Hytale-Kontoanbindung verwaltet OAuth-Tokens zentral und verschlüsselt, koordiniert deren Rotation und erstellt beim tatsächlichen Start eine eigene Spielsitzung je Server. Die Hytale-Server verlängern ihre laufenden Sitzungen. Ein echtes Konto und ein längerer Live-Serverbetrieb sind gesondert zu prüfen.

Die Dienstinstaller sowie Update-/Rollback-Abläufe sind in dieser ersten Alpha noch nicht auf allen sauberen Betriebssystem-Referenzsystemen verifiziert. Für Produktivdaten vorher externe Sicherungen anlegen.
