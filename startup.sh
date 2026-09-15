#!/bin/bash

set -e

echo "🚀 MQTT Broker Setup..."

# Verzeichnisse
mkdir -p mosquitto/{config,data,log} certs certbot-webroot

# Configs kopieren falls nicht vorhanden
[ ! -f mosquitto/config/mosquitto.conf ] && cp mosquitto/config/mosquitto.conf.example mosquitto/config/mosquitto.conf
[ ! -f mosquitto/config/acl.txt ] && cp mosquitto/config/acl.txt.example mosquitto/config/acl.txt

# Starten
docker-compose up -d

echo "⏳ Warte auf Mosquitto (5 Sekunden)..."
sleep 5

# Passwörter setzen (wenn noch nicht vorhanden)
if ! docker exec mqtt-broker grep -q "^olaf:" mosquitto/config/passwords.txt 2>/dev/null; then
  echo "🔐 Passwörter werden gesetzt..."
  
  read -sp "Admin (olaf) Passwort: " ADMIN_PW
  echo
  docker exec mqtt-broker mosquitto_passwd -b mosquitto/config/passwords.txt olaf "$ADMIN_PW"
  
  read -sp "Home Assistant Passwort: " HA_PW
  echo
  docker exec mqtt-broker mosquitto_passwd -b mosquitto/config/passwords.txt home-assistant "$HA_PW"
  
  read -sp "n8n Passwort: " N8N_PW
  echo
  docker exec mqtt-broker mosquitto_passwd -b mosquitto/config/passwords.txt n8n "$N8N_PW"
fi

# Mosquitto reload
docker exec mqtt-broker mosquitto -c mosquitto/config/mosquitto.conf

echo "✅ MQTT Broker läuft!"
echo ""
echo "📍 Verbindungen:"
echo "  MQTT (unverschlüsselt): mqtt.ob5.dev:1883"
echo "  MQTT (TLS):             mqtt.ob5.dev:8883"
echo "  WebSocket (TLS):        mqtt.ob5.dev:9001"
echo ""
docker logs mqtt-broker | tail -5
