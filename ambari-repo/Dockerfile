FROM bigtop/puppet:trunk-rockylinux-8

RUN yum install -y openssh openssh-server openssh-clients && \
    yum clean all

# Default command
CMD ["/sbin/init"]
