FROM ghcr.io/puppeteer/puppeteer:23.4.0

ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true \
    PUPPETEER_EXECUTABLE_PATH=/usr/.cache\puppeteer\chrome\win64-129.0.6668.58\chrome-win64\chrome.exe

WORKDIR /usr/src/app

COPY package*.json ./
RUN npm ci
COPY . .
CMD [ "node", "index.js" ]

