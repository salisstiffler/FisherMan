FROM node:22-alpine

WORKDIR /app

# Copy dependency manifests
COPY package*.json ./

# Install dependencies cleanly
RUN npm ci --only=production

# Copy application source code
COPY . .

# Expose HTTP port
EXPOSE 8080

# Environment defaults
ENV NODE_ENV=production \
    PORT=8080 \
    HOST=0.0.0.0 \
    DB_PATH=/app/data/fisherman.db

# Persistent volume for SQLite database & uploaded photos
VOLUME ["/app/data", "/app/public/uploads"]

CMD ["node", "src/server.js"]
