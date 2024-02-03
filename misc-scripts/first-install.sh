# update package repository
echo 'http://dl-cdn.alpinelinux.org/alpine/latest-stable/community' >> /etc/apk/repositories
apk update

# setup sudo access
apk add sudo
echo '%wheel ALL=(ALL:ALL) ALL' > /etc/sudoers.d/wheel-users
chmod 700 /etc/sudoers.d/wheel-users
addgroup gsham wheel


# setup docker access
apk add docker docker-cli-compose
addgroup gsham docker
rc-update add docker default
service docker start

# prevent direct logins to root
passwd -l root

#setup qemu-guest-agent
apk add qemu-guest-agent

rc-update add qemu-guest-agent default
service qemu-guest-agent start