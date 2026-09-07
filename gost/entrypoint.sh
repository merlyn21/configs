#!/bin/sh
set -eu

: "${GOST_METHOD:=aes-256-gcm}"
: "${GOST_PASSWORD:?GOST_PASSWORD is required}"
: "${GOST_SERVER_HOST:?GOST_SERVER_HOST is required}"
: "${GOST_SERVER_PORT:?GOST_SERVER_PORT is required}"
: "${GOST_TLS_SECURE:=false}"
: "${SOCKS5_LISTEN:=0.0.0.0:1080}"
: "${HTTP_LISTEN:=0.0.0.0:8080}"

# secure=false (default) = не проверять сертификат сервера (аналог noverify=true из gost v2)
# secure=true            = проверять сертификат (нужно передать корректный serverName)
FORWARD_URI="ss+tls://${GOST_METHOD}:${GOST_PASSWORD}@${GOST_SERVER_HOST}:${GOST_SERVER_PORT}?secure=${GOST_TLS_SECURE}"

exec /usr/local/sbin/gost \
  -L "socks5://${SOCKS5_LISTEN}" \
  -L "http://${HTTP_LISTEN}" \
  -F "${FORWARD_URI}"
