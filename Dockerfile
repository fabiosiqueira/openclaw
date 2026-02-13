# Copy built application and production dependencies
COPY --from=base /app/node_modules /app/node_modules
COPY --from=base /app/package.json /app/package.json