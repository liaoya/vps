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
