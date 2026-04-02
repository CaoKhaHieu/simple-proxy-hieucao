#!/bin/bash

# ==============================================================================
# HIEUCAO PROXY VPS INFRA SETUP SCRIPT - ULTRA-OPTIMIZED (UBUNTU 22.04/24.04)
# Domain: hls.filmlearning.com
# Port:   3001 (Nitro Node Server)
# ==============================================================================

set -e

echo "🚀 Bắt đầu quá trình thiết lập hạ tầng VPS (Ultra-Optimized)..."

# ==============================================================================
# 1. CẬP NHẬT HỆ THỐNG
# ==============================================================================
echo "📦 1/6: Cập nhật hệ thống..."
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl git build-essential nginx ufw

# ==============================================================================
# 2. TỐI ƯU HÓA KERNEL LINUX (BBR & Network)
# ==============================================================================
echo "🌐 2/6: Tối ưu hóa TCP & Network..."
if ! grep -q "net.core.default_qdisc=fq" /etc/sysctl.conf; then
  cat <<SYSCTL | sudo tee -a /etc/sysctl.conf

# === HIEUCAO PROXY OPTIMIZATION ===
# BBR - Thuật toán tối ưu TCP của Google (giảm giật khi xem phim)
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr

# Tăng giới hạn file descriptor (Chống lỗi "Too many open files")
fs.file-max=1000000

# Tăng buffer mạng cho nhiều kết nối đồng thời
net.core.somaxconn=1024
net.core.netdev_max_backlog=5000
net.ipv4.tcp_max_syn_backlog=4096

# Giảm thời gian chờ TCP (Giải phóng kết nối nhanh hơn)
net.ipv4.tcp_fin_timeout=30
net.ipv4.tcp_keepalive_time=1200
SYSCTL

  sudo sysctl -p
fi

# Tăng giới hạn file descriptor cho tất cả user
if ! grep -q "soft nofile 65535" /etc/security/limits.conf; then
  echo "* soft nofile 65535" | sudo tee -a /etc/security/limits.conf
  echo "* hard nofile 65535" | sudo tee -a /etc/security/limits.conf
fi
echo "✅ Kernel đã được tối ưu!"

# ==============================================================================
# 3. CÀI ĐẶT NODE.JS, PNPM, PM2
# ==============================================================================
echo "🟢 3/6: Cài đặt Node.js & pnpm..."
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs
sudo npm install -g pnpm pm2
echo "✅ Node.js $(node -v) & pnpm $(pnpm -v) đã sẵn sàng!"

# ==============================================================================
# 4. CẤU HÌNH FIREWALL
# ==============================================================================
echo "🛡️ 4/6: Cấu hình Tường lửa (UFW)..."
sudo ufw allow OpenSSH
sudo ufw allow 'Nginx Full'
sudo ufw --force enable
echo "✅ Firewall đã bật! (SSH + HTTP + HTTPS)"

# ==============================================================================
# 5. CẤU HÌNH NGINX - TỐI ƯU CHO VIDEO STREAMING PROXY
# ==============================================================================
echo "📡 5/6: Cấu hình Nginx..."

# Tối ưu Nginx worker ở cấp global
cat <<NGINXMAIN | sudo tee /etc/nginx/conf.d/optimization.conf
# Tăng số kết nối mỗi worker (mặc định chỉ 512)
# Mỗi người xem phim = ~2-4 kết nối (m3u8 + ts chunks)
worker_connections 4096;

# Bật sendfile & tcp_nopush để gửi file nhanh hơn
sendfile on;
tcp_nopush on;
tcp_nodelay on;

# Tăng kích thước buffer cho các header lớn (URL dài khi encode)
proxy_buffer_size 128k;
proxy_buffers 4 256k;
large_client_header_buffers 4 32k;
NGINXMAIN

# Cấu hình site cho hls.filmlearning.com
cat <<EOF | sudo tee /etc/nginx/sites-available/proxy.conf
server {
    listen 80;
    server_name hls.filmlearning.com;

    # Nén Gzip cho manifest m3u8 (file text, nén rất hiệu quả)
    gzip on;
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types application/vnd.apple.mpegurl application/json text/plain;

    location / {
        proxy_pass http://127.0.0.1:3001;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;

        # === QUAN TRỌNG CHO STREAMING VIDEO ===

        # Tắt buffering: Nginx đẩy data thẳng đến client ngay khi nhận được
        # Nếu bật buffering, Nginx sẽ chờ tải xong toàn bộ chunk rồi mới gửi -> lag
        proxy_buffering off;
        proxy_request_buffering off;

        # Timeout cao cho các video dài (10 phút)
        proxy_read_timeout 600s;
        proxy_send_timeout 600s;

        # Cho phép Chunked Transfer (cần cho HLS streaming)
        chunked_transfer_encoding on;

        # KHÔNG thêm CORS ở đây vì code Nitro đã tự xử lý CORS
        # Nếu thêm ở cả 2 nơi, trình duyệt sẽ nhận 2 header trùng -> lỗi CORS
    }
}
EOF

sudo ln -sf /etc/nginx/sites-available/proxy.conf /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t && sudo systemctl restart nginx
echo "✅ Nginx đã được thiết lập tối ưu cho Streaming!"

# ==============================================================================
# 6. CÀI ĐẶT SSL (CERTBOT)
# ==============================================================================
echo "🔒 6/6: Cài đặt Certbot cho SSL..."
sudo apt install -y certbot python3-certbot-nginx
echo "✅ Certbot đã sẵn sàng!"

echo ""
echo "=============================================================================="
echo "✨ THIẾT LẬP ULTRA-OPTIMIZED HOÀN TẤT! ✨"
echo "=============================================================================="
echo ""
echo "👉 Bước tiếp theo của bạn:"
echo ""
echo "1. Clone dự án:"
echo "   git clone <url_repo> ~/proxy && cd ~/proxy"
echo ""
echo "2. Cài đặt dependencies và Build:"
echo "   pnpm install && NITRO_PRESET=node-server pnpm build"
echo ""
echo "3. Chạy Proxy với PM2:"
echo "   PORT=3001 pm2 start .output/server/index.mjs --name proxy"
echo "   pm2 save && pm2 startup"
echo ""
echo "4. Cài SSL (SAU KHI đã trỏ domain hls.filmlearning.com về IP VPS này):"
echo "   sudo certbot --nginx -d hls.filmlearning.com"
echo ""
echo "=============================================================================="
