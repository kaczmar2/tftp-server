# TFTP Server Docker Image

[![Docker Build, Test and Publish](https://github.com/kaczmar2/tftp-server/actions/workflows/docker-build.yml/badge.svg)](https://github.com/kaczmar2/tftp-server/actions/workflows/docker-build.yml) [![Base Image Update Check](https://github.com/kaczmar2/tftp-server/actions/workflows/base-image-update.yml/badge.svg)](https://github.com/kaczmar2/tftp-server/actions/workflows/base-image-update.yml)

A minimal, secure TFTP server with optional web server based on Alpine Linux, `tftpd-hpa`, and `mini_httpd`.

**Also available on Docker Hub**: [https://hub.docker.com/r/kaczmar2/tftp-server](https://hub.docker.com/r/kaczmar2/tftp-server)

## Features

- **TFTP-only mode**: Minimal TFTP server for network boot scenarios
- **TFTP + Web mode**: TFTP server with HTTP access to boot files and scripts
- **Runtime mode selection**: Single image, choose mode with environment variable
- **Multi-architecture**: Supports AMD64, ARM64, and ARM v7
- **Security**: Runs as `nobody` user with proper privilege dropping
- **Logging**: Unified Docker logs for both TFTP and HTTP activity

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
# Edit .env to set TZ, TFTP_ROOT, and WEB_ROOT if needed

# Create Docker bind mount directories
sudo mkdir -p /srv/docker/tftp /srv/docker/www

# Start TFTP + Web server (default)
docker compose up -d

# OR start TFTP-only mode
docker compose --profile tftp-only up -d

# Check status
docker compose ps
docker logs tftp-server
```

### Using Docker Run

```bash
# TFTP + Web server mode
docker run -d \
  --name tftp-server \
  --network host \
  --restart unless-stopped \
  -e TZ=America/Denver \
  -e ENABLE_WEBSERVER=true \
  -v /srv/docker/tftp:/srv/tftp \
  -v /srv/docker/www:/srv/www \
  -v /etc/localtime:/etc/localtime:ro \
  ghcr.io/kaczmar2/tftp-server

# TFTP-only mode
docker run -d \
  --name tftp-server \
  --network host \
  --restart unless-stopped \
  -e TZ=America/Denver \
  -e ENABLE_WEBSERVER=false \
  -v /srv/docker/tftp:/srv/tftp \
  -v /etc/localtime:/etc/localtime:ro \
  ghcr.io/kaczmar2/tftp-server
```

## Configuration

### Environment Variables

- **`ENABLE_WEBSERVER`**: Set to `true` to enable HTTP server, `false` for TFTP-only (default: `false`)
- **`TZ`**: Timezone for logs and timestamps (default: `UTC`)
- **`TFTP_ARGS`**: Custom TFTP daemon arguments (see Custom TFTP Options section)

### Docker Compose Profiles

- **Default** (`docker compose up`): TFTP + Web server mode
- **`tftp-only`** (`docker compose --profile tftp-only up`): TFTP-only mode

### Complete Docker Compose Example

```yaml
services:
  # TFTP-only server
  tftp-only:
    container_name: tftp-server
    image: ghcr.io/kaczmar2/tftp-server:latest
    restart: unless-stopped
    network_mode: host
    environment:
      - TZ=${TZ:-UTC}
      - ENABLE_WEBSERVER=false
    volumes:
      - ${TFTP_ROOT:-/srv/docker/tftp}:/srv/tftp
      - /etc/localtime:/etc/localtime:ro
    profiles:
      - tftp-only

  # TFTP + mini_httpd web server
  tftp-web:
    container_name: tftp-server
    image: ghcr.io/kaczmar2/tftp-server:latest
    restart: unless-stopped
    network_mode: host
    environment:
      - TZ=${TZ:-UTC}
      - ENABLE_WEBSERVER=true
    volumes:
      - ${TFTP_ROOT:-/srv/docker/tftp}:/srv/tftp
      - ${WEB_ROOT:-/srv/docker/www}:/srv/www
      - /etc/localtime:/etc/localtime:ro
    profiles:
      - tftp-web
      - default
```

## Directory Structure

### TFTP Files
```
/srv/docker/tftp/         # Host directory (mapped to container /srv/tftp)
├── bootfile.txt          # File to serve via TFTP
├── firmware.bin          # File to serve via TFTP  
└── subdirectory/         # Subdirectories are supported
    └── nested-file.txt
```

### Web Files (when ENABLE_WEBSERVER=true)
```
/srv/docker/www/          # Host directory (mapped to container /srv/www)
├── index.html            # Served via HTTP at http://server/
├── boot-scripts/         # Directory listing available
│   ├── script1.sh        # Served via HTTP at http://server/boot-scripts/script1.sh
│   └── script2.py
└── documentation/
    └── readme.txt
```

## Usage

### Testing TFTP Access

Install a TFTP client to test your server:

```bash
# Install TFTP client
sudo apt install tftp-hpa
```

Test file download:

```bash
cd /tmp
uname -a | sudo tee /srv/docker/tftp/test
tftp localhost
tftp> get test
tftp> quit
diff test /srv/docker/tftp/test
# (no output = files are identical)
```

### Testing Web Server Access (ENABLE_WEBSERVER=true)

```bash
# Create test content
echo "<h1>TFTP Boot Server</h1>" | sudo tee /srv/docker/www/index.html
echo "#!/bin/bash\necho 'Boot script executed'" | sudo tee /srv/docker/www/boot.sh

# Test HTTP access
curl http://localhost/                    # Should show HTML
curl http://localhost/boot.sh             # Should show script
curl -I http://localhost/                 # Check headers
```

### Viewing Logs

```bash
# Real-time logs (includes TFTP and HTTP requests)
docker logs -f tftp-server

# Check for TFTP requests (RRQ = Read Request)
docker logs tftp-server | grep RRQ

# Check for TFTP errors (NAK = Negative Acknowledgment)
docker logs tftp-server | grep NAK

# Check for HTTP requests (when web server enabled)
docker logs tftp-server | grep "GET\|POST"
```

**Log examples:**
```
# TFTP requests
<29>Jan 16 10:30:15 in.tftpd[25]: RRQ from 192.168.1.100 filename bootfile.txt

# HTTP requests (mini_httpd format)
192.168.1.100 - - [16/Jan/2025:10:30:20 +0000] "GET /boot.sh HTTP/1.1" 200 45

# Service status
Starting TFTP server with process supervisor...
Web server enabled - HTTP accessible on port 80 (PID: 16)
TFTP server started (PID: 17)
```

### File Management

```bash
# Add TFTP files
cp bootfile.txt /srv/docker/tftp/
chmod 644 /srv/docker/tftp/*

# Add web files (when using web server)  
cp index.html /srv/docker/www/
cp -r boot-scripts/ /srv/docker/www/
chmod 644 /srv/docker/www/* /srv/docker/www/**/*

# Check what files are available
ls -la /srv/docker/tftp/     # TFTP files
ls -la /srv/docker/www/      # Web files (if enabled)
```

## Network Requirements

### Host Networking

This container **requires** `network_mode: host` because:

- **TFTP uses dynamic ports** - Data transfers use random ephemeral ports
- **Port mapping doesn't work** - Docker can't map unknown future ports
- **Host networking is standard** - Most TFTP Docker images use this approach

### Firewall

**TFTP (always required):**
- UDP port 69 must be accessible

**Web server (when ENABLE_WEBSERVER=true):**
- TCP port 80 must be accessible

## Custom TFTP Options

The container supports customizing TFTP daemon behavior via the `TFTP_ARGS` environment variable. You can pass any valid `in.tftpd` options while keeping the current defaults as the base.

### Docker Run Example

```bash
# Start container with --create flag to enable uploads
docker run \
  --network host \
  -e ENABLE_WEBSERVER=false \
  -e TFTP_ARGS="--foreground --secure --create --verbosity 4 --user nobody" \
  -v /srv/docker/tftp:/srv/tftp \
  ghcr.io/kaczmar2/tftp-server
```

### Docker Compose Examples

Add to your `.env` file:

```bash
# Enable write access with custom settings
TFTP_ARGS=--foreground --secure --create --verbosity 4 --user nobody
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