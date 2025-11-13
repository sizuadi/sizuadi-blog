# Blog

## Docker deployment

This repo includes a production-ready Dockerfile and docker-compose.yml to run the Next.js app on a VPS.

Prerequisites on the VPS:

- Docker Engine 24+
- Docker Compose v2

Build and run with Docker (PowerShell):

```powershell
# Build image
docker build -t sizu-blog:latest .

# Run container on port 3000
docker run -d --name sizu-blog -p 3000:3000 --restart unless-stopped sizu-blog:latest
```

Or with Compose:

```powershell
docker compose up -d --build
```

Update to a new version:

```powershell
docker compose pull ; docker compose up -d --build ; docker image prune -f
```

Environment variables:

- Create a `.env` file (not committed) at the project root if you need runtime configuration.
- Uncomment `env_file` in `docker-compose.yml` to load it.

Access: http://YOUR_SERVER_IP:3000
