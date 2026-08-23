# Stage 1: Build
FROM hexpm/elixir:1.20.2-erlang-29.0.4-debian-bullseye-20260713 AS build

# Ollama model to pull at container start (use "none" to skip). Example: llama3:latest
ARG OLLAMA_MODEL=none

# Install build dependencies (including curl)
RUN apt-get update -y && apt-get install -y build-essential git curl \
    && apt-get clean && rm -f /var/lib/apt/lists/*_*

# Install hex + rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# Create build directory
WORKDIR /app

# Copy all source files first
COPY . .

# Install mix dependencies
RUN mix deps.get --only prod
RUN MIX_ENV=prod mix deps.compile

# Install Node.js
RUN curl -fsSL https://deb.nodesource.com/setup_24.x | bash - && \
    apt-get install -y nodejs

# Install npm dependencies and build assets
RUN cd assets && \
    npm install && \
    cd .. && \
    mix assets.deploy

# Compile the project
RUN MIX_ENV=prod mix compile

# Build the release
RUN MIX_ENV=prod mix phx.digest
RUN MIX_ENV=prod mix release

# Stage 2: Release
FROM debian:bullseye-slim

RUN apt-get update -y && apt-get install -y libstdc++6 openssl libncurses5 locales curl zstd \
    && apt-get clean && rm -f /var/lib/apt/lists/*_*

# Set the locale
RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen

ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

# Install Ollama
RUN curl -fsSL https://ollama.ai/install.sh | sh

WORKDIR /app

# Copy the release from the build stage
COPY --from=build /app/_build/prod/rel/dungeon ./
COPY --from=build /app/priv ./priv
COPY --from=build /app/config ./config

# Runtime OLLAMA_MODEL (default none). Example build: --build-arg OLLAMA_MODEL=llama3:latest
ARG OLLAMA_MODEL=none

# Create startup script (pull only when OLLAMA_MODEL is not none)
RUN echo '#!/bin/bash' > start.sh && \
    echo 'set -e' >> start.sh && \
    echo '' >> start.sh && \
    echo 'echo "Starting Ollama service..."' >> start.sh && \
    echo 'ollama serve &' >> start.sh && \
    echo 'OLLAMA_PID=$!' >> start.sh && \
    echo '' >> start.sh && \
    echo 'echo "Waiting for Ollama to be ready..."' >> start.sh && \
    echo 'sleep 5' >> start.sh && \
    echo '' >> start.sh && \
    echo 'if [ "${OLLAMA_MODEL:-none}" != "none" ]; then' >> start.sh && \
    echo '  echo "Pulling ${OLLAMA_MODEL} model..."' >> start.sh && \
    echo '  ollama pull "${OLLAMA_MODEL}" || echo "Failed to pull model, continuing anyway..."' >> start.sh && \
    echo 'fi' >> start.sh && \
    echo '' >> start.sh && \
    echo 'echo "Starting Phoenix application..."' >> start.sh && \
    echo 'exec bin/dungeon start' >> start.sh && \
    chmod +x start.sh

# Set environment variables
ENV MIX_ENV=prod
ENV PORT=4000
ENV PHX_SERVER=true
ENV PHX_HOST=localhost
ENV RELEASE_DISTRIBUTION=none
ENV RELEASE_TMP=/tmp
ENV OLLAMA_HOST=localhost
ENV OLLAMA_PORT=11434
ENV OLLAMA_MODEL=${OLLAMA_MODEL}

# Expose ports
EXPOSE 4000 11434

# The command to run both services
CMD ["./start.sh"] 