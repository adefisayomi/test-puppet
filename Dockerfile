FROM ghcr.io/puppeteer/puppeteer:19.7.2

USER root

# Install dependencies and add Google Chrome's GPG key
RUN apt-get update && \
    apt-get install -y wget xvfb gnupg2 && \
    wget -q -O /usr/share/keyrings/google.gpg https://dl.google.com/linux/linux_signing_key.pub && \
    echo "deb [signed-by=/usr/share/keyrings/google.gpg] https://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list && \
    apt-get update && \
    apt-get install -y google-chrome-stable && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

USER node

ENV DISPLAY=:99

ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true \
    PUPPETEER_EXECUTABLE_PATH=/usr/bin/google-chrome-stable

WORKDIR /usr/src/app

COPY package*.json ./
RUN npm ci
COPY . .

# Start xvfb and run the application
CMD ["sh", "-c", "Xvfb :99 -screen 0 1280x720x24 & node index.js"]
