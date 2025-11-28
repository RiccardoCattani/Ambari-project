FROM bigtop/puppet:trunk-rockylinux-8

RUN yum install -y openssh openssh-server openssh-clients && \
    yum clean all

COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["/sbin/init"]
