# Build stage
FROM node:20-alpine AS build-stage

WORKDIR /app

# Copy package files (pnpm lockfile used)
COPY package.json pnpm-lock.yaml ./

# Install dependencies using pnpm (project uses pnpm)
# Use Corepack to activate pnpm and install with frozen lockfile
RUN corepack enable && \
    corepack prepare pnpm@8.10.0 --activate && \
    # Install dev dependencies so the build tooling (vite) is available
    pnpm install --frozen-lockfile

# Copy source code
COPY . .

# Build the app
RUN npm run build

# Production stage
FROM nginx:1.25-alpine AS production-stage

# Copy built assets from build stage
COPY --from=build-stage /app/dist /usr/share/nginx/html

# Ensure that any static public assets (images/icons) are also copied into the
# production image root. Vite copies `public/` to `dist/` in most setups, but
# copying `public/` explicitly prevents missing-files when `base` or plugins
# changed the output layout. Also copy public images to both `/images` and
# `/icons` to support different asset paths without needing to regenerate the
# build.
COPY public/ /usr/share/nginx/html/
RUN if [ -d /usr/share/nginx/html/images ]; then cp -r /usr/share/nginx/html/images /usr/share/nginx/html/icons || true; fi

# Copy nginx configuration
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Add non-root user for nginx
RUN chown -R nginx:nginx /usr/share/nginx/html && \
    chown -R nginx:nginx /var/cache/nginx && \
    chown -R nginx:nginx /var/log/nginx && \
    touch /var/run/nginx.pid && \
    chown -R nginx:nginx /var/run/nginx.pid

# Switch to non-root user
USER nginx

# Expose port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:3000/health || exit 1

# Start nginx
CMD ["nginx", "-g", "daemon off;"]