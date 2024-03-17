## TODO: bail if error encountered
## TODO: check for hostname & DO token env variables already set
# update package repository
## TODO: don't add this if it already exists
echo 'http://dl-cdn.alpinelinux.org/alpine/edge/community' >> /etc/apk/repositories
apk update
apk add certbot certbot-dns-digitalocean

# set up letsencrypt
mkdir /etc/letsencrypt

echo <<EOF > /etc/letsencrypt/options-ssl-nginx.conf

# This file contains important security parameters. If you modify this file
# manually, Certbot will be unable to automatically provide future security
# updates. Instead, Certbot will print and log an error message with a path to
# the up-to-date file that you will need to refer to when manually updating
# this file. Contents are based on https://ssl-config.mozilla.org

ssl_session_cache shared:le_nginx_SSL:10m;
ssl_session_timeout 1440m;
ssl_session_tickets off;

ssl_protocols TLSv1.2 TLSv1.3;
ssl_prefer_server_ciphers off;

ssl_ciphers "ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GC

EOF

echo "dns_digitalocean_token = $DO_DNS_TOKEN" > /etc/letsencrypt/creds.ini
chmod 700 /etc/letsencrypt/creds.ini
certbot certonly --dns-digitalocean --dns-digitalocean-credentials /etc/letsencrypt/creds.ini -d $HOSTNAME

#create post-renewal hook
echo "service nginx restart" > /etc/letsencrypt/renewal-hooks/deploy/restart-nginx.sh
chmod 755 /etc/letsencrypt/renewal-hooks/deploy/restart-nginx.sh

#create periodic entry 
echo "sleep $RANDOM && certbot renew -q" > /etc/periodic/daily/01-certbot-renew
chmod 755 /etc/periodic/daily/01-certbot-renew
