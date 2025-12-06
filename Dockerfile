# Pin to Alpine 3.19 due to BusyBox 1.37.0-r29 QEMU emulation issues in Alpine 3.23+
# Alpine 3.19 uses BusyBox 1.36.1 which works correctly with QEMU cross-platform builds
# TODO: Upgrade to alpine:latest when BusyBox 1.37.0 QEMU compatibility is resolved
FROM alpine:3.19

LABEL org.opencontainers.image.authors="Christian Kaczmarek" \
      org.opencontainers.image.description="TFTP server with optional BusyBox httpd web server based on Alpine Linux" \
      org.opencontainers.image.licenses="MIT" \
      org.opencontainers.image.source="https://github.com/kaczmar2/tftp-server"

RUN apk add --no-cache tftp-hpa socat tzdata busybox-extras

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