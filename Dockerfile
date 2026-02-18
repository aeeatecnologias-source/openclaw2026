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

FROM node:22-bookworm-slim

RUN npm install -g pnpm@10.23.0
RUN corepack enable

WORKDIR /app

COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package.json ./package.json
COPY --from=builder /app/openclaw.mjs ./openclaw.mjs
COPY --from=builder /app/extensions ./extensions
COPY --from=builder /app/skills ./skills

ENV NODE_ENV=production
ENV PORT=18789
ENV NODE_LLAMA_CPP_SKIP_DOWNLOAD=true
ENV PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1
ENV NODE_OPTIONS=--max-old-space-size=1536

EXPOSE 18789

CMD ["node", "openclaw.mjs", "gateway", "run", "--allow-unconfigured", "--port", "18789", "--bind", "lan"]
