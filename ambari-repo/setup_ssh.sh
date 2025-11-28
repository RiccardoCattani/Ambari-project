
#!/bin/bash

for cname in ambari-project-bigtop_hostname0-1 ambari-project-bigtop_hostname1-1 ambari-project-bigtop_hostname2-1 ambari-project-bigtop_hostname3-1; do
  echo "Configuro $cname"
  docker exec -it "$cname" bash -c '
    ssh-keygen -t rsa -N "" -f ~/.ssh/id_rsa
    systemctl enable sshd
    systemctl start sshd
  '
done
