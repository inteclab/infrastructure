# 更新系统
sudo dnf update -y
sudo dnf install git zip unzip jq curl vim wget gnupg2 -y

# 安装 Docker
sudo dnf install docker -y

# 启动并启用 Docker 服务
sudo systemctl start docker
sudo systemctl enable docker

## 安装 Docker Compose (作为插件)
## 下载最新版本的 Docker Compose
DOCKER_COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | jq -r .tag_name)
sudo curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# 将当前用户添加到 docker 组（避免每次使用 sudo）
sudo usermod -aG docker $USER

echo "Docker 安装完成"

# 验证安装
docker --version

echo "注意：如果 docker 命令仍然需要 sudo，请注销后重新登录，或运行 'newgrp docker'"

mkdir -p /root/acap.cc/uptime /root/acap.cc/reg-docker/registry

docker-compose up -d


echo "准备安装BW"
# 安装 Node.js 20.x
curl -fsSL https://rpm.nodesource.com/setup_20.x | sudo bash -
sudo dnf install nodejs -y
# 验证版本
node --version
npm --version
# 重新安装 Bitwarden CLI
sudo npm install -g @bitwarden/cli
# 测试
bw --version

bw config server https://vault.acap.work
bw login
BW_SESSION_OUTPUT=$(bw unlock --raw)
export BW_SESSION="$BW_SESSION_OUTPUT"
bw sync;
sudo mkdir -p /lab/envs
bw get item "2c078613-c242-4606-a7a5-3cf936c91c84" | jq -r '.notes' > /lab/envs/cf.env

bw get item "a86058cf-82dd-4e52-940c-633257e3897f" | jq -r '.notes' > /lab/envs/githubproxy-go.env

# docker-proxy-htpasswd
bw get item "ee2dee4c-844c-4ed0-ad05-ad92c4da7ec5" | jq -r '.notes' > /root/acap.cc/htpasswd
# docker-proxy registry-hub.yml
bw get item "4083e1cb-d41d-4505-9610-6adaa5610ec1" | jq -r '.notes' > /root/acap.cc/registry-hub.yml

mkdir -p /etc/sing-box/
bw get item "86b41eb6-e164-4c6b-a451-ed8c414cf9ef" | jq -r '.notes' > /etc/sing-box/config.json


echo "准备更新DNS"
. /lab/envs/cf.env
. /root/acap.cc/cf_update_dns.sh

echo "准备安装CADDY"

. ./install_caddy.sh


echo "准备更新CADDY配置"

cat << 'EOF' >> /etc/caddy/Caddyfile
git.acap.cc {
        reverse_proxy localhost:60000 {
                header_up Host {host}
                header_up X-Real-IP {remote_addr}
                header_up X-Forwarded-For {remote_addr}
                header_up X-Nginx-Proxy true
        }
}

ui.acap.cc {
        reverse_proxy localhost:50000 {
                header_up Host {host}
                header_up X-Real-IP {remote_addr}
                header_up X-Forwarded-For {remote_addr}
                header_up X-Nginx-Proxy true
        }
}

hub.acap.cc {
        reverse_proxy localhost:51000 {
                header_up Host {host}
                header_up X-Real-IP {remote_addr}
                header_up X-Forwarded-For {remote_addr}
                header_up X-Nginx-Proxy true
        }
}

v.acap.cc {
        # 特定路径转发到 news
        reverse_proxy /news localhost:41931

        # TLS 配置
        tls {
                protocols tls1.2 tls1.3
        }

        # 其他路径显示普通网站
        root * /usr/share/caddy
        file_server
}


uptime.acap.cc {
        reverse_proxy localhost:3001 {
                # 支持 WebSocket
                header_up Host {host}
                header_up X-Real-IP {remote}
                header_up X-Forwarded-For {remote}
                header_up X-Forwarded-Proto {scheme}
        }
}
EOF

systemctl reload caddy


echo "准备安装sing-box"

wget -O /tmp/sing-box-1.11.15-linux-arm64.tar.gz https://github.com/SagerNet/sing-box/releases/download/v1.11.15/sing-box-1.11.15-linux-arm64.tar.gz
tar -xzvf /tmp/sing-box-1.11.15-linux-arm64.tar.gz -C /tmp
mv /tmp/sing-box-1.11.15-linux-arm64/sing-box /usr/local/bin
chmod +x /usr/local/bin/sing-box


mv sing-box.service /etc/systemd/system/sing-box.service

systemctl daemon-reload
systemctl enable sing-box --now
