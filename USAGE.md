# Usage notes and customization

- To modify the Nginx template: edit templates/nginx_netdata.conf.tpl
- The install script will copy the template and replace placeholders.
- If you run firewall (ufw), allow ports 80 and 443:
  ```bash
  sudo ufw allow 80,443/tcp
  sudo ufw reload
  ```
- If certbot fails, ensure:
  - DNS A record points to server IP
  - Ports 80/443 are reachable from Let's Encrypt
