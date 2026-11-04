# Spielbilder über SteamGridDB

Unter **Systemeinstellungen → Allgemein → Spielbilder → SteamGridDB einrichten** den eigenen [API-Schlüssel](https://www.steamgriddb.com/profile/preferences/api) hinterlegen und die Verbindung prüfen. Der Schlüssel wird verschlüsselt auf dem Master gespeichert und nicht an Browser oder Nodes ausgegeben. Ein leeres Schlüsselfeld behält den vorhandenen Zugang; zum Entfernen die entsprechende Option wählen.

GSCS verwendet die Steam-App-ID des Spiels. Spiele ohne Steam-ID werden über ihren Namen gesucht; mehrdeutige Treffer werden nicht automatisch zugeordnet. Für Karten und Serverliste werden statische Querformate in **920 × 430** oder **460 × 215** ausgewählt. Kleine Spieleicons verwenden den Icon-Endpunkt. Fehlt ein passendes Bild oder ist der Anbieter vorübergehend nicht erreichbar, bleiben die bisherigen Steam-/Projektbilder als Ausweichquelle verfügbar.

Bilder werden auf dem Master gespeichert und im Hintergrund aktualisiert. Der Browser speichert fertige Bilder einen Tag lokal und bestätigt unveränderte Dateien über ETag. Beim Ändern der Bildquelle erhalten die Bildadressen eine neue Versionskennung. Der API-Schlüssel ist kein Bestandteil der Bildadresse. Langsame Downloads halten keine Bedienanfragen offen.

Die Spielbilder stammen von [SteamGridDB](https://www.steamgriddb.com/) und den jeweiligen Spieleanbietern. Rechte an Spielen, Logos und Community-Grafiken liegen bei ihren jeweiligen Rechteinhabern.
