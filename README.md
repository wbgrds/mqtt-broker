# MQTT Broker (Mosquitto)

Production-ready MQTT Broker mit Traefik Reverse Proxy, Let's Encrypt TLS und Authentifizierung.

## Features

- **MQTT unverschlüsselt** (Port 1883) + Auth
- **MQTT TLS** (Port 8883) mit Let's Encrypt Cert für `mqtt.ob5.dev`
- **WebSocket** (Port 9001) über HTTPS
- **Traefik Integration** für automatisches Cert-Management
- **Benutzerverwaltung** mit Passwort-Hashing
- **ACL** für granulare Zugriffskontrolle
- **Docker Compose** für schnelle Deployment

## Schnellstart

### Voraussetzungen
- Docker & Docker Compose
- Traefik läuft auf `traefik` Netzwerk
- Domain `mqtt.ob5.dev` aufgelöst

### Installation

```bash
git clone https://github.com/wbgrds/mqtt-broker.git
cd mqtt-broker

# Struktur erstellen
mkdir -p mosquitto/{config,data,log} certs certbot-webroot

# Config-Dateien kopieren
cp config/mosquitto.conf mosquitto/config/
cp config/acl.txt mosquitto/config/

# Starten
docker-compose up -d

# Passwörter setzen
sleep 5
docker exec mqtt-broker mosquitto_passwd -b mosquitto/config/passwords.txt olaf <dein_passwort>
docker exec mqtt-broker mosquitto_passwd -b mosquitto/config/passwords.txt home-assistant <ha_passwort>
docker exec mqtt-broker mosquitto_passwd -b mosquitto/config/passwords.txt n8n <n8n_passwort>

# Logs prüfen
docker logs mqtt-broker
```

## Verbindung

### MQTT unverschlüsselt (Port 1883)
```bash
mosquitto_sub -h mqtt.ob5.dev -p 1883 -u olaf -P <passwort> -t 'test/#'
```

### MQTT mit TLS (Port 8883)
```bash
mosquitto_sub -h mqtt.ob5.dev -p 8883 -u olaf -P <passwort> -t 'test/#'
```

### WebSocket (Port 9001)
```bash
# Browser/JavaScript
const client = new Paho.MQTT.Client('mqtt.ob5.dev', 9001, 'clientId');
client.connect({
  userName: 'olaf',
  password: '<passwort>',
  useSSL: true
});
```

## Benutzer & ACLs

Definiert in `mosquitto/config/acl.txt`:

- **olaf**: Vollzugriff (read/write #)
- **home-assistant**: Liest sensor/*, schreibt command/*
- **n8n**: Vollzugriff

Neue User hinzufügen:
```bash
docker exec mqtt-broker mosquitto_passwd -b mosquitto/config/passwords.txt <user> <passwort>
```

## Zertifikat-Erneuerung

Let's Encrypt Certs werden von Traefik automatisch erneuert. Mosquitto neu laden:

```bash
# Manuell
docker exec mqtt-broker mosquitto -c mosquitto/config/mosquitto.conf

# Automatisch (Cron)
0 2 * * * docker exec mqtt-broker mosquitto -c mosquitto/config/mosquitto.conf
```

## Monitoring

```bash
# Logs live
docker logs -f mqtt-broker

# Statistiken
docker exec mqtt-broker mosquitto_ctrl -h localhost -u olaf -P <pw> dynsec getDefaultAclAccess
```

## Integrationshooks

### Home Assistant
```yaml
mqtt:
  broker: mqtt.ob5.dev
  port: 8883
  username: home-assistant
  password: !secret mqtt_password
  discovery: true
```

### n8n
```json
{
  "broker": "mqtt://mqtt.ob5.dev:1883",
  "username": "n8n",
  "password": "${MQTT_PASSWORD}"
}
```

### FMC920 GPS Tracker
```
MQTT Server: mqtt.ob5.dev:1883
Username: home-assistant
Password: <ha_passwort>
Topic: gps/fmc920/#
```

## Troubleshooting

### "Connection refused"
```bash
# Traefik-Netzwerk prüfen
docker network ls | grep traefik

# Mosquitto im Netzwerk?
docker network inspect traefik | grep mqtt-broker
```

### "Auth error"
```bash
# Passwort-Datei prüfen
docker exec mqtt-broker cat mosquitto/config/passwords.txt

# ACL-Datei prüfen
docker exec mqtt-broker cat mosquitto/config/acl.txt
```

### "TLS certificate error"
```bash
# Cert vorhanden?
docker exec mqtt-broker ls -la mosquitto/certs/live/mqtt.ob5.dev/

# Certbot-Logs
docker logs certbot-mqtt
```

## Dateistruktur

```
mqtt-broker/
├── docker-compose.yml          # Main Stack
├── README.md                   # This file
├── traefik-entrypoints.yml     # Traefik Config
├── mosquitto/
│   ├── config/
│   │   ├── mosquitto.conf      # MQTT Config
│   │   ├── passwords.txt       # User Hashes
│   │   └── acl.txt             # Access Control
│   ├── data/                   # Persistence
│   └── log/                    # Logs
└── certs/                      # Let's Encrypt (Traefik verwaltet)
```

## Lizenz

MIT

## Author

WEBGUARDS UG (Rostock)
