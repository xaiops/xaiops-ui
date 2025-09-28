# Container Deployment Guide

This guide provides step-by-step instructions for containerizing and deploying the Mortgage Assistant UI application using Podman and OpenShift.

## Prerequisites

- Podman installed (or Docker as alternative)
- OpenShift CLI (`oc`) installed (for OpenShift deployment)
- Access to an OpenShift cluster
- PNPM package manager

## Files Overview

- `Containerfile` - Multi-stage container build definition
- `.containerignore` - Files to exclude from container build context
- `k8s/deployment.yaml` - Kubernetes/OpenShift deployment manifest
- `k8s/route.yaml` - OpenShift route for external access

## Step 1: Local Development with Podman

### Build the Container Image

```bash
# Build the container image
podman build -t quay.io/rbrhssa/mortgage-agent-ui:latest -f Containerfile .

# Alternative with specific tag
podman build -t quay.io/rbrhssa/mortgage-agent-ui:v1.0.0 -f Containerfile .
```

### Run Container Locally

```bash
# Run with basic configuration
podman run -d \
  --name mortgage-assistant-ui \
  -p 8080:8080 \
  -e NODE_ENV=production \
  -e LANGGRAPH_API_URL=http://host.containers.internal:2024 \
  quay.io/rbrhssa/mortgage-agent-ui:latest

# Run with volume mounts for development
podman run -d \
  --name mortgage-assistant-ui-dev \
  -p 8080:8080 \
  -e NODE_ENV=production \
  -v ./config:/opt/app-root/src/config:Z \
  mortgage-assistant-ui:latest
```

### Container Management

```bash
# Check container status
podman ps

# View logs
podman logs mortgage-assistant-ui

# Stop container
podman stop mortgage-assistant-ui

# Remove container
podman rm mortgage-assistant-ui

# Remove image
podman rmi mortgage-assistant-ui:latest
```

## Step 2: Push to Registry

### Tag and Push to Registry

```bash
# Tag for your registry
podman tag mortgage-assistant-ui:latest your-registry.com/mortgage-assistant-ui:latest

# Push to registry
podman push your-registry.com/mortgage-assistant-ui:latest

# For OpenShift internal registry
podman tag mortgage-assistant-ui:latest image-registry.openshift-image-registry.svc:5000/your-namespace/mortgage-assistant-ui:latest
```

## Step 3: Deploy to OpenShift

### Login to OpenShift

```bash
# Login to your OpenShift cluster
oc login https://your-openshift-cluster.com

# Create or switch to your project/namespace
oc new-project mortgage-assistant-ui
# or
oc project mortgage-assistant-ui
```

### Configure Application Settings

```bash
# Update the ConfigMap with your specific values
oc apply -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  langgraph-api-url: "https://your-actual-langgraph-api.example.com"
  api-base-url: "https://your-actual-api.example.com"
EOF
```

### Deploy the Application

```bash
# Apply all manifests
oc apply -f k8s/

# Or apply individually
oc apply -f k8s/configmap.yaml
oc apply -f k8s/deployment.yaml  
oc apply -f k8s/service.yaml
oc apply -f k8s/route.yaml

# Or use Kustomize
oc apply -k k8s/

# Check deployment status
oc get deployments
oc get pods
oc get services
oc get routes
```

### Verify Deployment

```bash
# Check pod status
oc get pods -l app=mortgage-assistant-ui

# View pod logs
oc logs -l app=mortgage-assistant-ui

# Get route URL
oc get route mortgage-assistant-ui-route -o jsonpath='{.spec.host}'

# Test the application
curl https://$(oc get route mortgage-assistant-ui-route -o jsonpath='{.spec.host}')
```

## Environment Variables Configuration

### Required Environment Variables

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `NODE_ENV` | Node.js environment | `production` | Yes |
| `PORT` | Application port | `8080` | Yes |
| `HOSTNAME` | Bind hostname | `0.0.0.0` | Yes |
| `LANGGRAPH_API_URL` | LangGraph API endpoint | - | Yes |
| `API_BASE_URL` | Base API URL | - | Optional |

### Configure via ConfigMap

```bash
# Create ConfigMap
oc create configmap app-config \
  --from-literal=langgraph-api-url=https://your-api.example.com \
  --from-literal=api-base-url=https://your-base-api.example.com

# Or update existing ConfigMap
oc patch configmap app-config -p '{"data":{"langgraph-api-url":"https://new-api.example.com"}}'
```

### Configure via Environment Variables

```bash
# Set environment variables in deployment
oc set env deployment/mortgage-assistant-ui LANGGRAPH_API_URL=https://your-api.example.com
```

## Scaling and Management

### Scale the Application

```bash
# Scale to 3 replicas
oc scale deployment/mortgage-assistant-ui --replicas=3

# Check scaling status
oc get deployment mortgage-assistant-ui
```

### Update the Application

```bash
# Update image
oc set image deployment/mortgage-assistant-ui mortgage-assistant-ui=your-registry.com/mortgage-assistant-ui:v1.1.0

# Check rollout status
oc rollout status deployment/mortgage-assistant-ui

# Rollback if needed
oc rollout undo deployment/mortgage-assistant-ui
```

## Security Considerations

### Security Context Constraints (SCC)

The application runs with the `restricted` SCC by default:

- Non-root user (UID 1001)
- No privileged escalation
- Read-only root filesystem capability
- Drops all capabilities

### Network Policies

```bash
# Apply network policy for additional security
oc apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: mortgage-assistant-ui-netpol
spec:
  podSelector:
    matchLabels:
      app: mortgage-assistant-ui
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector: {}
    ports:
    - protocol: TCP
      port: 8080
  egress:
  - to: []
    ports:
    - protocol: TCP
      port: 443
    - protocol: TCP
      port: 80
    - protocol: UDP
      port: 53
EOF
```

## Troubleshooting

### Common Issues

1. **Permission Denied**: Ensure the container runs as non-root user (UID 1001)
2. **Image Pull Errors**: Verify registry credentials and image name
3. **Application Won't Start**: Check environment variables and logs
4. **Route Not Accessible**: Verify route configuration and DNS

### Debug Commands

```bash
# Get detailed pod information
oc describe pod -l app=mortgage-assistant-ui

# Get events
oc get events --sort-by=.metadata.creationTimestamp

# Access pod shell for debugging
oc rsh deployment/mortgage-assistant-ui

# Port forward for testing
oc port-forward deployment/mortgage-assistant-ui 8080:8080
```

### Monitoring and Observability

```bash
# View resource usage
oc top pods -l app=mortgage-assistant-ui

# Check liveness/readiness probes
oc describe pod -l app=mortgage-assistant-ui | grep -A 10 "Liveness\|Readiness"
```

## Performance Tuning

### Resource Requests and Limits

Update resource specifications in `k8s/deployment.yaml`:

```yaml
resources:
  requests:
    memory: "512Mi"
    cpu: "200m"
  limits:
    memory: "1Gi"
    cpu: "1000m"
```

### Horizontal Pod Autoscaler

```bash
# Create HPA
oc autoscale deployment mortgage-assistant-ui --cpu-percent=70 --min=2 --max=10

# Check HPA status
oc get hpa
```

## Cleanup

```bash
# Delete application resources
oc delete -f k8s/

# Delete ConfigMap
oc delete configmap app-config

# Delete project (if desired)
oc delete project mortgage-assistant-ui
```
