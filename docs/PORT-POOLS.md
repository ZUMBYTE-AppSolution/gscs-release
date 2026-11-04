# Portpools und Serverzuweisung

Unter **Einstellungen → Netzwerk & Ports** werden pro Node Bind-Adresse, Portbereich und Protokoll freigegeben. TCP und UDP sind getrennte Belegungen; ein Pool mit „TCP + UDP“ erlaubt beide Protokolle. Reservierungen bleiben auch bei gestoppten Servern erhalten.

Beim Erstellen eines Servers einen festen Node auswählen, um Spiel-, Query-, RCON- und weitere Basisports selbst zu wählen. Jede Rolle bietet nur passende Pools dieses Nodes an. Ein leeres Portfeld wird automatisch zugewiesen. Bei automatischer Nodewahl werden auch die Ports automatisch vergeben.

Die freie Auswahl ist ausschließlich innerhalb eines passenden Pools möglich. Der Server prüft Pool, Node, Adresse, Protokoll und Portnummer erneut; zusätzliche Angaben im Browser können die Grenzen nicht erweitern. Abhängige Ports, etwa „Spielport + 1“, werden gemeinsam zugewiesen und müssen ebenfalls in passenden Pools frei sein.

Bei bestehenden Servern erfolgt die Änderung unter **Netzwerk**. Der Server muss gestoppt sein; laufende oder wartende Aufträge sowie ein Nodeumzug verhindern die Änderung. Erst wenn das gesamte Portbündel verfügbar ist, werden die alten Reservierungen ersetzt. Bei einem Fehler bleibt die bisherige Zuweisung erhalten. Die neuen Werte fließen beim nächsten Start in Konfiguration und erzeugtes Startskript ein. Eigene Startskripte bleiben erhalten; dort fest eingetragene Portnummern müssen entsprechend angepasst werden.

Die Belegungsanzeige unterscheidet GSCS-Reservierungen, Systemdienste und veröffentlichte Docker-Ports. Die lokale Prüfung erfolgt beim Zuweisen erneut. Entfernte Nodes melden ihre Belegung mit dem Heartbeat; ohne vollständige Meldung aus den letzten 35 Sekunden wird keine neue Zuweisung vorgenommen. Master und Nodes müssen dafür auf demselben aktuellen Softwarestand sein. Beim Prozessstart wird erneut auf belegte Ports geprüft.

Ein freier Port ist keine Router- oder Firewallfreigabe. Die Erkennung beschreibt eine Momentaufnahme: Andere Programme können einen freien Port später belegen. Der Netzwerkreiter zeigt die zuletzt ermittelte Belegung und bietet eine Aktualisierung an.

Docker sollte mit `network_mode: host` ausgeführt werden, wie in der mitgelieferten Compose-Datei und Unraid-Vorlage. So sieht die lokale Prüfung die Systemports des Hosts. Ohne Hostnetzwerk sieht GSCS zunächst nur die Ports seines eigenen Netzwerkbereichs sowie die über Docker veröffentlichten Ports. Bei erkanntem Bridge-Modus ohne Host-Portdaten wird die Zuweisung abgewiesen. Für eine vollständige Hostprüfung im Bridge-Modus lässt sich `/proc/net` des Linux-Hosts schreibgeschützt nach `/run/gscs-host-net` einbinden.

Technische Referenzen: [lokale TCP-Endpunkte](https://learn.microsoft.com/en-us/dotnet/api/system.net.networkinformation.ipglobalproperties.getactivetcpconnections?view=net-10.0), [Docker-Containerprüfung](https://docs.docker.com/reference/cli/docker/container/inspect/).
