FROM alpine:latest

LABEL org.opencontainers.image.authors="Christian Kaczmarek" \
      org.opencontainers.image.description="TFTP server with nginx web server for boot scripts" \
      org.opencontainers.image.licenses="MIT" \
      org.opencontainers.image.source="https://github.com/kaczmar2/tftp-hpa-alpine"

# Install TFTP server, nginx, and socat for logging
RUN apk add --no-cache tftp-hpa nginx socat

EXPOSE 69/udp 80/tcp

# Set default TFTP arguments (can be overridden via environment variables)
ENV TFTP_ARGS="--foreground --secure --verbosity 4 --user nobody"

# Set up TFTP root directory
RUN mkdir -p /srv/tftp && \
    chown nobody:nobody /srv/tftp && \
    chmod 755 /srv/tftp

# Set up nginx web root (shared with TFTP for convenience)
RUN mkdir -p /var/www/html && \
    chown nobody:nobody /var/www/html && \
    chmod 755 /var/www/html

# Create nginx configuration
RUN mkdir -p /etc/nginx/http.d && \
    rm -f /etc/nginx/http.d/default.conf

# Copy nginx configuration
COPY nginx.conf /etc/nginx/http.d/default.conf

# Set working directory
WORKDIR /srv/tftp

# Copy startup script
COPY start-web.sh /start-web.sh
RUN chmod +x /start-web.sh

CMD ["/start-web.sh"]