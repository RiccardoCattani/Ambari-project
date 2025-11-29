# Work in repository root

# Creare cartelle di configurazione e persistenza chiavi
mkdir -p conf
mkdir -p ssh_keys/server ssh_keys/agent1 ssh_keys/agent2 ssh_keys/agent3
mkdir -p ssh_host_keys/server ssh_host_keys/agent1 ssh_host_keys/agent2 ssh_host_keys/agent3


# Start the Docker containers (Hortonworks images)
docker compose -f docker-compose.ambari.yml up -d

# opzionale stop
docker compose -f docker-compose.ambari.yml down -d

# Per vedere nome e IP dei container (utile per aggiornare il file hosts):
# NB: L'ordine dei container restituito da questo comando può essere diverso da quello nel file hosts.
# Verifica sempre che IP e nome corrispondano!
docker ps --format '{{.Names}}' | xargs -n1 -I{} sh -c "echo -n '{}: '; docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' {}"

## Creare file hosts per risoluzione hostname container (Accertarsi che gli IP corrispondano a quelli definiti nel docker-compose.yml)
# Come da docker compose, questi ip sono statici e assegnati ai container
cat > conf/hosts << EOF
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6

# Container hostnames (aggiornare con gli IP reali)
172.19.0.4 ambari-server
172.19.0.2 ambari-agent1
172.19.0.3 ambari-agent2
172.19.0.5 ambari-agent3
EOF

# Verify connectivity between containers
docker exec -it ambari-server ping -c 2 172.19.0.2   # ping ambari-agent1
docker exec -it ambari-server ping -c 2 172.19.0.3   # ping ambari-agent2
docker exec -it ambari-server ping -c 2 172.19.0.5   # ping ambari-agent3

# (Opzionale) Configure SSH Access Between Containers
# Configure SSH on the primary container (ambari-server)

 # Access the primary container (ambari-server)
docker exec -it ambari-server bash

# Generate SSH key
## Genera la chiave SSH in modo persistente (nella cartella montata)
# Generare la chiave SSH per ambari-server in modo persistente (nella cartella montata):

ssh-keygen -t rsa -N "" -f /root/.ssh/id_rsa   # (dentro il container, con volume ./ssh_keys/server)
# Avvia il demone SSH per abilitare l'accesso:
/usr/sbin/sshd -D &


# Le chiavi host SSH ora sono persistenti nella directory montata ./ssh_host_keys/<container>.
# Prima di avviare sshd, assicurati che le chiavi host siano presenti (necessarie per sshd) e avvialo:
if [ ! -f /etc/ssh/ssh_host_rsa_key ]; then
	ssh-keygen -A
fi
/usr/sbin/sshd -D &


# Per ogni container, genera la chiave nella directory dedicata:
## Per ambari-agent1:
# Entra nel container ambari-agent1
docker exec -it ambari-agent1 bash

# Installa openssh-server se non è già presente
# CentOS base nelle immagini potrebbe già includere SSH.
# Se mancante:
yum install -y openssh-clients openssh-server

# Genera la chiave SSH in modo persistente (nella cartella montata)
ssh-keygen -t rsa -N "" -f /root/.ssh/id_rsa   # (dentro il container, con volume ./ssh_keys/agent1)

# Avvia il demone SSH per abilitare l'accesso:
# Prima di avviare sshd, assicurati che le chiavi host siano presenti (necessarie per sshd) e avvialo:
if [ ! -f /etc/ssh/ssh_host_rsa_key ]; then
	ssh-keygen -A
fi
/usr/sbin/sshd -D &

## Per ambari-agent2:
# Entra nel container ambari-agent2
docker exec -it ambari-agent2 bash


# Installa openssh-clients se non è già presente
yum install -y openssh-clients openssh-server
# Genera la chiave SSH in modo persistente (nella cartella montata)
ssh-keygen -t rsa -N "" -f /root/.ssh/id_rsa   # (dentro il container, con volume ./ssh_keys/agent2)

# Avvia il demone SSH per abilitare l'accesso:
if [ ! -f /etc/ssh/ssh_host_rsa_key ]; then
	ssh-keygen -A
fi
/usr/sbin/sshd -D &

## Per ambari-agent3:
# Entra nel container ambari-agent3
docker exec -it ambari-agent3 bash

# Installa openssh-clients se non è già presente
yum install -y openssh-clients openssh-server
# genera chiave SSH in modo persistente (nella cartella montata)
ssh-keygen -t rsa -N "" -f /root/.ssh/id_rsa   # (dentro il container, con volume ./ssh_keys/agent3)
# Avvia il demone SSH per abilitare l'accesso e le chiavi host sono persistenti nella directory montata ./ssh_host_keys/<container>):
if [ ! -f /etc/ssh/ssh_host_rsa_key ]; then
	ssh-keygen -A
fi
/usr/sbin/sshd -D &

# Ora ogni chiave sarà visibile nella rispettiva cartella ./ssh_keys/<nome> sul tuo host



# Exit the container
exit

# Configure SSH on the other containers (bigtop_hostname1, bigtop_hostname2, bigtop_hostname3)
# Repeat SSH configuration on all other containers (hostname1, 2, 3)

# Genera la chiave SSH in modo persistente (nella cartella montata)
ssh-keygen -t rsa -N "" -f ~/.ssh/id_rsa
# Avvia il servizio SSH (le chiavi host sono persistenti nella directory montata ./ssh_host_keys/<container>):
if [ ! -f /etc/ssh/ssh_host_rsa_key ]; then
	ssh-keygen -A
fi
/usr/sbin/sshd -D &
exit


# Genera la chiave SSH in modo persistente (nella cartella montata)
ssh-keygen -t rsa -N "" -f ~/.ssh/id_rsa
# Avvia il servizio SSH (usa sempre il path assoluto per evitare errori):
/usr/sbin/sshd -D &
exit


# Genera la chiave SSH in modo persistente (nella cartella montata)
ssh-keygen -t rsa -N "" -f ~/.ssh/id_rsa
# Avvia il servizio SSH (usa sempre il path assoluto per evitare errori):
/usr/sbin/sshd -D &
exit


## Copy SSH key from server to agents
# Assicurati che la chiave pubblica esista prima di copiarla:
if docker exec ambari-server test -f /root/.ssh/id_rsa.pub; then
	docker cp ambari-server:/root/.ssh/id_rsa.pub /tmp/id_rsa.pub
	cat /tmp/id_rsa.pub | docker exec -i ambari-agent1 bash -c 'cat >> ~/.ssh/authorized_keys'
	cat /tmp/id_rsa.pub | docker exec -i ambari-agent2 bash -c 'cat >> ~/.ssh/authorized_keys'
	cat /tmp/id_rsa.pub | docker exec -i ambari-agent3 bash -c 'cat >> ~/.ssh/authorized_keys'
	rm /tmp/id_rsa.pub
else
	echo "La chiave pubblica /root/.ssh/id_rsa.pub non esiste su ambari-server. Generala prima con ssh-keygen."
fi


# Entra nel container primario per testare le connessioni SSH
docker exec -it ambari-server bash

# Test SSH connections (da dentro ambari-server)
ssh -o StrictHostKeyChecking=no ambari-agent1 echo "Connection successful"
ssh -o StrictHostKeyChecking=no ambari-agent2 echo "Connection successful"
ssh -o StrictHostKeyChecking=no ambari-agent3 echo "Connection successful"
exit

# Disable SELinux on all containers
docker exec -it ambari-server bash -c "setenforce 0 && sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config"
docker exec -it ambari-agent1 bash -c "setenforce 0 && sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config"
docker exec -it ambari-agent2 bash -c "setenforce 0 && sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config"
docker exec -it ambari-agent3 bash -c "setenforce 0 && sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config"


## Install necessary packages on all containers (opzionale)
# Le immagini Hortonworks includono già i componenti Ambari.
# Usa yum anziché dnf se devi installare utilities aggiuntive.

# Settare ora esatta automatica e datazione corretta su tutti i container in maniera persistente (opzionale, ma consigliato)
docker exec -it ambari-server bash -c "yum install -y ntpdate && ntpdate pool.ntp.org && systemctl enable ntpd && systemctl start ntpd"
docker exec -it ambari-agent1 bash -c "yum install -y ntpdate && ntpdate pool.ntp.org && systemctl enable ntpd && systemctl start ntpd"
docker exec -it ambari-agent2 bash -c "yum install -y ntpdate && ntpdate pool.ntp.org && systemctl enable ntpd && systemctl start ntpd"
docker exec -it ambari-agent3 bash -c "yum install -y ntpdate && ntpdate pool.ntp.org && systemctl enable ntpd && systemctl start ntpd"




# setup ambari server and agents
./setup-ambari.sh


## Access Ambari Web UI
# Open browser and navigate to:
# http://localhost:8080  (or http://192.168.1.230:8080 from remote)
#
# Default credentials:
# Username: admin
# Password: admin
#
# From Ambari Web UI, you can now:
# 1. Create a cluster
# 2. Install Hadoop services (HDFS, YARN, etc.)
# 3. Manage and monitor your cluster