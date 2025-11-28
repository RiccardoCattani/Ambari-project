#!/bin/bash
# Script per installare e configurare Ambari Server e Agent
# Basato sul setup testato Apache Ambari CentOS 7

set -e

echo "=========================================="
echo "Setup Ambari Server"
echo "=========================================="

# Scarica pacchetti Ambari da repository CentOS 7
docker exec ambari-server bash -c "
cd /tmp && \
wget http://public-repo-1.hortonworks.com/ambari/centos7/2.x/updates/2.7.5.0/ambari.repo -O /etc/yum.repos.d/ambari.repo && \
yum install -y ambari-server ambari-agent
"

# Configura MariaDB
docker exec ambari-server bash -c "
systemctl enable mariadb && \
systemctl start mariadb && \
mysql -e \"UPDATE mysql.user SET Password = PASSWORD('root') WHERE User = 'root'\" && \
mysql -e \"GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY 'root' WITH GRANT OPTION\" && \
mysql -e \"DROP USER ''@'localhost'\" && \
mysql -e \"DROP USER ''@'ambari-server'\" && \
mysql -e \"DROP DATABASE test\" && \
mysql -e \"CREATE DATABASE ambari\" && \
mysql --database=ambari -e \"source /var/lib/ambari-server/resources/Ambari-DDL-MySQL-CREATE.sql\" && \
mysql -e \"FLUSH PRIVILEGES\"
"

# Configura Ambari Server
docker exec ambari-server bash -c "
ambari-server setup --jdbc-db=mysql --jdbc-driver=/usr/share/java/mysql-connector-java.jar && \
ambari-server setup --java-home=/usr/lib/jvm/java-1.8.0 --database=mysql --databasehost=localhost --databaseport=3306 --databasename=ambari --databaseusername=root --databasepassword=root -s
"

# Configura SSH
SERVER_PUB_KEY=$(docker exec ambari-server /bin/cat /root/.ssh/id_rsa.pub)
docker exec ambari-server bash -c "
systemctl enable sshd && \
systemctl start sshd && \
ambari-agent start
"

echo "=========================================="
echo "Setup Ambari Agents"
echo "=========================================="

# Installa e configura agent1
docker exec ambari-agent1 bash -c "
wget http://public-repo-1.hortonworks.com/ambari/centos7/2.x/updates/2.7.5.0/ambari.repo -O /etc/yum.repos.d/ambari.repo && \
yum install -y ambari-agent && \
echo '$SERVER_PUB_KEY' > /root/.ssh/authorized_keys && \
systemctl enable sshd && \
systemctl start sshd
"

# Installa e configura agent2
docker exec ambari-agent2 bash -c "
wget http://public-repo-1.hortonworks.com/ambari/centos7/2.x/updates/2.7.5.0/ambari.repo -O /etc/yum.repos.d/ambari.repo && \
yum install -y ambari-agent && \
echo '$SERVER_PUB_KEY' > /root/.ssh/authorized_keys && \
systemctl enable sshd && \
systemctl start sshd
"

# Installa e configura agent3
docker exec ambari-agent3 bash -c "
wget http://public-repo-1.hortonworks.com/ambari/centos7/2.x/updates/2.7.5.0/ambari.repo -O /etc/yum.repos.d/ambari.repo && \
yum install -y ambari-agent && \
echo '$SERVER_PUB_KEY' > /root/.ssh/authorized_keys && \
systemctl enable sshd && \
systemctl start sshd
"

# Avvia Ambari Server
docker exec ambari-server bash -c "ambari-server start"

echo "=========================================="
echo "Ambari Setup Completato!"
echo "=========================================="
echo "Accedi alla Web UI: http://localhost:8080"
echo "Username: admin"
echo "Password: admin"
echo "=========================================="
echo "Chiave privata SSH del server (da usare nel wizard Ambari):"
docker exec ambari-server bash -c "cat ~/.ssh/id_rsa"
echo "=========================================="
