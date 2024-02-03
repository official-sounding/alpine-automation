# update package repository
echo 'http://dl-cdn.alpinelinux.org/alpine/edge/testing' >> /etc/apk/repositories
apk update

mkdir /etc/letsencrypt
echo "dns_digitalocean_token = $(DO_DNS_TOKEN)" > /etc/letsencrypt/creds.ini
chmod 700 /etc/letsencrypt/creds.ini
certbot certonly --dns-digitalocean --dns-digitalocean-credentials /etc/letsencrypt/creds.ini -d dns.omgpwned.net

echo "service nginx restart" > /etc/letsencrypt/renewal-hooks/deploy/restart-nginx.sh
chmod 755 /etc/letsencrypt/renewal-hooks/deploy/restart-nginx.sh