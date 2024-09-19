# Use Puppeteer's Docker image as the base
FROM ghcr.io/puppeteer/puppeteer:19.7.2

# Set environment variables to configure Puppeteer
ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true \
    PUPPETEER_EXECUTABLE_PATH=/usr/bin/google-chrome-stable

# Install Chromium dependencies manually if necessary
RUN apt-get update && apt-get install -y \
    wget \
    gnupg \
    ca-certificates \
    --no-install-recommends

# Add Google's signing key and setup the Chrome stable repository
RUN wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - \
    && sh -c 'echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google-chrome.list'

# Install the latest version of Chrome Stable
RUN apt-get update && apt-get install -y \
    google-chrome-stable \
    --no-install-recommends

# Clean up the unnecessary files
RUN apt-get purge --auto-remove -y gnupg wget ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Set working directory for the application
WORKDIR /usr/src/app

# Copy package.json and install dependencies
COPY package*.json ./
RUN npm ci

# Copy the rest of the application files
COPY . .

# Expose the default port (optional, in case your app needs it)
EXPOSE 3000

# Run the application
CMD ["node", "index.js"]
