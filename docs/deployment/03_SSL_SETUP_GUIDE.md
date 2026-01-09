# Hướng dẫn cài đặt SSL (HTTPS) cho VPS với Certbot & Let's Encrypt

Việc cài đặt SSL trực tiếp trên VPS giúp hệ thống bảo mật hơn và cho phép bạn sử dụng chế độ **SSL/TLS Full (Strict)** trên Cloudflare, tránh được các lỗi vòng lặp chuyển hướng (Redirect Loop).

---

## Bước 1: Cài đặt Certbot

Chạy các lệnh sau trên VPS (Ubuntu/Debian) để cài đặt Certbot và plugin cho Nginx:

```bash
sudo apt update
sudo apt install certbot python3-certbot-nginx -y
```

---

## Bước 2: Cấp chứng chỉ SSL mới

Thay `hls.filmlearning.com` bằng subdomain của bạn. Certbot sẽ tự động đọc cấu hình Nginx hiện tại và xin cấp chứng chỉ.

```bash
sudo certbot --nginx -d hls.filmlearning.com
```

**Lưu ý trong quá trình chạy:**
1.  **Email:** Nhập email của bạn để nhận thông báo khi chứng chỉ sắp hết hạn.
2.  **Terms of Service:** Chọn `A` (Agree).
3.  **Redirect:** Certbot sẽ hỏi có muốn tự động chuyển hướng HTTP sang HTTPS không. Nên chọn **2 (Redirect)** để đảm bảo luôn dùng HTTPS.

---

## Bước 3: Cấu hình Nginx thủ công (Nếu Certbot không tự cập nhật)

Nếu bạn muốn tự tay cấu hình hoặc kiểm tra, file cấu hình Nginx tại `/etc/nginx/sites-available/hls-proxy` sau khi có SSL sẽ trông như thế này:

```nginx
server {
    listen 80;
    server_name hls.filmlearning.com;
    return 301 https://$host$request_uri; # Chuyển hướng HTTP sang HTTPS
}

server {
    listen 443 ssl;
    server_name hls.filmlearning.com;

    # Đường dẫn chứng chỉ (Certbot sẽ tự điền nếu chạy lệnh ở Bước 2)
    ssl_certificate /etc/letsencrypt/live/hls.filmlearning.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/hls.filmlearning.com/privkey.pem;

    # Tối ưu SSL
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;

    client_max_body_size 100M;

    location / {
        # Giữ nguyên các cấu hình proxy cũ
        proxy_pass http://127.0.0.1:3000;
        
        # Header CORS (Anti-Leech)
        add_header 'Access-Control-Allow-Origin' 'https://film-learning-c126.vercel.app' always;
        add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS' always;
        add_header 'Access-Control-Allow-Headers' '*' always;

        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        proxy_buffering off;
        proxy_read_timeout 300s;
    }
}
```

Sau khi sửa file, hãy kiểm tra và khởi động lại Nginx:
```bash
sudo nginx -t
sudo systemctl restart nginx
```

---

## Bước 4: Kiểm tra tự động gia hạn

Chứng chỉ Let's Encrypt có thời hạn 90 ngày. Certbot đã tự động thêm một "cron job" để gia hạn. Bạn có thể kiểm tra xem nó có hoạt động không bằng lệnh:

```bash
sudo certbot renew --dry-run
```
*Nếu không có lỗi hiện ra, hệ thống sẽ tự động gia hạn vĩnh viễn cho bạn.*

---

## Bước 5: Cấu hình lại Cloudflare (QUAN TRỌNG)

Bây giờ VPS đã có SSL "xịn", bạn hãy quay lại Cloudflare:

1.  Vào **SSL/TLS** -> **Overview**.
2.  Chuyển chế độ sang **Full (Strict)**.
3.  Đây là chế độ bảo mật cao nhất, đảm bảo kết nối từ Cloudflare tới VPS được mã hóa hoàn toàn.

---
*Người viết: Antigravity AI Assistant*
