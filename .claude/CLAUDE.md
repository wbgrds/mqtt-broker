# CLAUDE.md – MQTT Broker (Mosquitto)

## Zweck des Repos

Konfiguration eines Mosquitto-MQTT-Brokers in Docker, hinter Traefik, mit Let's-Encrypt-Zertifikat für die Domain `mqtt.ob5.dev`. Ports laut README: 1883 (Klartext mit Auth), 8883 (TLS), 9001 (WebSocket). Art des Repos: Infrastruktur-Konfiguration, kein Anwendungscode.

## Befehle

- Start und Erstinstallation: `./startup.sh` (startet `docker-compose up -d`, fragt Passwörter ab). Ungeprüft: Docker lief in dieser Sitzung nicht.
- Start ohne Script: `docker-compose up -d`. Ungeprüft.
- Neuer Benutzer: `docker exec mqtt-broker mosquitto_passwd -b …` und Eintrag in `mosquitto/config/acl.txt` (Befehle aus `README.md`). Ungeprüft.
- Neu laden nach Zertifikatserneuerung: `docker exec mqtt-broker mosquitto -c mosquitto/config/mosquitto.conf` (laut README, ungeprüft).
- Test: `mosquitto_sub` und `mosquitto_pub` mit den Verbindungsdaten aus `README.md`. Ungeprüft.

## Ordnerstruktur

- `docker-compose.yml` – Dienste `mosquitto` (Container `mqtt-broker`) und `certbot`, Traefik-Labels, externes Netz `traefik`.
- `mosquitto/config/mosquitto.conf` – Listener, TLS, Pfade zur ACL und Passwortdatei.
- `mosquitto/config/acl.txt` – Benutzer und Themenrechte.
- `traefik-entrypoints.yml` – Entrypoints für Traefik.
- `startup.sh` – Erstinstallation.
- `.env.example` – Liste der benötigten Variablen.
- `README.md` – Verbindungsbeispiele, Benutzerverwaltung, Integrationen.

## Umgebung

- Docker und Docker Compose. Externes Docker-Netz `traefik` muss existieren.
- DNS: `mqtt.ob5.dev` zeigt auf den Host.
- Umgebungsvariablen (nur Namen): `MQTT_ADMIN_PASSWORD`, `MQTT_HA_PASSWORD`, `MQTT_N8N_PASSWORD`, `LE_EMAIL`. Werte gehören nicht in das Repo.
- Versionen: `eclipse-mosquitto:latest`, `certbot/certbot:latest` (nicht fixiert).

## Konventionen

- Sprache: Deutsch in Dokumentation und Kommentaren.
- Commit-Nachrichten mit Emoji-Präfix im bisherigen Verlauf (`🔐 Add MQTT credentials & updated ACL`). Format ungeprüft.

## Grenzen

- Nicht ins Repo: `mosquitto/config/passwords.txt`, `mosquitto/data/`, `mosquitto/log/`, `certs/`, `certbot-webroot/` (laut `.gitignore`).
- Keine Passwörter, Tokens oder Zertifikatsdateien in Dateien, Commits, Issues oder Logs schreiben.
- Produktionskonfiguration (Ports, TLS, ACL) nur nach ausdrücklicher Freigabe ändern.

## Workflows

- Basisbranch: `main`. Änderungen als Commit auf einem Branch, dann Pull Request.
- PR-Vorlage: keine im Repo.

## Stolperfallen

- `startup.sh` kopiert `mosquitto.conf.example` und `acl.txt.example`, diese Dateien fehlen im Repo. Eine Erstinstallation ohne vorhandene Konfiguration bricht ab.
- Benutzernamen sind uneinheitlich. `acl.txt` nennt `webguards`, `home-assistant` und `n8n`. `startup.sh` und `README.md` nennen `olaf` als Admin, und die README-Tabelle nennt `olaf` mit Vollzugriff. Vor Änderungen abgleichen.
- `startup.sh` und `README.md` schreiben die Passwortdatei unter `mosquitto/config/passwords.txt`, im Container liegt sie aber unter `/mosquitto/config/`. Pfade im Befehl prüfen.
- `.env.example` enthält Platzhalter-artige Werte für die Passwörter (ungeprüft, ob echte Werte). Nicht durch echte Werte ersetzen.
- `README.md` ist lang (rund 300 Zeilen) und enthält Beispiele mit Platzhalterpasswörtern. Beispiele nicht als Vorlage für echte Zugangsdaten verwenden.
