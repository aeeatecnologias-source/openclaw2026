FROM node:22-bookworm-slim AS builder

RUN npm install -g pnpm@10.23.0
RUN corepack enable

WORKDIR /app

COPY package.json pnpm-lock.yaml pnpm-workspace.yaml .npmrc ./
COPY ui/package.json ./ui/package.json
COPY patches ./patches
COPY scripts ./scripts

ENV NODE_LLAMA_CPP_SKIP_DOWNLOAD=true
ENV PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1

RUN pnpm install --frozen-lockfile --ignore-scripts

COPY . .

RUN pnpm build
RUN pnpm ui:build

RUN pnpm prune --prod

FROM node:22-bookworm-slim

RUN npm install -g pnpm@10.23.0
RUN corepack enable

WORKDIR /app
RUN chown -R node:node /app
USER node

COPY --from=builder --chown=node:node /app/dist ./dist
COPY --from=builder --chown=node:node /app/node_modules ./node_modules
COPY --from=builder --chown=node:node /app/package.json ./package.json
COPY --from=builder --chown=node:node /app/openclaw.mjs ./openclaw.mjs
COPY --from=builder --chown=node:node /app/assets ./assets
COPY --from=builder --chown=node:node /app/extensions ./extensions
COPY --from=builder --chown=node:node /app/skills ./skills

ENV NODE_ENV=production
ENV PORT=18789

EXPOSE 18789

CMD ["node", "openclaw.mjs", "gateway", "run"]
