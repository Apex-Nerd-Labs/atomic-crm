# syntax=docker/dockerfile:1
#
# Publishable key must be supplied as a BuildKit secret (not ARG/ENV), e.g.:
#   docker build --secret id=vite_sb_publishable_key,env=VITE_SB_PUBLISHABLE_KEY ...
#   docker build --secret id=vite_sb_publishable_key,src=./sb_publishable_key.txt ...

# --- build ---
FROM node:22-alpine AS builder
WORKDIR /app

COPY package.json package-lock.json ./
RUN npm ci

COPY . .

ARG VITE_SUPABASE_URL
ARG VITE_IS_DEMO=false
ARG VITE_INBOUND_EMAIL=
ARG VITE_ATTACHMENTS_BUCKET=attachments

ENV NODE_ENV=production \
    VITE_SUPABASE_URL=${VITE_SUPABASE_URL} \
    VITE_IS_DEMO=${VITE_IS_DEMO} \
    VITE_INBOUND_EMAIL=${VITE_INBOUND_EMAIL} \
    VITE_ATTACHMENTS_BUCKET=${VITE_ATTACHMENTS_BUCKET}

RUN --mount=type=secret,id=vite_sb_publishable_key \
    sh -c 'export VITE_SB_PUBLISHABLE_KEY="$(tr -d "\r\n" </run/secrets/vite_sb_publishable_key)" && npm run build'

# --- runtime ---
FROM nginx:alpine AS runtime
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=builder /app/dist /usr/share/nginx/html
EXPOSE 80
