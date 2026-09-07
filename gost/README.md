# gost-client

Docker-образ и Kubernetes-манифест для клиента [GOST](https://github.com/go-gost/gost) v3.
Поднимает локальные **SOCKS5** и **HTTP**-прокси, которые форвардят трафик на
удалённый gost-сервер по `ss+tls` (Shadowsocks поверх TLS).

```
приложение → socks5://…:1080  ─┐
                               ├─► gost-client ──ss+tls──► GOST_SERVER_HOST:PORT
приложение → http://…:8080   ─┘
```

## Состав репозитория

| Файл                | Назначение                                                        |
|---------------------|------------------------------------------------------------------|
| `Dockerfile`        | Multi-stage сборка: скачивает бинарь gost, кладёт в alpine        |
| `entrypoint.sh`     | Формирует форвард-URI из ENV и запускает gost                     |
| `gost.yaml` | Шаблон манифеста k8s (Namespace + Secret + Deployment + Service)  |

## Сборка образа

```bash
docker build -t gost-client:3.2.6 .
# другая версия gost:
docker build --build-arg GOST_VERSION=3.2.6 -t gost-client:3.2.6 .
```

Поддерживаемые архитектуры: `amd64`, `arm64`, `armv7`.

## Запуск через Docker

```bash
docker run --rm -p 1080:1080 -p 8080:8080 \
  -e GOST_SERVER_HOST=proxy.example.com \
  -e GOST_SERVER_PORT=5443 \
  -e GOST_PASSWORD='...' \
  gost-client:3.2.6
```

### Переменные окружения

| Переменная         | Обяз. | Дефолт          | Описание                                              |
|--------------------|:-----:|-----------------|------------------------------------------------------|
| `GOST_SERVER_HOST` |  да   | —               | Хост удалённого gost-сервера                          |
| `GOST_SERVER_PORT` |  да   | —               | Порт удалённого gost-сервера                          |
| `GOST_PASSWORD`    |  да   | —               | Пароль Shadowsocks                                    |
| `GOST_METHOD`      |  нет  | `aes-256-gcm`   | Метод шифрования Shadowsocks                          |
| `GOST_TLS_SECURE`  |  нет  | `false`         | `true` — проверять TLS-сертификат сервера             |
| `SOCKS5_LISTEN`    |  нет  | `0.0.0.0:1080`  | Адрес прослушивания SOCKS5                            |
| `HTTP_LISTEN`      |  нет  | `0.0.0.0:8080`  | Адрес прослушивания HTTP-прокси                       |

> При `GOST_TLS_SECURE=true` сертификат сервера должен быть валиден для указанного `GOST_SERVER_HOST`.

## Деплой в Kubernetes

```bash
kubectl apply -f gost.yaml
```

Прокси доступны внутри кластера по `gost-client.tools.svc:1080` (SOCKS5) и `:8080` (HTTP).

