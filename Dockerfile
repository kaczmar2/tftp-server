FROM alpine:latest

LABEL org.opencontainers.image.authors="Christian Kaczmarek" \
      org.opencontainers.image.description="TFTP server with optional mini_httpd web server based on Alpine Linux" \
      org.opencontainers.image.licenses="MIT" \
      org.opencontainers.image.source="https://github.com/kaczmar2/tftp-server"

RUN apk add --no-cache tftp-hpa socat mini_httpd tzdata

EXPOSE 69/udp 80/tcp

# Set default environment variables
ENV TFTP_ARGS="--foreground --secure --verbosity 4 --user nobody"
ENV ENABLE_WEBSERVER="false"

# Set up TFTP root directory
RUN mkdir -p /srv/tftp && \
    chown nobody:nobody /srv/tftp && \
    chmod 755 /srv/tftp

# Set up web content directory
RUN mkdir -p /srv/www && \
    chown nobody:nobody /srv/www && \
    chmod 755 /srv/www

# Set working directory
WORKDIR /srv/tftp

# Copy startup script
COPY start-server.sh /start-server.sh
RUN chmod +x /start-server.sh

# Health check to verify TFTP service is responding
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD nc -z -u -w2 127.0.0.1 69 || exit 1

CMD ["/start-server.sh"]