# Ripeti la configurazione SSH su tutti i container (hostname1, 2, 3)
docker exec -it bigtop_hostname1 bash
ssh-keygen -t rsa -N "" -f ~/.ssh/id_rsa
systemctl enable sshd
systemctl start sshd
exit
# ...ripeti per hostname2 e hostname3...

# Copia la chiave pubblica di bigtop_hostname0 negli authorized_keys degli altri container
cat ~/.ssh/id_rsa.pub | docker exec -i bigtop_hostname1 bash -c 'cat >> ~/.ssh/authorized_keys'
# ...ripeti per hostname2 e hostname3...

# Testa la connessione SSH da bigtop_hostname0 verso gli altri container
ssh -o StrictHostKeyChecking=no bigtop_hostname1 echo "Connection successful"
# ...ripeti per hostname2 e hostname3...