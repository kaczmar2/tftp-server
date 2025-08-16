FROM alpine:latest

LABEL org.opencontainers.image.authors="Christian Kaczmarek" \
      org.opencontainers.image.description="Minimal TFTP server based on Alpine Linux and tftpd-hpa" \
      org.opencontainers.image.licenses="MIT" \
      org.opencontainers.image.source="https://github.com/kaczmar2/tftp-hpa-alpine"

RUN apk add --no-cache tftp-hpa socat

EXPOSE 69/udp

# Set default TFTP arguments (can be overridden via environment variables)
ENV TFTP_ARGS="--foreground --secure --verbosity 4 --user nobody"

# Set up TFTP root directory
RUN mkdir -p /srv/tftp && \
    chown nobody:nobody /srv/tftp && \
    chmod 755 /srv/tftp

# Set working directory
WORKDIR /srv/tftp

# Create startup script with socat for syslog redirection
RUN echo '#!/bin/ash' > /start-tftp.sh && \
    echo 'echo "Starting tftpd..."' >> /start-tftp.sh && \
    echo 'socat -u UNIX-RECV:/dev/log STDOUT &' >> /start-tftp.sh && \
    echo 'sleep 1' >> /start-tftp.sh && \
    echo 'echo "Executing: /usr/sbin/in.tftpd ${TFTP_ARGS} /srv/tftp"' >> /start-tftp.sh && \
    echo 'exec /usr/sbin/in.tftpd ${TFTP_ARGS} /srv/tftp' >> /start-tftp.sh && \
    chmod +x /start-tftp.sh

CMD ["/start-tftp.sh"]