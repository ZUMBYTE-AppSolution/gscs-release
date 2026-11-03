# Hytale konfigurieren

Im Serverfenster unter **Konfiguration** stehen 25 Felder in fünf Bereichen bereit:

| Bereich | Einstellung | Hytale-Konfiguration |
|---|---|---|
| Server & Spieler | Servername im Spiel | `ServerName` |
| Server & Spieler | Willkommensnachricht | `MOTD` |
| Server & Spieler | Maximale Spieler | `MaxPlayers`, über Slots in GSCS |
| Server & Spieler | Sichtweite | `MaxViewRadius`, 1–32 Chunks |
| Zugang | Serverpasswort | `Password`; leer erlaubt Beitritt ohne Passwort |
| Zugang | Beitrittsberechtigung | `RequireJoinPermission` |
| Standardwelt | Weltordner | `Defaults.World` |
| Standardwelt | Abenteuer oder Kreativ | `Defaults.GameMode` |
| Laufzeit & Updates | Mods standardmäßig aktivieren | `DefaultModsEnabled` |
| Laufzeit & Updates | Java-Version | Java 25 |
| Laufzeit & Updates | Dateiversion | Release oder Vorabversion des Downloaders |
| Weltregeln | PvP | `IsPvpEnabled` |
| Weltregeln | Fallschaden | `IsFallDamageEnabled` |
| Weltregeln | NPCs erzeugen | `IsSpawningNPC` |
| Weltregeln | Spawnmarker | `IsSpawnMarkersEnabled` |
| Weltregeln | NPCs einfrieren | `IsAllNPCFrozen` |
| Weltregeln | Spielzeit anhalten | `IsGameTimePaused` |
| Weltregeln | Weltsimulation | `IsTicking` |
| Weltregeln | Blocksimulation | `IsBlockTicking` |
| Weltregeln | Kompass | `IsCompassUpdating` |
| Weltregeln | Zielmarkierungen | `IsObjectiveMarkersEnabled` |
| Weltregeln | Spielerdaten speichern | `IsSavingPlayers` |
| Weltregeln | Chunks speichern | `IsSavingChunks` |
| Weltregeln | Chunks entladen | `IsUnloadingChunks` |
| Weltregeln | Gameplay-Konfiguration | `GameplayConfig` |

Serverwerte schreibt GSCS nach `Server/config.json`. Weltregeln werden in `Server/universe/worlds/<Weltname>/config.json` übernommen, sobald Hytale die Welt angelegt hat. Dafür den Server nach der ersten Welterstellung einmal stoppen und wieder starten. Bestehende Weltkennungen, Seed, Plugins und weitere Einträge bleiben erhalten. Ein neuer Standardweltname wählt einen anderen Weltordner.

Das Serverpasswort wird in der GSCS-Datenbank verschlüsselt gespeichert und beim Anzeigen verdeckt. Für Hytale selbst steht es in seiner Konfigurationsdatei. Ein unverändert verdecktes Feld erhält das vorhandene Passwort; Leeren des Feldes entfernt den Passwortschutz beim nächsten Serverstart. Die Kontoanmeldung für Hytale ist davon unabhängig.

Zusätzliche strukturierte Einstellungen wie `ConnectionTimeouts`, `RateLimit`, `LogLevels`, `Modules`, `Mods`, `PlayerStorage`, `AuthCredentialStore`, `Backup`, `WorldMap` und `Update` lassen sich im Dateieditor bearbeiten. Hytales eigene Update-Anwendung benötigt dessen Start-Wrapper; Spielupdates sollten in GSCS über die Update-Funktion ausgelöst werden.

Die Feldnamen wurden mit dem offiziellen Server-Artefakt 0.7.5, der [Server-API](https://docs.hytale.com/api/com/hypixel/hytale/server/core/HytaleServerConfig) und dem [Server-Handbuch](https://support.hytale.com/hc/en-us/articles/45326769420827-Hytale-Server-Manual) abgeglichen. Änderungen werden beim Serverstart gelesen. Änderungen an Dateien während des Spielbetriebs kann Hytale überschreiben.
