# Bunny - Docker-based Agent Isolation

A Docker-based workspace for running AI agents with system isolation using mounted bind mounts. This setup allows agents to run in isolation from the host system while maintaining access to necessary resources.

## Overview

This project provides a containerized environment for running AI agents (OpenClaw, OpenCode, etc.) with strong system isolation. The container uses bind mounts to selectively share only the necessary files and resources with the host system, rather than exposing the entire filesystem.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        Host System                          │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  Selected Bind Mounts Only                          │   │
│  │  • ~/.local/share/opencode                          │   │
│  │  • ~/.gemini                                         │   │
│  │  • ~/.kilocode                                       │   │
│  │  • ~/Desktop/workshop/                              │   │
│  │  • /var/run/docker.sock                             │   │
│  │  • $SSH_AUTH_SOCK                                   │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                    Bunny Container                          │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  Isolated Environment                                │   │
│  │  • oven/bun:slim base                               │   │
│  │  • Node.js 24 (via fnm)                            │   │
│  │  • OpenClaw, OpenCode, Gemini CLI, Kilocode        │   │
│  │  • Docker CLI, Git, Make, Nano, Curl               │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

## Isolation Model

This setup provides **system-level isolation** while selectively sharing specific directories:

| Resource | Mount Type | Purpose |
|----------|-----------|---------|
| `/var/run/docker.sock` | Bind Mount | Docker socket for nested container operations |
| `~/.local/share/opencode` | Bind Mount | OpenCode data persistence |
| `~/.gemini` | Bind Mount | Gemini CLI data |
| `~/.kilocode` | Bind Mount | Kilocode CLI data |
| `~/Desktop/workshop/` | Bind Mount | Shared workspace directory |
| `$SSH_AUTH_SOCK` | Bind Mount | SSH authentication forwarding |
| `~/.docker` | Bind Mount (ro) | Docker config (read-only) |
| `./openclaw` | Bind Mount | OpenClaw configuration |
| `/etc/profile.d/aliases.sh` | Bind Mount | Shell aliases |

### What Is Isolated

- **Filesystem**: Container has its own isolated filesystem
- **Process Space**: Separate process namespace
- **Network**: Uses bridge network mode (configurable)

### What Is Shared

- **Docker Daemon**: Via socket mount, allows running nested containers
- **User Data**: Selected directories for CLI tools
- **SSH Keys**: Via SSH_AUTH_SOCK for git operations
- **Workspace**: Specific project directory

## Installed Tools

The container includes:

- **Runtime**: Bun (oven/bun:slim)
- **Node.js**: v24 (via fnm)
- **AI Agents**: OpenClaw, OpenCode-AI, Gemini CLI, Kilocode CLI
- **Utilities**: Docker CLI, Docker Compose, Git, Make, Nano, Curl, Unzip, Tree, Bash

## Getting Started

### Prerequisites

- Docker
- Docker Compose
- Access to Docker socket (`/var/run/docker.sock`)

### Build the Image

```bash
docker-compose build
```

### Start the Container

```bash
docker-compose up -d
```

### Access the Container

```bash
docker exec -it bunny bash
```

Or use the attached shell:

```bash
docker attach bunny
```

### Check Status

```bash
docker-compose ps
docker-compose logs -f
```

### Stop the Container

```bash
docker-compose down
```

## Configuration

### Volume Mounts

Modify `docker-compose.yml` to adjust volume mounts:

```yaml
volumes:
  # Add your own mounts
  - /path/to/your/project:/workspace
  - ~/.config/your-tool:/root/.config/your-tool
```

### Environment Variables

Key environment variables set in the container:

- `TERM=xterm-256color` - Terminal type
- `SSH_AUTH_SOCK` - SSH agent socket (from host)
- `HOSTNAME=bunny` - Container hostname

### Network

The container uses `bridge` network mode. To change:

```yaml
network_mode: host  # For full host network access
# or
networks:
  - your_network
```

### Privileged Mode

The container runs in `privileged: true` mode for:
- Docker-in-Docker operations
- Full device access

> **Warning**: Privileged mode grants the container near-host privileges. Only use in trusted environments.

## Health Check

The container includes a health check that verifies the aliases file is mounted:

```yaml
healthcheck:
  test: ["CMD", "test", "-d", "/etc/profile.d/aliases.sh"]
  interval: 30s
  timeout: 10s
  retries: 3
  start_period: 10s
```

## Customization

### Adding New Tools

Edit `Dockerfile` to add new tools:

```dockerfile
RUN bun i -g your-new-tool
# or
RUN apt install -yf new-package
```

### Modifying Default Shell

The container uses bash with fnm for Node.js version management. To change:

```dockerfile
# Add to Dockerfile
RUN echo 'eval "$($FNM_DIR/fnm env --shell bash)"' >> /etc/bash.bashrc
RUN $FNM_DIR/fnm i <version> && $FNM_DIR/ffnm default <version>
```

### Changing Default User

Currently runs as root. To add a non-root user:

```yaml
user: "1000:1000"
```

## Troubleshooting

### Container Won't Start

Check logs:
```bash
docker-compose logs
```

Verify volume paths exist on host:
```bash
ls -la /var/run/docker.sock
ls -la ~/.local/share/opencode
```

### SSH Auth Not Working

Ensure `SSH_AUTH_SOCK` is set on host:
```bash
echo $SSH_AUTH_SOCK
```

### Docker-in-Docker Not Working

Verify socket permissions:
```bash
ls -la /var/run/docker.sock
```

The container needs read/write access to the Docker socket.

### Network Issues

If network connectivity fails, check bridge configuration:
```bash
docker network inspect bridge
```

## Security Considerations

1. **Privileged Mode**: Grants extensive host access - use only in trusted environments
2. **Docker Socket**: Allows container to control host Docker daemon
3. **Read-only Mounts**: Use `:ro` suffix for read-only access (e.g., `/host/path:/container/path:ro`)
4. **Volume Review**: Regularly audit mounted directories

## Project Structure

```
bunny/
├── Dockerfile              # Container image definition
├── docker-compose.yml     # Container orchestration
├── README.md              # This file
└── openclaw/              # OpenClaw configuration
    ├── agents/            # Agent definitions
    ├── skills/            # Agent skills
    ├── workspace/         # Working directory
    ├── openclaw.json      # Main configuration
    └── ...
```

## License

MIT
