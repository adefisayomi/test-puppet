# Use Puppeteer image with version 23.3.1
FROM ghcr.io/puppeteer/puppeteer:23.3.1

# Set environment variables to skip Chromium download and define Chrome executable path
ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true \
    PUPPETEER_EXECUTABLE_PATH=/usr/bin/google-chrome-stable

# Install necessary fonts and system dependencies for Puppeteer and Chrome
# RUN apt-get update \
#     && apt-get install -y --no-install-recommends fonts-ipafont-gothic fonts-wqy-zenhei fonts-thai-tlwg fonts-khmeros \
#     fonts-kacst fonts-freefont-ttf dbus dbus-x11

# Set working directory inside the container
WORKDIR /usr/src/app

# Copy package.json and package-lock.json (or yarn.lock) and install dependencies
COPY package*.json ./
RUN npm ci

# Copy the Puppeteer configuration file
COPY puppeteer.config.js ./

# Copy the rest of the application code
COPY . .

# Define the default command to run the application
CMD [ "node", "index.js" ]
