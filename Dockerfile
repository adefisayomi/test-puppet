# FROM ghcr.io/puppeteer/puppeteer:23.4.0

# ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true \
#     PUPPETEER_EXECUTABLE_PATH=/usr/bin/google-chrome-stable

# WORKDIR /usr/src/app

# COPY package*.json ./
# RUN npm ci
# COPY . .
# CMD [ "node", "index.js" ]
FROM ghcr.io/puppeteer/puppeteer:23.4.0 as base

WORKDIR /app

USER root

RUN apt-get update && \
    apt-get install -y tini && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

ARG SCOPE
ENV SCOPE=$SCOPE

ARG PACKAGE_CONTAINERS="apps packages"
ARG CLEANING_TARGETS="src test .turbo .eslintrc.* jest.config.* tsup.config.* tsconfig.*"

ARG PORT=4000
ENV PORT=$PORT

RUN corepack enable
RUN npm install -g turbo

FROM base as pruner
RUN npm fetch
ADD . .
RUN turbo prune --scope=$SCOPE --docker

FROM base as installer
COPY --from=pruner /app/out/full .
COPY --from=pruner /app/out/npm-lock.yaml .
RUN npm install -r

FROM base as builder
COPY --from=installer /app .
RUN npm run build --filter=$SCOPE

FROM base as runner
COPY --from=builder /app .
RUN npm install -r --prod --ignore-scripts
RUN for c in $PACKAGE_CONTAINERS; do \
    for t in $CLEANING_TARGETS; do \
    rm -rf ./$c/*/$t; \
    done; \
    done;
EXPOSE $PORT

RUN chown -R pptruser:pptruser /app
USER pptruser

ENTRYPOINT ["/usr/bin/tini", "--"]
CMD npm --filter=$SCOPE run start
