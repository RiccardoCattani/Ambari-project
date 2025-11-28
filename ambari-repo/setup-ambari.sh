#!/bin/bash
# Script per installare e configurare Ambari Server e Agent
# Basato sul setup testato Apache Ambari CentOS 7

set -e

echo "=========================================="
echo "Setup Ambari (Hortonworks images)"
echo "=========================================="

# Avvia Ambari Server (immagine hortonworks espone già il servizio)
docker exec ambari-server bash -c "ambari-server start || true"

# Recupera chiave pubblica SSH del server (se presente)
SERVER_PUB_KEY=$(docker exec ambari-server /bin/sh -c "test -f /root/.ssh/id_rsa.pub && cat /root/.ssh/id_rsa.pub || true")

echo "=========================================="
echo "Setup Ambari Agents"
echo "=========================================="

# Configura server per gli agent e avvia
docker exec ambari-agent1 bash -c "
echo 'server=ambari-server' > /etc/ambari-agent/conf/ambari-agent.ini && \
ambari-agent start || true
"

docker exec ambari-agent2 bash -c "
echo 'server=ambari-server' > /etc/ambari-agent/conf/ambari-agent.ini && \
ambari-agent start || true
"

docker exec ambari-agent3 bash -c "
echo 'server=ambari-server' > /etc/ambari-agent/conf/ambari-agent.ini && \
ambari-agent start || true
"

echo "=========================================="
echo "Ambari Setup Completato!"
echo "=========================================="
echo "Accedi alla Web UI: http://localhost:8080"
echo "Username: admin"
echo "Password: admin"
echo "=========================================="
if [ -n "$SERVER_PUB_KEY" ]; then
	echo "Chiave pubblica SSH del server:";
	echo "$SERVER_PUB_KEY"
else
	echo "Nessuna chiave SSH trovata su ambari-server (opzionale per wizard)."
fi
echo "=========================================="
