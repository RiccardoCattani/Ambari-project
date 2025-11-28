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
echo "=========================================="
echo "Setup Ambari (Custom RPM install)"
echo "=========================================="

# Verifica RPM locali
if [ ! -d rpms ]; then
	echo "Directory rpms mancante. Esegui prima: ./download-ambari-rpms.sh"
	exit 1
fi
for f in rpms/ambari-server-*.rpm rpms/ambari-agent-*.rpm rpms/ambari-log4j-*.rpm; do
	if [ ! -f "$f" ]; then
		echo "File RPM mancante: $f"
		echo "Esegui ./download-ambari-rpms.sh"
		exit 1
	fi
done

echo "Installazione Ambari Server RPM"
docker cp rpms/ambari-server-*.rpm ambari-server:/tmp/
docker cp rpms/ambari-log4j-*.rpm ambari-server:/tmp/
docker exec ambari-server yum localinstall -y /tmp/ambari-server-*.rpm /tmp/ambari-log4j-*.rpm

echo "Esecuzione ambari-server setup (embedded DB)"
docker exec ambari-server ambari-server setup -s

echo "Avvio Ambari Server"
docker exec ambari-server ambari-server start

# Chiave SSH (se non esiste la generiamo)
docker exec ambari-server bash -c "[ -f /root/.ssh/id_rsa ] || ssh-keygen -t rsa -N '' -f /root/.ssh/id_rsa"
SERVER_PUB_KEY=$(docker exec ambari-server cat /root/.ssh/id_rsa.pub)

echo "Installazione Ambari Agent RPM sui nodi"
for agent in ambari-agent1 ambari-agent2 ambari-agent3; do
	echo "-- $agent"
	docker cp rpms/ambari-agent-*.rpm $agent:/tmp/
	docker cp rpms/ambari-log4j-*.rpm $agent:/tmp/
	docker exec $agent yum localinstall -y /tmp/ambari-agent-*.rpm /tmp/ambari-log4j-*.rpm
	docker exec $agent bash -c "[ -f /root/.ssh/id_rsa ] || ssh-keygen -t rsa -N '' -f /root/.ssh/id_rsa"
	echo "$SERVER_PUB_KEY" | docker exec -i $agent bash -c "cat >> /root/.ssh/authorized_keys"
	# Configura server hostname in ambari-agent.ini
	docker exec $agent sed -i "s/^server=.*/server=ambari-server/" /etc/ambari-agent/conf/ambari-agent.ini || true
	docker exec $agent ambari-agent start || true
	docker exec $agent ambari-agent status || true
done

echo "=========================================="
echo "Ambari Setup Completato!"
echo "=========================================="
echo "Accedi alla Web UI: http://localhost:8080"
echo "Username: admin"
echo "Password: admin"
echo "=========================================="
echo "Chiave privata SSH del server (per wizard host registration):"
docker exec ambari-server cat /root/.ssh/id_rsa
echo "=========================================="

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
