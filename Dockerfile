FROM lukemathwalker/cargo-chef:latest AS chef
RUN rustup default nightly
RUN curl -L https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64 > /usr/bin/jq; chmod +x /usr/bin/jq
WORKDIR /app

FROM chef AS planner
ARG CARGO_UNSTABLE_SPARSE_REGISTRY=true
COPY . .
RUN cargo chef prepare --recipe-path recipe.json
RUN jq -C '.' recipe.json

FROM chef AS builder
ARG CARGO_UNSTABLE_SPARSE_REGISTRY=true
COPY --from=planner /app/recipe.json recipe.json
# Build dependencies - this is the caching Docker layer!
RUN cargo chef cook --recipe-path recipe.json
# Build application
COPY . .
RUN cargo build

# We do not need the Rust toolchain to run the binary!
FROM debian:buster-slim AS runtime
WORKDIR /app