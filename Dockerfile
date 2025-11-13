# syntax=docker/dockerfile:1

# --- Base builder image ---
FROM node:20-bookworm-slim AS builder

ENV NODE_ENV=production
WORKDIR /app

# Enable corepack and pin Yarn to repo's version
RUN corepack enable
RUN corepack prepare yarn@3.6.1 --activate \
    && yarn --version

# Install OS deps commonly required by Next.js/sharp
RUN apt-get update -y && apt-get install -y --no-install-recommends \
    ca-certificates \
    dumb-init \
    git \
    && rm -rf /var/lib/apt/lists/*

# Install dependencies first (better layer caching)
COPY package.json yarn.lock ./
# Configure Yarn to use node_modules linker globally and install deps
RUN yarn config set nodeLinker node-modules -H \
    && yarn install --immutable

# Copy the rest of the source
COPY . .

# Build-time environment (provided via build args)
ARG NEXT_PUBLIC_URL
ARG NEXT_PUBLIC_GISCUS_REPO
ARG NEXT_PUBLIC_GISCUS_REPOSITORY_ID
ARG NEXT_PUBLIC_GISCUS_CATEGORY
ARG NEXT_PUBLIC_GISCUS_CATEGORY_ID
ARG NEXT_PUBLIC_HOME_URL
ARG NEXT_PUBLIC_UTTERANCES_REPO
ARG NEXT_PUBLIC_DISQUS_SHORTNAME
ARG NEXT_UMAMI_ID

ENV NEXT_PUBLIC_URL=$NEXT_PUBLIC_URL \
    NEXT_PUBLIC_GISCUS_REPO=$NEXT_PUBLIC_GISCUS_REPO \
    NEXT_PUBLIC_GISCUS_REPOSITORY_ID=$NEXT_PUBLIC_GISCUS_REPOSITORY_ID \
    NEXT_PUBLIC_GISCUS_CATEGORY=$NEXT_PUBLIC_GISCUS_CATEGORY \
    NEXT_PUBLIC_GISCUS_CATEGORY_ID=$NEXT_PUBLIC_GISCUS_CATEGORY_ID \
    NEXT_PUBLIC_HOME_URL=$NEXT_PUBLIC_HOME_URL \
    NEXT_PUBLIC_UTTERANCES_REPO=$NEXT_PUBLIC_UTTERANCES_REPO \
    NEXT_PUBLIC_DISQUS_SHORTNAME=$NEXT_PUBLIC_DISQUS_SHORTNAME \
    NEXT_UMAMI_ID=$NEXT_UMAMI_ID

# Build the Next.js app (standalone output is configured in next.config.js)
ENV NEXT_TELEMETRY_DISABLED=1
RUN yarn build

# --- Runtime image ---
FROM node:20-bookworm-slim AS runner

ENV NODE_ENV=production \
    NEXT_TELEMETRY_DISABLED=1 \
    PORT=3000

WORKDIR /app

# Install minimal runtime deps
RUN apt-get update -y && apt-get install -y --no-install-recommends \
    ca-certificates \
    dumb-init \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user context (node user already exists in the image)
RUN mkdir -p /app/.next /app/public \
  && chown -R node:node /app

# Copy the standalone server and static assets from builder
COPY --from=builder --chown=node:node /app/.next/standalone ./
COPY --from=builder --chown=node:node /app/public ./public
COPY --from=builder --chown=node:node /app/.next/static ./.next/static
COPY --from=builder --chown=node:node /app/.contentlayer ./.contentlayer

USER node

EXPOSE 3000

# Use dumb-init for signal handling and zombie reaping
ENTRYPOINT ["/usr/bin/dumb-init", "--"]

# Start the server produced by Next.js standalone build
CMD ["node", "server.js"]
