# Hướng dẫn thiết lập Nginx làm Reverse Proxy cho HLS Proxy

Việc sử dụng Nginx đứng trước ứng dụng Node.js là một **Best Practice** giúp hệ thống ổn định hơn, bảo mật hơn và xử lý được lượng kết nối lớn (1000+ user).

---

## Bước 1: Cài đặt Nginx

Chạy các lệnh sau trên VPS (Ubuntu/Debian):

```bash
sudo apt update
sudo apt install nginx -y
```

---

## Bước 2: Cấu hình Nginx cho Subdomain

1.  **Tạo file cấu hình mới:**
    ```bash
    sudo nano /etc/nginx/sites-available/hls-proxy
    ```

2.  **Dán nội dung cấu hình sau vào (Thay đổi `hls.kolarea.com` bằng domain của bạn):**

```nginx
server {
    listen 80;
    server_name hls.kolarea.com;

    # Tăng kích thước upload nếu cần (không quan trọng với proxy này)
    client_max_body_size 100M;

    location / {
        # Xử lý yêu cầu Preflight (OPTIONS) - Chỉ cho phép domain của bạn
        if ($request_method = 'OPTIONS') {
            add_header 'Access-Control-Allow-Origin' 'https://film-learning-c126.vercel.app' always;
            add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS' always;
            add_header 'Access-Control-Allow-Headers' '*' always;
            add_header 'Access-Control-Max-Age' 1728000 always;
            add_header 'Content-Type' 'text/plain; charset=utf-8' always;
            add_header 'Content-Length' 0 always;
            return 204;
        }

        # Trỏ về ứng dụng Node.js đang chạy ở cổng 3000
        proxy_pass http://127.0.0.1:3000;
        
        # Ép thêm header CORS bảo vệ (Anti-Leech)
        add_header 'Access-Control-Allow-Origin' 'https://film-learning-c126.vercel.app' always;
        add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS' always;
        add_header 'Access-Control-Allow-Headers' '*' always;
        add_header 'Access-Control-Expose-Headers' '*' always;

        # Các header quan trọng để truyền thông tin người dùng
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $http_x_forwarded_proto;

        # Tối ưu hóa cho việc truyền tải Video (HLS)
        proxy_buffering off;
        proxy_request_buffering off;
        proxy_read_timeout 300s;
        proxy_connect_timeout 300s;
        proxy_send_timeout 300s;
    }

    # Trang lỗi tùy chỉnh (Tùy chọn)
    error_page 502 /502.html;
    location = /502.html {
        return 502 '{"error": "HLS Proxy is starting up or down. Please wait."}';
        add_header Content-Type application/json;
    }
}
```

---

## Bước 3: Kích hoạt cấu hình

1.  **Tạo liên kết (Link) để kích hoạt:**
    ```bash
    sudo ln -s /etc/nginx/sites-available/hls-proxy /etc/nginx/sites-enabled/
    ```

2.  **Xóa cấu hình mặc định (Để tránh xung đột):**
    ```bash
    sudo rm /etc/nginx/sites-enabled/default
    ```

3.  **Kiểm tra lỗi cú pháp:**
    ```bash
    sudo nginx -t
    ```
    *Nếu hiện `syntax is ok` và `test is successful` là bạn đã làm đúng.*

4.  **Khởi động lại Nginx:**
    ```bash
    sudo systemctl restart nginx
    ```

---

## Bước 4: Đảm bảo App Node.js chạy ở cổng 3000

Trong file `.env` trên VPS, hãy chắc chắn bạn đặt:
```env
PORT=3000
```

Sau đó khởi động lại app bằng PM2:
```bash
pm2 restart hls-proxy
```

---

## Bước 5: Kiểm tra kết quả

Bây giờ bạn có thể truy cập:
*   `http://hls.kolarea.com/` (Nginx sẽ tự động chuyển tiếp vào App ở cổng 3000).
*   Nếu bạn đã bật Cloudflare HTTPS, hãy dùng: `https://hls.kolarea.com/`.

---

## Các lệnh Nginx hữu ích:

*   **Xem log truy cập:** `sudo tail -f /var/log/nginx/access.log`
*   **Xem log lỗi:** `sudo tail -f /var/log/nginx/error.log` (Rất hữu ích khi bị lỗi 502).
*   **Kiểm tra trạng thái:** `sudo systemctl status nginx`

---
*Người viết: Antigravity AI Assistant*
