# Use lightweight Node.js base image
FROM node:18-alpine

# Set working directory
WORKDIR /usr/src/app

# Copy package files first for efficient caching
COPY package*.json ./

# Install only production dependencies
RUN npm ci --only=production

# Copy application code
COPY . .

# Install curl for ECS health check
RUN apk add --no-cache curl

# Expose the API port
EXPOSE 3101

# Run the app
CMD ["node", "app.js"]
