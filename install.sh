addgroup -S aa-svc && adduser -S aa-svc -G aa-svc

mv alpine-automation.init-script /etc/init.d/alpine-automation
touch /var/log/alpine-automation.log && chown aa-svc:aa-svc /var/log/alpine-automation.log
