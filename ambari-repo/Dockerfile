# Dockerfile basato sul setup testato Apache Ambari (CentOS 7)
# Fonte: https://github.com/apache/ambari/tree/main/dev-support/docker/centos7

FROM centos:7

# Repository CentOS 7 EOL: usa mirror stabile (kernel.org) per evitare redirect HTTPS
RUN rm -f /etc/yum.repos.d/CentOS-*.repo && \
    cat > /etc/yum.repos.d/CentOS-Vault.repo <<'EOF'
[base]
name=CentOS-7 - Base
baseurl=http://archive.kernel.org/centos-vault/7.9.2009/os/$basearch/
gpgcheck=0
enabled=1

[updates]
name=CentOS-7 - Updates
baseurl=http://archive.kernel.org/centos-vault/7.9.2009/updates/$basearch/
gpgcheck=0
enabled=1

[extras]
name=CentOS-7 - Extras
baseurl=http://archive.kernel.org/centos-vault/7.9.2009/extras/$basearch/
gpgcheck=0
enabled=1
EOF

# Evita il plugin fastestmirror che può causare mirrorlist in ambienti chiusi
RUN if [ -f /etc/yum/pluginconf.d/fastestmirror.conf ]; then \
      sed -i 's/^enabled=1/enabled=0/' /etc/yum/pluginconf.d/fastestmirror.conf; \
    fi

# Aggiorna metadata e cache
RUN yum clean all && rm -rf /var/cache/yum && yum makecache fast

# Pacchetti di base + strumenti build
RUN yum -y install sudo wget curl openssh-clients openssh-server vim net-tools \
    mariadb mariadb-server java-1.8.0-openjdk-devel \
    chrony git rpm-build krb5-server krb5-libs krb5-workstation \
    ntp ntpdate

# Installa Maven 3.6.3 (compatibile con Ambari 2.7.x)
RUN cd /opt && \
    curl -fL http://archive.apache.org/dist/maven/maven-3/3.6.3/binaries/apache-maven-3.6.3-bin.tar.gz -o maven.tgz && \
    tar -xzf maven.tgz && rm -f maven.tgz && \
    ln -sfn /opt/apache-maven-3.6.3 /opt/maven

# Clona i sorgenti Ambari 2.7.5 (persistono nell'immagine)
RUN git clone --depth 1 --branch release-2.7.5 https://github.com/apache/ambari.git /ambari

# Pulizia finale
RUN yum clean all && rm -rf /var/cache/yum

# Scarica MySQL Connector
RUN curl -fL https://repo1.maven.org/maven2/mysql/mysql-connector-java/5.1.47/mysql-connector-java-5.1.47.jar \
    -o /usr/share/java/mysql-connector-java.jar

# Configura SSH
RUN /bin/sed -i 's,#   StrictHostKeyChecking ask,StrictHostKeyChecking no,g' /etc/ssh/ssh_config && \
    ssh-keygen -f "/root/.ssh/id_rsa" -N ""

# Env di build
ENV JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk \
    M2_HOME=/opt/maven \
    PATH=$JAVA_HOME/bin:$M2_HOME/bin:$PATH

EXPOSE 1-65535

CMD ["/usr/sbin/init"]
