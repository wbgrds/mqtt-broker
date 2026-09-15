# 🔌 MQTT Broker (Mosquitto)

Production-ready MQTT Broker mit **Traefik Reverse Proxy**, **Let's Encrypt TLS** und **Benutzer-Authentifizierung**.

![Status](https://img.shields.io/badge/Status-Active-brightgreen)
![Docker](https://img.shields.io/badge/Docker-Compose-blue)
![License](https://img.shields.io/badge/License-MIT-green)

## ✨ Features

- ✅ **MQTT unverschlüsselt** (Port 1883) mit Authentifizierung
- ✅ **MQTT TLS** (Port 8883) mit automatischem Let's Encrypt Cert für `mqtt.ob5.dev`
- ✅ **WebSocket** (Port 9001) über HTTPS
- ✅ **Traefik Integration** für automatisches Zertifikat-Management
- ✅ **Benutzerverwaltung** mit Passwort-Hashing
- ✅ **ACL (Access Control List)** für granulare Zugriffskontrolle
- ✅ **Docker Compose** für schnelle Deployment
- ✅ **Persistente Daten** und strukturiertes Logging

## 🚀 Schnellstart

### Voraussetzungen

- Docker & Docker Compose
- Traefik läuft auf `traefik` Netzwerk
- Domain `mqtt.ob5.dev` aufgelöst

### Installation

```bash
# Klonen
git clone https://github.com/wbgrds/mqtt-broker.git
cd mqtt-broker

# Starten
./startup.sh
```

Das Script erstellt die Verzeichnisse und fragt nach Passwörtern.

## 📡 Verbindung & Tests

### MQTT unverschlüsselt (Port 1883)

```bash
# Subscribe
mosquitto_sub -h mqtt.ob5.dev -p 1883 -u olaf -P <passwort> -t 'test/#'

# Publish (neues Terminal)
mosquitto_pub -h mqtt.ob5.dev -p 1883 -u olaf -P <passwort> -t 'test/hello' -m 'Hallo Welt'
```

### MQTT mit TLS (Port 8883)

```bash
# Subscribe (automatisch mit LE Cert)
mosquitto_sub -h mqtt.ob5.dev -p 8883 -u olaf -P <passwort> -t 'test/#'
```

### WebSocket (Port 9001 über HTTPS)

```javascript
// Browser/JavaScript (z.B. mit paho-mqtt)
const client = new Paho.MQTT.Client('mqtt.ob5.dev', 9001, 'clientId_' + Math.random());

client.connect({
  userName: 'olaf',
  password: '<passwort>',
  useSSL: true,
  onSuccess: () => console.log('✅ Verbunden'),
  onFailure: (err) => console.error('❌ Fehler:', err)
});

client.subscribe('test/#');
client.onMessageArrived = (msg) => console.log(`📨 ${msg.destinationName}: ${msg.payloadString}`);
```

## 👥 Benutzer & ACLs

Definiert in `mosquitto/config/acl.txt`:

| User | Rechte |
|------|--------|
| **olaf** | ✅ read/write # (Vollzugriff) |
| **home-assistant** | read sensor/#, read device/#, write command/# |
| **n8n** | ✅ read/write # (Vollzugriff) |

### Neue User hinzufügen

```bash
# Passwort hinzufügen
docker exec mqtt-broker mosquitto_passwd -b mosquitto/config/passwords.txt <username> <passwort>

# In acl.txt schreiben
echo "user <username>" >> mosquitto/config/acl.txt
echo "topic read <topic>" >> mosquitto/config/acl.txt
```

## 🔄 Zertifikat-Erneuerung

Let's Encrypt Certs werden von **Traefik automatisch** erneuert. Mosquitto muss nach Renewal neu geladen werden:

```bash
# Manuell
docker exec mqtt-broker mosquitto -c mosquitto/config/mosquitto.conf

# Automatisch (Cron - täglich 2 Uhr)
0 2 * * * docker exec mqtt-broker mosquitto -c mosquitto/config/mosquitto.conf
```

## 🔌 Integrations-Beispiele

### Home Assistant

```yaml
mqtt:
  broker: mqtt.ob5.dev
  port: 8883
  username: home-assistant
  password: !secret mqtt_password
  discovery: true
  birth_message:
    topic: homeassistant/status
    payload: online
  will_message:
    topic: homeassistant/status
    payload: offline
```

### n8n

```json
{
  "broker": "mqtt.ob5.dev",
  "port": 1883,
  "username": "n8n",
  "password": "${MQTT_PASSWORD}",
  "connectionTimeout": 4000,
  "keepalive": 60
}
```

### FMC920 GPS Tracker

```
MQTT Server: mqtt.ob5.dev
Port: 1883
Username: home-assistant
Password: <ha_passwort>
Topic: gps/fmc920/#
```

### Home Assistant + FMC920

```yaml
mqtt:
  broker: mqtt.ob5.dev
  port: 8883
  username: home-assistant
  password: !secret mqtt_password

template:
  - trigger:
      platform: mqtt
      topic: gps/fmc920/+/data
    sensors:
      - name: "FMC920 Latitude"
        unique_id: fmc920_lat
        state_topic: "gps/fmc920/+/lat"
      - name: "FMC920 Longitude"
        unique_id: fmc920_lon
        state_topic: "gps/fmc920/+/lon"
```

## 📊 Monitoring & Logs

```bash
# Live Logs
docker logs -f mqtt-broker

# Mosquitto Statistiken
docker exec mqtt-broker mosquitto_ctrl -h localhost -u olaf -P <pw> dynsec getDefaultAclAccess

# Verbundene Clients
docker exec mqtt-broker mosquitto_ctrl -h localhost -u olaf -P <pw> dynsec getClients
```

## 🛠️ Troubleshooting

### "Connection refused"

```bash
# Traefik-Netzwerk existiert?
docker network ls | grep traefik

# Mosquitto im Netzwerk?
docker network inspect traefik | grep mqtt-broker

# Ports offen?
netstat -tlnp | grep -E '1883|8883|9001'
```

### "Auth error"

```bash
# Passwort-Datei prüfen
docker exec mqtt-broker cat mosquitto/config/passwords.txt

# ACL-Datei prüfen
docker exec mqtt-broker cat mosquitto/config/acl.txt

# Logs für Auth-Fehler
docker logs mqtt-broker | grep -i auth
```

### "TLS certificate error"

```bash
# Cert vorhanden?
docker exec mqtt-broker ls -la mosquitto/certs/live/mqtt.ob5.dev/ || echo "❌ Zertifikate fehlen"

# Certbot-Logs
docker logs certbot-mqtt | tail -20

# Renewal manuell
docker exec certbot-mqtt certbot renew --force-renewal
```

### "WebSocket ConnectionError"

```bash
# Port 9001 offen?
telnet mqtt.ob5.dev 9001

# Traefik WebSocket-Routing?
docker logs traefik | grep mqtt-ws
```

## 📁 Dateistruktur

```
mqtt-broker/
├── README.md                          # Dokumentation
├── docker-compose.yml                 # Main Stack
├── startup.sh                         # Setup Script
├── traefik-entrypoints.yml            # Traefik Konfiguration
├── .env.example                       # Umgebungsvariablen Template
├── .gitignore                         # Git-Ignorliste (Passwörter!)
└── mosquitto/
    ├── config/
    │   ├── mosquitto.conf             # MQTT Server-Konfiguration
    │   ├── passwords.txt              # Benutzer-Hashes (nicht ins Repo!)
    │   └── acl.txt                    # Access Control List
    ├── data/                          # Persistence (Message DB)
    └── log/                           # Mosquitto Logs
```

## ⚙️ Manuelle Installation (ohne startup.sh)

```bash
# Struktur erstellen
mkdir -p mosquitto/{config,data,log} certs certbot-webroot

# Config-Dateien kopieren
cp mosquitto/config/{mosquitto.conf,acl.txt} ./mosquitto/config/

# Stack starten
docker-compose up -d

# Passwörter setzen
sleep 5
docker exec mqtt-broker mosquitto_passwd -b mosquitto/config/passwords.txt olaf <passwort>
docker exec mqtt-broker mosquitto_passwd -b mosquitto/config/passwords.txt home-assistant <ha_pw>
docker exec mqtt-broker mosquitto_passwd -b mosquitto/config/passwords.txt n8n <n8n_pw>

# Mosquitto Reload
docker exec mqtt-broker mosquitto -c mosquitto/config/mosquitto.conf

# Status
docker logs mqtt-broker
```

## 🔐 Sicherheit

⚠️ **WICHTIG:**
- `mosquitto/config/passwords.txt` **NIEMALS** ins Repo committen (in `.gitignore`)
- Starke Passwörter nutzen (min. 12 Zeichen, mixed case + numbers + symbols)
- ACL-Datei regelmäßig aktualisieren
- TLS für Produktions-Umgebungen aktivieren

## 📜 Lizenz

MIT

## 👤 Author

**WEBGUARDS UG** (Rostock)

---

### 📚 Weitere Ressourcen

- [Mosquitto Dokumentation](https://mosquitto.org/man/mosquitto-conf-5.html)
- [Traefik MQTT Routing](https://doc.traefik.io/traefik/routing/routers/#protocol)
- [Let's Encrypt](https://letsencrypt.org/)
