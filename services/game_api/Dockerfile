FROM node:24-slim AS build
WORKDIR /app
COPY services/game_api/package*.json ./
RUN npm ci --ignore-scripts
COPY services/game_api/tsconfig.json ./
COPY services/game_api/src ./src
RUN npm run build && npm prune --omit=dev --ignore-scripts
FROM node:24-slim
WORKDIR /app
COPY --from=build /app/node_modules ./node_modules
COPY --from=build /app/dist ./dist
COPY --from=build /app/package.json ./package.json
USER node
EXPOSE 8080
CMD ["node","dist/src/server.js"]
