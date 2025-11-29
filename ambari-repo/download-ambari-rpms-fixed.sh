#!/bin/bash
set -euo pipefail

VERSION=2.7.5.0-72
# Repository Cloudera Archive (stabile e funzionante)
BASE_URL="https://archive.cloudera.com/p/ambari/centos7/2.x/updates/2.7.5.0"
TARGET_DIR="rpms"
mkdir -p "$TARGET_DIR"

RPM_LIST=(
  "ambari-server-${VERSION}.noarch.rpm"
  "ambari-agent-${VERSION}.noarch.rpm"
  "ambari-log4j-${VERSION}.noarch.rpm"
)

echo "=========================================="
echo "Download Ambari 2.7.5.0-72 RPM da Cloudera Archive"
echo "=========================================="

for rpm in "${RPM_LIST[@]}"; do
  if [[ -f "$TARGET_DIR/$rpm" ]]; then
    echo "[SKIP] $rpm già presente"
  else
    echo "[DOWNLOAD] $rpm"
    if ! curl -fSLk "$BASE_URL/$rpm" -o "$TARGET_DIR/$rpm"; then
      echo "ERRORE: impossibile scaricare $rpm"
      echo "URL tentato: $BASE_URL/$rpm"
      exit 1
    fi
  fi
  # Verifica dimensione > 10KB (evita file HTML di errore)
  SIZE=$(stat -c%s "$TARGET_DIR/$rpm" 2>/dev/null || stat -f%z "$TARGET_DIR/$rpm")
  if [[ $SIZE -lt 10000 ]]; then
    echo "ERRORE: File $rpm troppo piccolo ($SIZE bytes). Eliminazione."
    rm -f "$TARGET_DIR/$rpm"
    exit 1
  fi
  echo "[OK] $rpm scaricato ($(du -h "$TARGET_DIR/$rpm" | cut -f1))"
done

echo "=========================================="
echo "Tutti gli RPM scaricati in $TARGET_DIR/"
echo "Prossimo passo: ./setup-ambari.sh"
echo "=========================================="
