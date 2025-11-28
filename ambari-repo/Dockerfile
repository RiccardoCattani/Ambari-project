# Dockerfile basato sul setup testato Apache Ambari (CentOS 7)
# Fonte: https://github.com/apache/ambari/tree/main/dev-support/docker/centos7

FROM centos:7

# Fix repository per CentOS 7 EOL - usa vault.centos.org
RUN cd /etc/yum.repos.d/ && \
    sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-*.repo && \
    sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-*.repo

# Aggiorna metadata e cache
RUN yum clean all && rm -rf /var/cache/yum && yum makecache fast

# Installa pacchetti base (step 1)
RUN yum -y install sudo wget openssh-clients openssh-server vim net-tools

# Installa database e Java (step 2)  
RUN yum -y install mariadb mariadb-server java-1.8.0-openjdk-devel

# Installa utilities (step 3)
RUN yum -y install chrony git rpm-build

# Installa Kerberos (step 4)
RUN yum -y install krb5-server krb5-libs krb5-workstation

# Pulizia finale
RUN yum clean all && rm -rf /var/cache/yum

# Scarica MySQL Connector
RUN wget https://repo1.maven.org/maven2/mysql/mysql-connector-java/5.1.47/mysql-connector-java-5.1.47.jar \
    -O /usr/share/java/mysql-connector-java.jar

# Configura SSH
RUN /bin/sed -i 's,#   StrictHostKeyChecking ask,StrictHostKeyChecking no,g' /etc/ssh/ssh_config && \
    ssh-keygen -f "/root/.ssh/id_rsa" -N ""

EXPOSE 1-65535

CMD ["/usr/sbin/init"]

