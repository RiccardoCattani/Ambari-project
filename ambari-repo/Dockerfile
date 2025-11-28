# Dockerfile basato sul setup testato Apache Ambari (CentOS 7)
# Fonte: https://github.com/apache/ambari/tree/main/dev-support/docker/centos7

FROM centos:7

# Installa pacchetti base necessari per Ambari
RUN yum -y install \
    sudo \
    wget \
    openssh-clients \
    openssh-server \
    vim \
    mariadb \
    mariadb-server \
    java-1.8.0-openjdk-devel \
    net-tools \
    chrony \
    krb5-server \
    krb5-libs \
    krb5-workstation \
    git \
    rpm-build \
  && yum clean all

# Scarica MySQL Connector
RUN wget https://repo1.maven.org/maven2/mysql/mysql-connector-java/5.1.47/mysql-connector-java-5.1.47.jar \
    -O /usr/share/java/mysql-connector-java.jar

# Configura SSH
RUN /bin/sed -i 's,#   StrictHostKeyChecking ask,StrictHostKeyChecking no,g' /etc/ssh/ssh_config && \
    ssh-keygen -f "/root/.ssh/id_rsa" -N ""

EXPOSE 1-65535

CMD ["/usr/sbin/init"]
