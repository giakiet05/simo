# ==============================================================================
# Multi-stage Dockerfile for Simo Web Management Frontend
# ==============================================================================

# ------------------------------------------------------------------------------
# Stage 1: Build static assets
# ------------------------------------------------------------------------------
FROM node:22-slim AS builder

WORKDIR /app

# Install dependencies with lockfile
COPY package.json package-lock.json ./
RUN npm ci

# Copy source files
COPY . .

# Build Vite SPA
ARG VITE_API_BASE_URL
ENV VITE_API_BASE_URL=$VITE_API_BASE_URL
RUN npm run build

# ------------------------------------------------------------------------------
# Stage 2: Serve with Nginx
# ------------------------------------------------------------------------------
FROM nginx:alpine

# Remove default nginx static files
RUN rm -rf /usr/share/nginx/html/*

# Copy build artifacts and configuration
COPY --from=builder /app/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
