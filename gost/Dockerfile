# syntax=docker/dockerfile:1

FROM alpine:3.20 AS downloader

ARG GOST_VERSION=3.2.6

RUN apk add --no-cache curl tar \
    && ARCH="$(apk --print-arch)" \
    && case "$ARCH" in \
         x86_64)  GOST_ARCH=amd64 ;; \
         aarch64) GOST_ARCH=arm64 ;; \
         armv7l)  GOST_ARCH=armv7 ;; \
         *) echo "unsupported arch: $ARCH" >&2; exit 1 ;; \
       esac \
    && URL="https://github.com/go-gost/gost/releases/download/v${GOST_VERSION}/gost_${GOST_VERSION}_linux_${GOST_ARCH}.tar.gz" \
    && echo "Downloading: $URL" \
    && curl -4 -fSL --retry 3 -o /tmp/gost.tar.gz "$URL" \
    && ls -la /tmp/gost.tar.gz \
    && mkdir -p /usr/local/sbin \
    && tar -xzf /tmp/gost.tar.gz -C /usr/local/sbin gost \
    && chmod +x /usr/local/sbin/gost \
    && rm -f /tmp/gost.tar.gz \
    && ls -la /usr/local/sbin/gost \
    && /usr/local/sbin/gost -V

FROM alpine:3.20
RUN apk add --no-cache ca-certificates \
    && addgroup -S gost && adduser -S gost -G gost

COPY --from=downloader /usr/local/sbin/gost /usr/local/sbin/gost
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

USER gost

# Значения по умолчанию — переопределяются через ENV / k8s Secret+ConfigMap
ENV GOST_METHOD=aes-256-gcm \
    GOST_SERVER_HOST="" \
    GOST_SERVER_PORT="" \
    GOST_PASSWORD="" \
    GOST_TLS_SECURE=false \
    SOCKS5_LISTEN=0.0.0.0:1080 \
    HTTP_LISTEN=0.0.0.0:8080

EXPOSE 1080 8080

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
