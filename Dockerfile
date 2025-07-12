FROM alpine:latest

LABEL maintainer="kaczmar2"
LABEL description="Minimal TFTP server based on Alpine Linux and tftpd-hpa"

RUN apk add --no-cache tftp-hpa socat

EXPOSE 69/udp

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
    echo 'echo "Executing: /usr/sbin/in.tftpd --foreground --secure --verbosity 4 --user nobody srv/tftp"' >> /start-tftp.sh && \
    echo 'exec /usr/sbin/in.tftpd --foreground --secure --verbosity 4 --user nobody /srv/tftp' >> /start-tftp.sh && \
    chmod +x /start-tftp.sh

CMD ["/start-tftp.sh"]