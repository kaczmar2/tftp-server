FROM alpine:latest

LABEL org.opencontainers.image.authors="Christian Kaczmarek" \
      org.opencontainers.image.description="TFTP server with optional BusyBox httpd web server based on Alpine Linux" \
      org.opencontainers.image.licenses="MIT" \
      org.opencontainers.image.source="https://github.com/kaczmar2/tftp-server"

RUN apk add --no-cache tftp-hpa socat

EXPOSE 69/udp 80/tcp

# Set default environment variables
ENV TFTP_ARGS="--foreground --secure --verbosity 4 --user nobody"
ENV ENABLE_WEBSERVER="false"

# Set up TFTP root directory
RUN mkdir -p /srv/tftp && \
    chown nobody:nobody /srv/tftp && \
    chmod 755 /srv/tftp

# Set up web content directory
RUN mkdir -p /var/www && \
    chown nobody:nobody /var/www && \
    chmod 755 /var/www

# Set working directory
WORKDIR /srv/tftp

# Copy startup script
COPY start-server.sh /start-server.sh
RUN chmod +x /start-server.sh

CMD ["/start-server.sh"]