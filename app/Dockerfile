# Use lightweight official Node image
FROM node:20-alpine
WORKDIR /app
COPY . .
RUN npm install
RUN addgroup -S appgroup && adduser -S appuser -G appgroup && chown -R appuser:appgroup /app
USER appuser
EXPOSE 3000
CMD ["node", "index.js"]
