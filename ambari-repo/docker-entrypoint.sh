#!/bin/bash
set -e

# Genera le chiavi host se mancanti
if [ ! -f /etc/ssh/ssh_host_rsa_key ]; then
  ssh-keygen -A
fi

# Avvia sshd in background
/usr/sbin/sshd

# Esegue il comando richiesto (default: /sbin/init)
exec "$@"