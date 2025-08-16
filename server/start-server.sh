#!/bin/ash

echo "Starting TFTP server..."

# Start socat for syslog redirection to stdout
socat -u UNIX-RECV:/dev/log STDOUT &

# Give socat a moment to initialize
sleep 1

# Conditionally start web server
if [ "${ENABLE_WEBSERVER:-false}" = "true" ]; then
    echo "Starting BusyBox httpd on port 80 serving /var/www..."
    httpd -f -p 80 -h /var/www &
    echo "Web server enabled - HTTP accessible on port 80"
else
    echo "Web server disabled - TFTP only mode"
fi

# Start TFTP server in foreground
echo "Executing: /usr/sbin/in.tftpd ${TFTP_ARGS} /srv/tftp"
exec /usr/sbin/in.tftpd ${TFTP_ARGS} /srv/tftp