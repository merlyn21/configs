docker run -d --name socks5_amd64 -p 28131:1080 -e PROXY_USER=user -e PROXY_PASSWORD=password --restart=unless-stopped olebedev/socks5
