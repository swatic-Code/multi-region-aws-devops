# ---- Stage 1: install production dependencies ----
FROM node:20-alpine AS deps
WORKDIR /app
COPY package*.json ./
RUN npm ci --omit=dev

# ---- Stage 2: minimal runtime image ----
FROM node:20-alpine
ENV NODE_ENV=production PORT=3000
WORKDIR /app
RUN apk upgrade --no-cache
COPY --from=deps /app/node_modules ./node_modules
COPY --chown=node:node package*.json server.js ./
COPY --chown=node:node public ./public
USER node
EXPOSE 3000
HEALTHCHECK --interval=30s --timeout=3s CMD wget -qO- http://localhost:3000/health || exit 1
CMD ["node", "server.js"]
