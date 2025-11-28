#!/bin/bash
set -euo pipefail

VERSION=2.7.5.0-72
BASE_URL="https://archive.apache.org/dist/ambari/ambari-2.7.5.0/centos7"
TARGET_DIR="rpms"
mkdir -p "$TARGET_DIR"

RPM_LIST=(
  "ambari-server-${VERSION}.noarch.rpm"
  "ambari-agent-${VERSION}.noarch.rpm"
  "ambari-log4j-${VERSION}.noarch.rpm"
)

for rpm in "${RPM_LIST[@]}"; do
  if [[ -f "$TARGET_DIR/$rpm" ]]; then
    echo "[SKIP] $rpm già presente"
  else
    echo "[DOWNLOAD] $rpm"
    curl -fSL "$BASE_URL/$rpm" -o "$TARGET_DIR/$rpm"
  fi
  # Verifica dimensione > 10KB (evita file HTML di errore o redirect vuoto)
  SIZE=$(stat -c%s "$TARGET_DIR/$rpm")
  if [[ $SIZE -lt 10000 ]]; then
    echo "ERRORE: File $rpm troppo piccolo ($SIZE bytes). Eliminazione."
    rm -f "$TARGET_DIR/$rpm"
    exit 1
  fi
done

echo "Tutti gli RPM scaricati in $TARGET_DIR/"
