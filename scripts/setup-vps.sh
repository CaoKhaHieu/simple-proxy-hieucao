#!/bin/bash

# ==============================================================================
# HIEUCAO PROXY VPS SETUP SCRIPT (FIXED CORS VERSION)
# Domain: hls.filmlearning.com
# Port:   3000 (Nitro Server)
# Repo:   https://github.com/CaoKhaHieu/simple-proxy-template
# Branch: feat/testing
# ==============================================================================

set -e

# --- CẤU HÌNH ---
DOMAIN="hls.filmlearning.com"
EMAIL="admin@filmlearning.com"
PORT=3000
REPO_URL="https://github.com/CaoKhaHieu/simple-proxy-template"

# Thêm domain production của bạn vào đây (Cách nhau bằng dấu phẩy)
ALLOWED_DOMAINS="filmlearning.com,film-learning-c126.vercel.app,localhost"

echo "🚀 Bắt đầu quá trình thiết lập hạ tầng (Fix CORS)..."

# 1. Cập nhật hệ thống & Cài đặt công cụ
echo "📦 1/7: Cài đặt công cụ cơ bản..."
sudo apt update
sudo apt install -y curl git build-essential nginx ufw certbot python3-certbot-nginx

# 2. Cài đặt Node.js & công cụ
echo "🟢 2/7: Cài đặt Node.js & pnpm..."
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs
sudo npm install -g pnpm pm2

# 3. Download mã nguồn & Cấu hình .env
echo "📂 3/7: Download mã nguồn & Thiết lập .env..."
rm -rf ~/proxy
git clone $REPO_URL ~/proxy
cd ~/proxy
git checkout feat/testing

# QUAN TRỌNG: Thiết lập ALLOWED_DOMAINS để Nitro xử lý CORS chuẩn
echo "PORT=$PORT" > .env
echo "ENABLE_CACHE=true" >> .env
echo "ALLOWED_DOMAINS=$ALLOWED_DOMAINS" >> .env

# 4. Build dự án
echo "🛠️ 4/7: Build dự án..."
pnpm install
NITRO_PRESET=node-server pnpm build

# 5. Cấy Nginx (LOẠI BỎ CORS ĐỂ TRÁNH XUNG ĐỘT)
echo "📡 5/7: Cấu hình Nginx..."
export NGINX_CONF="/etc/nginx/nginx.conf"
sudo sed -i '0,/sendfile on;/! s/sendfile on;//' $NGINX_CONF
sudo sed -i '0,/tcp_nopush on;/! s/tcp_nopush on;//' $NGINX_CONF
sudo sed -i '0,/tcp_nodelay on;/! s/tcp_nodelay on;//' $NGINX_CONF

cat <<EOF | sudo tee /etc/nginx/sites-available/hls-proxy
server {
    listen 80;
    server_name $DOMAIN;

    client_max_body_size 100M;

    location / {
        # KHÔNG THÊM HEADER CORS Ở ĐÂY VÌ CODE NITRO ĐÃ TỰ XỬ LÝ
        
        proxy_pass http://127.0.0.1:$PORT;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;

        proxy_buffering off;
        proxy_request_buffering off;
        proxy_read_timeout 300s;
    }

    error_page 502 /502.html;
    location = /502.html {
        return 502 '{"error": "HLS Proxy is starting up or down. Please wait."}';
        add_header Content-Type application/json;
    }
}
EOF

sudo ln -sf /etc/nginx/sites-available/hls-proxy /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
sudo rm -f /etc/nginx/sites-enabled/proxy.conf
sudo ufw allow OpenSSH
sudo ufw allow 'Nginx Full'
sudo ufw --force enable
sudo nginx -t && sudo systemctl restart nginx

# 6. SSL
echo "🔒 6/7: Tự động cài SSL..."
sudo certbot --nginx -d $DOMAIN --non-interactive --agree-tos --email $EMAIL || echo "Tiếp tục chạy PM2..."

# 7. PM2
echo "🚀 7/7: Khởi chạy Proxy..."
cd ~/proxy
pm2 delete hls-proxy || true
pm2 start .output/server/index.mjs --name hls-proxy
pm2 save
pm2 startup

echo "✅ HOÀN TẤT!"
