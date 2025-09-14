# Use official Node.js image
FROM node:18

# Set working directory
WORKDIR /app

# Copy package files first (better for caching)
COPY package*.json ./

# Install dependencies
RUN npm install

# Copy rest of the app
COPY . .

# Expose port (same as your app uses, e.g., 3000)
EXPOSE 3000

# Start the app
CMD ["npm", "start"]
