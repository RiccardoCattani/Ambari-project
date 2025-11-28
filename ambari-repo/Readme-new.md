# Ambari Cluster su Docker - Setup Completo

Questo setup è basato sulla configurazione testata dal repository ufficiale Apache Ambari per CentOS 7.

## Prerequisiti

- Docker e docker-compose installati
- Almeno 8GB di RAM disponibile
- Connessione internet per scaricare i pacchetti

## Passo 1: Preparazione

Crea le cartelle necessarie:

```bash
mkdir -p conf
```

## Passo 2: Crea file hosts

```bash
cat > conf/hosts << 'EOF'
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6

# Ambari cluster
172.19.0.4 ambari-server
172.19.0.2 ambari-agent1
172.19.0.3 ambari-agent2
172.19.0.5 ambari-agent3
EOF
```

## Passo 3: Build e avvio container

Costruisci l'immagine Docker e avvia i container:

```bash
docker compose -f docker-compose.ambari.yml up -d
```

Questo creerà 4 container:
- **ambari-server**: Server Ambari + MariaDB (porta 8080, 3306, 5005)
- **ambari-agent1, ambari-agent2, ambari-agent3**: Nodi agent

## Passo 4: Installa Ambari

Esegui lo script di setup:

```bash
chmod +x setup-ambari.sh
./setup-ambari.sh
```

Questo script:
1. Scarica e installa Ambari Server e Agent da repository Hortonworks
2. Configura MariaDB per Ambari
3. Configura SSH tra i nodi
4. Avvia Ambari Server

## Passo 5: Accedi alla Web UI

Apri il browser e vai su: **http://localhost:8080**

Credenziali:
- **Username**: admin
- **Password**: admin

## Passo 6: Crea il cluster Hadoop

1. Clicca su "Launch Install Wizard"
2. Nome cluster: scegli un nome (es. "MyCluster")
3. Seleziona stack version: **HDP 2.6** (o versione compatibile)
4. Install Options:
   - **Target Hosts**: inserisci i nomi dei nodi:
     ```
     ambari-server
     ambari-agent1
     ambari-agent2
     ambari-agent3
     ```
   - **Host Registration Information**: 
     - Copia e incolla la chiave privata SSH stampata dallo script setup (o eseguila manualmente con `docker exec ambari-server cat ~/.ssh/id_rsa`)
     - **SSH User**: root
5. Segui il wizard per selezionare e configurare i servizi Hadoop desiderati

## Comandi Utili

### Fermare i container
```bash
docker compose -f docker-compose.ambari.yml down
```

### Riavviare i container
```bash
docker compose -f docker-compose.ambari.yml restart
```

### Accedere a un container
```bash
docker exec -it ambari-server bash
docker exec -it ambari-agent1 bash
```

### Vedere i log di Ambari Server
```bash
docker exec ambari-server tail -f /var/log/ambari-server/ambari-server.log
```

### Riavviare Ambari Server
```bash
docker exec ambari-server ambari-server restart
```

### Verificare stato Ambari Agent
```bash
docker exec ambari-agent1 ambari-agent status
```

## Troubleshooting

### Ambari Server non si avvia
```bash
docker exec ambari-server ambari-server status
docker exec ambari-server tail -n 100 /var/log/ambari-server/ambari-server.log
```

### Agent non si registra
```bash
docker exec ambari-agent1 ambari-agent status
docker exec ambari-agent1 tail -n 100 /var/log/ambari-agent/ambari-agent.log
```

### Reset completo
```bash
docker compose -f docker-compose.ambari.yml down -v
docker rmi ambari-centos7:latest
# Poi riparti dal Passo 3
```

## Note

- Questa configurazione usa **CentOS 7** (testato e stabile con Ambari 2.7.5)
- MariaDB è configurato con password 'root' per l'utente root
- SSH è configurato senza password tra i nodi
- I container girano in modalità privilegiata per systemd

## Riferimenti

- [Apache Ambari](https://ambari.apache.org/)
- [Apache Ambari GitHub](https://github.com/apache/ambari)
- [Hortonworks Documentation](https://docs.cloudera.com/HDPDocuments/Ambari-2.7.5.0/index.html)
