# Multi-stage build for optimized production image
ARG NODE_VERSION=20

# Build stage
FROM registry.access.redhat.com/ubi8/nodejs-20:latest AS builder

# Set working directory
WORKDIR /opt/app-root/src

# Copy package files
COPY package.json pnpm-lock.yaml ./

# Install pnpm and dependencies
RUN npm install -g pnpm@10.5.1
RUN pnpm install --frozen-lockfile

# Copy source code
COPY . .

# Build the application
RUN pnpm build

# Production stage
FROM registry.access.redhat.com/ubi8/nodejs-20:latest AS runner

# Install pnpm in production image
RUN npm install -g pnpm@10.5.1

# Create app directory with proper permissions
WORKDIR /opt/app-root/src

# Copy package files for production dependencies
COPY package.json pnpm-lock.yaml ./

# Install dependencies (including next.js which is in devDependencies but needed for production)
RUN pnpm install --frozen-lockfile && \
    pnpm store prune && \
    npm cache clean --force

# Copy built application from builder stage
COPY --from=builder /opt/app-root/src/.next ./.next
COPY --from=builder /opt/app-root/src/public ./public

# Create next.config.mjs
COPY next.config.mjs ./

# Create cache directory with proper group permissions
RUN mkdir -p /opt/app-root/src/.next/cache && \
    chmod -R g+rwX /opt/app-root/src/.next/cache

# Expose port 8080 (OpenShift standard)
EXPOSE 8080

# Set environment variables
ENV NODE_ENV=production
ENV PORT=8080
ENV HOSTNAME="0.0.0.0"

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD node -e "const http = require('http'); const req = http.request('http://localhost:8080/api/health', res => process.exit(res.statusCode === 200 ? 0 : 1)); req.on('error', () => process.exit(1)); req.end();"

# Start the application
CMD ["pnpm", "start"]
