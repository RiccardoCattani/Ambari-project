#!/bin/bash
# Installazione manuale Ambari Server + Agent tramite RPM locali
# Da eseguire sull'host (non dentro un container)
set -euo pipefail

AMBARI_VERSION="2.7.5.0-72"
RPM_DIR="rpms"
AGENTS=(ambari-agent1 ambari-agent2 ambari-agent3)
SERVER=ambari-server

echo "=== Verifica prerequisiti RPM ==="
if [[ ! -d "$RPM_DIR" ]]; then
  echo "Cartella $RPM_DIR mancante. Esegui ./download-ambari-rpms.sh prima."; exit 1; fi
for req in "ambari-server-${AMBARI_VERSION}.noarch.rpm" "ambari-agent-${AMBARI_VERSION}.noarch.rpm" "ambari-log4j-${AMBARI_VERSION}.noarch.rpm"; do
  if [[ ! -f "$RPM_DIR/$req" ]]; then echo "RPM mancante: $RPM_DIR/$req"; exit 1; fi; done

echo "=== Installazione Ambari Server RPM ==="
docker cp "$RPM_DIR/ambari-server-${AMBARI_VERSION}.noarch.rpm" $SERVER:/tmp/
docker cp "$RPM_DIR/ambari-log4j-${AMBARI_VERSION}.noarch.rpm" $SERVER:/tmp/
docker exec $SERVER yum localinstall -y /tmp/ambari-server-${AMBARI_VERSION}.noarch.rpm /tmp/ambari-log4j-${AMBARI_VERSION}.noarch.rpm

echo "=== Setup Ambari Server (embedded Postgres) ==="
docker exec $SERVER ambari-server setup -s

echo "=== Avvio Ambari Server ==="
docker exec $SERVER ambari-server start
docker exec $SERVER ambari-server status || true

echo "=== Generazione chiave SSH server (se assente) ==="
docker exec $SERVER bash -c "[ -f /root/.ssh/id_rsa ] || ssh-keygen -t rsa -N '' -f /root/.ssh/id_rsa"
SERVER_PRIV_KEY=$(docker exec $SERVER cat /root/.ssh/id_rsa)
SERVER_PUB_KEY=$(docker exec $SERVER cat /root/.ssh/id_rsa.pub)

echo "=== Installazione Ambari Agent sui nodi ==="
for a in "${AGENTS[@]}"; do
  echo "-- $a"
  docker cp "$RPM_DIR/ambari-agent-${AMBARI_VERSION}.noarch.rpm" $a:/tmp/
  docker cp "$RPM_DIR/ambari-log4j-${AMBARI_VERSION}.noarch.rpm" $a:/tmp/
  docker exec $a yum localinstall -y /tmp/ambari-agent-${AMBARI_VERSION}.noarch.rpm /tmp/ambari-log4j-${AMBARI_VERSION}.noarch.rpm
  docker exec $a bash -c "[ -f /root/.ssh/id_rsa ] || ssh-keygen -t rsa -N '' -f /root/.ssh/id_rsa"
  echo "$SERVER_PUB_KEY" | docker exec -i $a bash -c "cat >> /root/.ssh/authorized_keys"
  docker exec $a sed -i "s/^server=.*/server=$SERVER/" /etc/ambari-agent/conf/ambari-agent.ini || true
  docker exec $a ambari-agent start || true
  docker exec $a ambari-agent status || true
done

echo "=== Riepilogo stato agent ==="
for a in "${AGENTS[@]}"; do docker exec $a ambari-agent status || true; done

echo "=========================================="
echo "Ambari Setup Completato"
echo "UI: http://localhost:8080 (admin/admin)"
echo "Chiave privata da usare nel wizard:" 
echo "$SERVER_PRIV_KEY"
echo "=========================================="
