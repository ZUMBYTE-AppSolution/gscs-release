# Hytale-Anmeldung

Servername, Passwort und Weltregeln sind unter [Hytale konfigurieren](HYTALE-CONFIG.md) beschrieben.

Im Serverfenster **Hytale-Anmeldung** öffnen, ein Konto hinzufügen und dem Link zu Hytale folgen. GSCS zeigt Gerätecode und Restzeit an, wartet auf die Bestätigung und bietet danach die Spielprofile zur Zuordnung an. Unter **Systemeinstellungen > Hytale-Konten** können Administratoren Konten für Hosting-Server freigeben.

Der Master verwaltet die OAuth-Zugangsdaten verschlüsselt. Er erneuert sie vor Ablauf und speichert beide rotierenden Tokens gemeinsam. Beim tatsächlichen Serverstart erhält jede Instanz eine eigene Spielsitzung. Hytale übernimmt deren laufende Verlängerung; GSCS startet dafür keine stündlichen Neustarts. Nodes erhalten keine OAuth-Refresh-Tokens. Windows, Linux, Docker und die WSL-Übergabe verwenden Umgebungsvariablen statt Token-Werten in Startargumenten.

Abbruch, abgelaufener Gerätecode, fehlendes Spielprofil und erforderliche Neuanmeldung werden angezeigt. Bei unklarem Ausgang eines Token-Wechsels wird der alte Refresh-Token nicht erneut verwendet. Das Hytale-Limit von 500 gleichzeitigen Sitzungen bleibt bestehen.

Die Anmeldung des offiziellen Downloaders ist getrennt. Beim Systemumzug den bisherigen Master anhalten; OAuth-Verbindungen nicht parallel auf zwei Mastern betreiben. Ältere Backups können eine erneute Anmeldung erfordern.

Die lokalen Tests ersetzen Hytale-Antworten. Eine reale Konto-Freigabe und ein Langzeittest mit einem echten Hytale-Server stehen aus.

[Offizielle Hytale-Anleitung](https://support.hytale.com/hc/en-us/articles/45328341414043-Server-Provider-Authentication-Guide)
