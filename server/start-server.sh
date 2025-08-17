#!/bin/ash

echo "Starting TFTP server with process supervisor..."

# Global variables for process tracking
SOCAT_PID=""
MINI_HTTPD_PID=""
TFTPD_PID=""

# Function to handle graceful shutdown
cleanup() {
    echo "Received shutdown signal, stopping services..."
    
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
    
    # Stop socat
    if [ -n "$SOCAT_PID" ]; then
        echo "Stopping socat (PID: $SOCAT_PID)..."
        kill -TERM "$SOCAT_PID" 2>/dev/null
    fi
    
    # Wait a moment for graceful shutdown
    sleep 2
    
    # Force kill any remaining processes
    [ -n "$MINI_HTTPD_PID" ] && kill -KILL "$MINI_HTTPD_PID" 2>/dev/null
    [ -n "$TFTPD_PID" ] && kill -KILL "$TFTPD_PID" 2>/dev/null
    [ -n "$SOCAT_PID" ] && kill -KILL "$SOCAT_PID" 2>/dev/null
    
    echo "All services stopped"
    exit 0
}

# Set up signal handlers for graceful shutdown
trap cleanup SIGTERM SIGINT

# Start socat for syslog redirection to stdout
echo "Starting socat for syslog redirection..."
socat -u UNIX-RECV:/dev/log STDOUT &
SOCAT_PID=$!
echo "socat started (PID: $SOCAT_PID)"

# Give socat a moment to initialize
sleep 1

# Conditionally start web server
if [ "${ENABLE_WEBSERVER:-false}" = "true" ]; then
    echo "Starting mini_httpd on port 80 serving /srv/www..."
    mini_httpd -p 80 -d /srv/www -u nobody -l /dev/stdout &
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

echo "All services started, waiting for processes..."

# Wait for any child process to exit
# This keeps the script running as PID 1
wait