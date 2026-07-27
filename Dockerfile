FROM node:24.14.1-bookworm AS build
ARG SOURCE_SHA=unknown
ARG SOURCE_REF=main
ARG REACT_APP_API_URL=https://ai-model-index-server.onrender.com
ENV CI=true
ENV REACT_APP_API_URL=${REACT_APP_API_URL}
RUN npm install --global npm@11.11.0 @wasp.sh/wasp-cli@0.24.0
WORKDIR /app
COPY source/ ./
RUN node --version && npm --version && wasp version && wasp install && wasp build
RUN npx vite build \
 && cp .wasp/out/web-app/build/200.html .wasp/out/web-app/build/index.html \
 && rm .wasp/out/web-app/build/200.html \
 && node scripts/generate-seo-shells.mjs .wasp/out/web-app/build \
 && RENDER=true RENDER_GIT_COMMIT="$SOURCE_SHA" RENDER_GIT_BRANCH="$SOURCE_REF" RENDER_SERVICE_NAME="ai-model-index-client-v2" \
    node scripts/write-release-metadata.mjs .wasp/out/web-app/build/release.json --service ai-model-index-client-v2
RUN bash scripts/patch-generated-server.sh \
 && cd .wasp/out/server \
 && npm install \
 && npx prisma generate --schema=../db/schema.prisma \
 && npm run bundle

FROM node:24.14.1-bookworm-slim AS runtime
RUN apt-get update \
 && apt-get install -y --no-install-recommends nginx ca-certificates \
 && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY --from=build /app/.wasp/out /app/.wasp/out
COPY runtime/nginx.conf /etc/nginx/conf.d/default.conf
COPY runtime/proxy_params /etc/nginx/proxy_params
COPY runtime/entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh && nginx -t
ENV NODE_ENV=production
EXPOSE 10000
ENTRYPOINT ["/app/entrypoint.sh"]
