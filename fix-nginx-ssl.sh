#!/bin/bash
cat > /etc/letsencrypt/options-ssl-nginx.conf << 'SSLEOF'
ssl_session_cache shared:le_nginx_SSL:10m;
ssl_session_timeout 1440m;
ssl_session_tickets off;
ssl_protocols TLSv1.2 TLSv1.3;
ssl_prefer_server_ciphers off;
ssl_ciphers "ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384";
SSLEOF

[ ! -f /etc/letsencrypt/ssl-dhparams.pem ] && openssl dhparam -dsaparam -out /etc/letsencrypt/ssl-dhparams.pem 2048

nginx -t && systemctl reload nginx && echo "NGINX OK"
