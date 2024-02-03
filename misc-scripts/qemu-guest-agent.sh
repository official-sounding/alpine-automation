#!/bin/sh

apk update
apk add qemu-guest-agent

rc-update add qemu-guest-agent default
service qemu-guest-agent start