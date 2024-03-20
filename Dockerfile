# syntax=docker/dockerfile:1
ARG RUST_VERSION=1.76.0
ARG APP_NAME=rust-htmx

FROM rust:${RUST_VERSION}-alpine AS rust-build
ARG APP_NAME
WORKDIR /app

RUN apk add --no-cache clang lld musl-dev git

RUN --mount=type=bind,source=src,target=src \
    --mount=type=bind,source=Cargo.toml,target=Cargo.toml \
    --mount=type=bind,source=Cargo.lock,target=Cargo.lock \
    --mount=type=cache,target=/app/target/ \
    --mount=type=cache,target=/usr/local/cargo/git/db \
    --mount=type=cache,target=/usr/local/cargo/registry/ \
cargo build --locked --release && \
cp ./target/release/$APP_NAME /bin/server

FROM node:21 AS node-build

WORKDIR /app

COPY /www /www/

RUN cd /www && npm i && npx tailwindcss -i ./styles/tailwind_input.css -o ./styles/tailwind_output.css

FROM alpine:3.18 AS final

ARG UID=10001
RUN adduser \
    --disabled-password \
    --gecos "" \
    --home "/nonexistent" \
    --shell "/sbin/nologin" \
    --no-create-home \
    --uid "${UID}" \
    appuser
USER appuser

COPY --from=rust-build /bin/server /bin/
COPY --from=node-build /www /www/
COPY Rocket.toml ./ 

ENV ROCKET_ADDRESS=0.0.0.0

EXPOSE 8080

CMD ["/bin/server"]
