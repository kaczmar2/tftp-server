#!/bin/ash

echo "Starting TFTP server with process supervisor..."

# Global variables for critical process tracking
MINI_HTTPD_PID=""
TFTPD_PID=""

# Function to handle graceful shutdown
cleanup() {
    echo "Shutting down services..."
    
    # Stop web server if running
    if [ -n "$MINI_HTTPD_PID" ]; then
        echo "Stopping mini_httpd (PID: $MINI_HTTPD_PID)..."
        kill -TERM "$MINI_HTTPD_PID" 2>/dev/null
    fi
    
    # Stop TFTP server
    if [ -n "$TFTPD_PID" ]; then
        echo "Stopping tftpd (PID: $TFTPD_PID)..."
        kill -TERM "$TFTPD_PID" 2>/dev/null
    fi
    
    # Wait a moment for graceful shutdown
    sleep 2
    
    # Force kill any remaining processes
    [ -n "$MINI_HTTPD_PID" ] && kill -KILL "$MINI_HTTPD_PID" 2>/dev/null
    [ -n "$TFTPD_PID" ] && kill -KILL "$TFTPD_PID" 2>/dev/null
    
    echo "Services stopped"
    exit 0
}

# Set up signal handlers for graceful shutdown
trap cleanup SIGTERM SIGINT

# Start socat for syslog redirection (utility process - not monitored)
echo "Starting socat for syslog redirection..."
socat -u UNIX-RECV:/dev/log STDOUT &
echo "socat started for logging"

# Give socat a moment to initialize
sleep 1

# Conditionally start web server
if [ "${ENABLE_WEBSERVER:-false}" = "true" ]; then
    echo "Starting mini_httpd on port 80 serving /srv/www..."
    # Run without daemonizing (-D prevents fork) and background with &
    mini_httpd -p 80 -d /srv/www -u nobody -l /dev/stdout -D &
    MINI_HTTPD_PID=$!
    echo "Web server enabled - HTTP accessible on port 80 (PID: $MINI_HTTPD_PID)"
else
    echo "Web server disabled - TFTP only mode"
fi

# Start TFTP server in background
echo "Starting TFTP server: /usr/sbin/in.tftpd ${TFTP_ARGS} /srv/tftp"
/usr/sbin/in.tftpd ${TFTP_ARGS} /srv/tftp &
TFTPD_PID=$!
echo "TFTP server started (PID: $TFTPD_PID)"

echo "Core services started, monitoring critical processes..."

# Monitor only critical services (tftpd + mini_httpd if enabled)
# If either core service dies, shutdown everything
while true; do
    # Check if TFTP server is still running
    if ! kill -0 "$TFTPD_PID" 2>/dev/null; then
        echo "TFTP server (PID: $TFTPD_PID) has exited, shutting down..."
        cleanup
    fi
    
    # Check web server if it was started
    if [ -n "$MINI_HTTPD_PID" ] && ! kill -0 "$MINI_HTTPD_PID" 2>/dev/null; then
        echo "Web server (PID: $MINI_HTTPD_PID) has exited, shutting down..."
        cleanup
    fi
    
    # Sleep briefly before next check
    sleep 5
done