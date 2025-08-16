# TFTP Server Docker Image

[![Docker Build, Test and Publish](https://github.com/kaczmar2/tftp-server/actions/workflows/docker-build.yml/badge.svg)](https://github.com/kaczmar2/tftp-server/actions/workflows/docker-build.yml) [![Base Image Update Check](https://github.com/kaczmar2/tftp-server/actions/workflows/base-image-update.yml/badge.svg)](https://github.com/kaczmar2/tftp-server/actions/workflows/base-image-update.yml)

Docker Hub: [https://hub.docker.com/r/kaczmar2/tftp-server](https://hub.docker.com/r/kaczmar2/tftp-server)

A minimal, secure TFTP server based on `alpine` and `tftpd-hpa`.

## Quick Start

### Using Docker Compose (Recommended)

```bash
# Clone or create the project directory
mkdir -p ~/docker/tftp-server && cd ~/docker/tftp-server

# Download docker-compose.yml
curl -O https://raw.githubusercontent.com/kaczmar2/tftp-server/main/docker-compose.yml

# Create .env file for configuration (optional)
curl -O https://raw.githubusercontent.com/kaczmar2/tftp-server/main/.env.example
cp .env.example .env
# Edit .env to set TZ and TFTP_ROOT if needed

# Create Docker bind mount directory
sudo mkdir -p /srv/docker/tftp

# Pull and start
docker compose up -d

# Check status
docker compose ps
docker logs tftp-server
```

### Using Docker Run

```bash
docker run -d \
  --name tftp-server \
  --network host \
  --restart unless-stopped \
  -e TZ=America/Denver \
  -v /srv/docker/tftp:/srv/tftp \
  -v /etc/localtime:/etc/localtime:ro \
  kaczmar2/tftp-hpa-server
```

## Configuration

### Docker Compose Setup

```yaml
services:
  tftp:
    container_name: tftp-server
    image: kaczmar2/tftp-server
    restart: unless-stopped
    network_mode: host
    environment:
      - TZ=${TZ:-UTC}  # Use .env file or default to UTC
    volumes:
      - ${TFTP_ROOT:-/srv/docker/tftp}:/srv/tftp
      - /etc/localtime:/etc/localtime:ro
```

## Directory Structure

```
/srv/docker/tftp/         # Host directory (mapped to container)
├── file1.txt             # File to serve via TFTP
├── file2.bin             # File to serve via TFTP
└── subdirectory/         # Subdirectories are supported
    └── nested-file.txt
```

## Usage

### Testing TFTP Access

It is useful to test your TFTP server with a TFTP client; you may simply use the [tftp-hpa](https://packages.debian.org/search?keywords=tftp-hpa) package for this purpose:

```bash
# Install TFTP client
sudo apt install tftp-hpa
```

Test file download:

```
cd /tmp
uname -a | sudo tee /srv/docker/tftp/test
tftp localhost
tftp> get test
tftp> quit
diff test /srv/docker/tftp/test
(nothing, they are identical)
```

### Viewing Logs

```bash
# Real-time logs (includes TFTP requests and responses)
docker logs -f tftp-server

# Check for TFTP requests (RRQ = Read Request)
docker logs tftp-server | grep RRQ

# Check for file not found errors (NAK = Negative Acknowledgment)
docker logs tftp-server | grep NAK
```

**Log format:**
- `<29>` - RRQ (Read Request) messages
- `<30>` - NAK (Error) messages like "File not found"
- Timestamps use container timezone (configurable via TZ environment variable)

### File Management

```bash
# Add files to serve (use actual host directory)
cp myfile.txt /srv/docker/tftp/

# Check what files are available
ls -la /srv/docker/tftp/

# Set proper permissions (readable by all)
chmod 644 /srv/docker/tftp/*
```

## Network Requirements

### Host Networking

This container **requires** `network_mode: host` because:

- **TFTP uses dynamic ports** - Data transfers use random ephemeral ports
- **Port mapping doesn't work** - Docker can't map unknown future ports
- **Host networking is standard** - Most TFTP Docker images use this approach

### Firewall

Ensure UDP port 69 is accessible.

## Custom TFTP Options

The container supports customizing TFTP daemon behavior via the `TFTP_ARGS` environment variable. You can pass any valid `in.tftpd` options while keeping the current defaults as the base.

### Docker Run Example

```bash
# Start container with --create flag to enable uploads
docker run -e TFTP_ARGS="--foreground --secure --create --verbosity 4 --user nobody" kaczmar2/tftp-server
```

### Docker Compose Examples

Add to your `.env` file:

```bash
# Enable write access with custom settings
TFTP_ARGS="-foreground --secure --create --verbosity 4 --user nobody"
```

### Available Options

See the [tftpd man page](https://manpages.debian.org/testing/tftpd-hpa/tftpd.8.en.html) for all available options. 

### Limitations

When customizing `TFTP_ARGS`, note these restrictions:

- **Required options**: Always include `--foreground --user nobody` for proper container operation and security
- **Conflicting options**: Don't use `--listen` as it conflicts with `--foreground` (required for containers)
- **Security**: Avoid changing `--user` from `nobody` as this breaks the container's security model
- **Directory**: The TFTP root directory is fixed to `/srv/tftp` and cannot be changed via arguments

### File Permissions for Uploads

**Note**: Setting up host directory permissions for TFTP uploads is beyond the scope of this README, as requirements vary by environment. 

For general guidance when using `--create`: the container process needs write access to the mounted directory. This typically involves setting appropriate permissions on the host directory before starting the container.