# README

This repo contain

- ansible scripts
- docker image
- shadowsocks deployment scripts

Enable ufw on Ubuntu server and open the port for Shadowsocks

```bash
# Open a port
sudo ufw allow 8388

# Show the status
sudo ufw status numbered

# delete a rule
sudo ufw delete 4
```

```bash
# https://www.baeldung.com/linux/udp-port-testing
nc -vz -u 155.94.149.79 24222
```
