#!/bin/ash

echo "Starting TFTP + nginx web server..."

# Start socat for syslog redirection to stdout
socat -u UNIX-RECV:/dev/log STDOUT &

# Give socat a moment to initialize
sleep 1

# Start nginx in background
echo "Starting nginx..."
nginx

# Start TFTP server in foreground
echo "Executing: /usr/sbin/in.tftpd ${TFTP_ARGS} /srv/tftp"
exec /usr/sbin/in.tftpd ${TFTP_ARGS} /srv/tftp