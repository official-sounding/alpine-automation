#!/bin/sh

apk update
apk add chrony

cat <<EOF > /etc/chrony/chrony.conf
server fleming.omgpwned.net iburst
makestep 1 3
driftfile /var/lib/chrony/chrony.drift
rtcsync
cmdport 0
EOF

rc-update add chronyd default
service chronyd start

apk del openntpd