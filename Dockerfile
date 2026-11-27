# EmDash (Astro + SQLite) — imagen para Easypanel / Docker
FROM node:24-slim AS builder
WORKDIR /app

COPY package.json package-lock.json ./
RUN npm ci

COPY . .
# URL pública opcional en build (optimiza imágenes de páginas prerenderizadas)
ARG EMDASH_SITE_URL
ENV EMDASH_SITE_URL=${EMDASH_SITE_URL}
RUN npm run build && npm prune --omit=dev

# ---- Runtime ----
FROM node:24-slim
WORKDIR /app
ENV NODE_ENV=production \
    HOST=0.0.0.0 \
    PORT=4321

COPY --from=builder /app/package.json ./
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/dist ./dist

# SQLite (data/data.db) y medios (data/uploads) viven en este volumen
RUN mkdir -p /app/data/uploads
VOLUME ["/app/data"]

EXPOSE 4321
HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
  CMD node -e "fetch('http://127.0.0.1:'+(process.env.PORT||4321)+'/health').then(r=>process.exit(r.ok?0:1)).catch(()=>process.exit(1))"

# Docker espera 10 s al parar; EmDash necesita >5 s para cerrar salas de co-edición
STOPSIGNAL SIGTERM
CMD ["node", "./dist/server/entry.mjs"]
