# Quay.io Public Registry Deployment Guide

This guide covers building and pushing the Mortgage Agent UI to Quay.io for public distribution.

## Registry Information
- **Registry**: `quay.io`
- **Repository**: `rbrhssa/mortgage-agent-ui`
- **Full Image Name**: `quay.io/rbrhssa/mortgage-agent-ui:latest`

## Prerequisites

1. **Quay.io Account**: Sign up at https://quay.io
2. **Repository Setup**: Create the `mortgage-agent-ui` repository in your Quay.io account
3. **Podman/Docker**: Container tool installed
4. **Authentication**: Login credentials for Quay.io

## Step 1: Login to Quay.io

```bash
# Login to Quay.io registry
podman login quay.io

# You'll be prompted for:
# Username: rbrhssa
# Password: [your-quay-token-or-password]
```

## Step 2: Build Image

```bash
# Build with Quay.io tag
podman build -t quay.io/rbrhssa/mortgage-agent-ui:latest -f Containerfile .

# Build with version tag
podman build -t quay.io/rbrhssa/mortgage-agent-ui:v1.0.0 -f Containerfile .

# Build with both tags
podman build -t quay.io/rbrhssa/mortgage-agent-ui:latest -t quay.io/rbrhssa/mortgage-agent-ui:v1.0.0 -f Containerfile .
```

## Step 3: Test Locally

```bash
# Test the image locally first
podman run -d --name test-mortgage-ui \
  -p 8080:8080 \
  -e NODE_ENV=production \
  -e LANGGRAPH_API_URL=http://host.containers.internal:2024 \
  quay.io/rbrhssa/mortgage-agent-ui:latest

# Test endpoints
curl http://localhost:8080/api/health
curl -I http://localhost:8080/

# Clean up test
podman stop test-mortgage-ui && podman rm test-mortgage-ui
```

## Step 4: Push to Quay.io

```bash
# Push latest tag
podman push quay.io/rbrhssa/mortgage-agent-ui:latest

# Push version tag
podman push quay.io/rbrhssa/mortgage-agent-ui:v1.0.0

# Or push all tags
podman push --all-tags quay.io/rbrhssa/mortgage-agent-ui
```

## Step 5: Verify Public Access

```bash
# Pull the image from public registry (no login required for public images)
podman pull quay.io/rbrhssa/mortgage-agent-ui:latest

# Run the public image
podman run -d --name mortgage-ui-public \
  -p 8080:8080 \
  -e LANGGRAPH_API_URL=http://host.containers.internal:2024 \
  quay.io/rbrhssa/mortgage-agent-ui:latest
```

## Step 6: Update Kubernetes Deployments

The Kubernetes manifests are already updated to use the Quay.io image:

```yaml
# k8s/deployment.yaml
containers:
- name: mortgage-assistant-ui
  image: quay.io/rbrhssa/mortgage-agent-ui:latest
```

## Automated Build & Push Using Makefile

```bash
# Build the image
make build

# Push to Quay.io (requires login)
make push

# Build and push in one command
make build push
```

## Repository Configuration

### Make Repository Public

1. Go to https://quay.io/repository/rbrhssa/mortgage-agent-ui
2. Click on "Settings" tab
3. Change "Repository Visibility" to "Public"
4. Save changes

### Set Up Automated Builds (Optional)

1. In repository settings, go to "Builds" tab
2. Connect to GitHub repository
3. Configure build triggers for automated builds on git push

## Tags and Versioning Strategy

```bash
# Development builds
podman build -t quay.io/rbrhssa/mortgage-agent-ui:dev-$(date +%Y%m%d) -f Containerfile .

# Release builds
podman build -t quay.io/rbrhssa/mortgage-agent-ui:v1.0.0 -f Containerfile .
podman build -t quay.io/rbrhssa/mortgage-agent-ui:latest -f Containerfile .

# Push both version and latest
podman push quay.io/rbrhssa/mortgage-agent-ui:v1.0.0
podman push quay.io/rbrhssa/mortgage-agent-ui:latest
```

## OpenShift Deployment with Quay.io

```bash
# Deploy using public Quay.io image
oc apply -f k8s/deployment.yaml

# Update image in existing deployment
oc set image deployment/mortgage-assistant-ui \
  mortgage-assistant-ui=quay.io/rbrhssa/mortgage-agent-ui:v1.1.0

# Check deployment status
oc rollout status deployment/mortgage-assistant-ui
```

## Security Considerations

### Using Robot Accounts for CI/CD

1. Create a robot account in Quay.io:
   - Go to Account Settings > Robot Accounts
   - Create robot with write permissions
   - Use robot credentials in CI/CD pipelines

```bash
# Login with robot account
echo $QUAY_ROBOT_TOKEN | podman login quay.io --username $QUAY_ROBOT_USER --password-stdin

# Push using robot account
podman push quay.io/rbrhssa/mortgage-agent-ui:latest
```

### Image Scanning

Quay.io automatically scans images for vulnerabilities:

1. Check scan results in repository page
2. View vulnerability details
3. Set up notifications for new vulnerabilities

## Troubleshooting

### Authentication Issues

```bash
# Check login status
podman system info | grep -A5 registries

# Re-login if needed
podman logout quay.io
podman login quay.io
```

### Push Failures

```bash
# Check image exists locally
podman images | grep mortgage-agent-ui

# Check repository permissions
# - Verify repository exists in Quay.io
# - Check write permissions
# - Verify repository visibility settings
```

### Pull Issues

```bash
# For private repositories, ensure login
podman login quay.io

# For public repositories, no login required
podman pull quay.io/rbrhssa/mortgage-agent-ui:latest
```

## Image Information

- **Base Image**: Red Hat UBI8 with Node.js 20
- **Size**: ~2GB (optimized multi-stage build)
- **Architecture**: linux/amd64
- **Security**: Non-root user (UID 1001), OpenShift SCC compliant

## Usage Examples

### Quick Start
```bash
podman run -p 8080:8080 \
  -e LANGGRAPH_API_URL=http://host.containers.internal:2024 \
  quay.io/rbrhssa/mortgage-agent-ui:latest
```

### With Custom Configuration
```bash
podman run -p 8080:8080 \
  -e NODE_ENV=production \
  -e LANGGRAPH_API_URL=https://your-langgraph-api.com \
  -e API_BASE_URL=https://your-api.com \
  quay.io/rbrhssa/mortgage-agent-ui:latest
```

### Docker Compose Example
```yaml
version: '3.8'
services:
  mortgage-ui:
    image: quay.io/rbrhssa/mortgage-agent-ui:latest
    ports:
      - "8080:8080"
    environment:
      - NODE_ENV=production
      - LANGGRAPH_API_URL=http://host.docker.internal:2024
```

## Support

For issues with the container image, check:

1. **Health Endpoint**: `http://localhost:8080/api/health`
2. **Container Logs**: `podman logs <container-name>`
3. **Repository Issues**: https://github.com/your-repo/issues
