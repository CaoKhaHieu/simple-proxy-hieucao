# Hướng dẫn triển khai HLS Proxy lên VPS & Cấu hình Cloudflare

Tài liệu này hướng dẫn chi tiết cách cài đặt hệ thống Proxy video lên VPS và tối ưu hóa bằng Cloudflare để phục vụ hàng ngàn người dùng cùng lúc với chi phí thấp nhất.

---

## Phần 1: Chuẩn bị trên VPS

### 1. Cài đặt môi trường
Mở Terminal của VPS và chạy các lệnh sau (Dành cho Ubuntu/Debian):

```bash
# Cập nhật hệ thống
sudo apt update && sudo apt upgrade -y

# Cài đặt Node.js (Phiên bản 20 hoặc mới hơn)
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs

# Cài đặt pnpm
sudo npm install -g pnpm

# Cài đặt PM2 (Để quản lý ứng dụng chạy ngầm)
sudo npm install -g pm2
```

### 2. Tải mã nguồn và Cài đặt
```bash
# Clone code từ GitHub của bạn
git clone https://github.com/YOUR_USERNAME/simple-proxy-hieucao.git
cd simple-proxy-hieucao

# Cài đặt thư viện
pnpm install

# Tạo file cấu hình môi trường
nano .env
```
Nội dung file `.env`:
```env
PORT=80
ENABLE_CACHE=true
```

### 3. Build và Chạy ứng dụng
```bash
# Build dự án cho môi trường Node.js
pnpm build:node

# Dừng và xóa tiến trình cũ (nếu có)
sudo pm2 delete hls-proxy

# Chạy ứng dụng bằng PM2 với quyền sudo (bắt buộc cho cổng 80)
pm2 start .output/server/index.mjs --name "hls-proxy"

# Thiết lập PM2 tự khởi động cùng VPS
sudo pm2 startup
sudo pm2 save
```

---

## Phần 2: Cấu hình Cloudflare (QUAN TRỌNG)

Để gánh được 1000 user trên VPS cổng mạng 200Mbps, bạn **bắt buộc** phải cấu hình Cloudflare để cache video.

### 1. DNS Setup
*   Trỏ tên miền của bạn (ví dụ: `hls.kolarea.com`) về IP của VPS.
*   Đảm bảo biểu tượng đám mây là **Màu cam (Proxied)**.
*   Vào mục **SSL/TLS** -> **Edge Certificates**, bật **Always Use HTTPS**.

### 2. Cấu hình Cache Rules (Để Cloudflare lưu video)
Mặc định Cloudflare không lưu file video. Bạn cần ép nó lưu lại:
1.  Vào Dashboard Cloudflare -> **Caching** -> **Cache Rules**.
2.  Nhấn **Create rule**.
3.  **Field:** `Hostname` | **Operator:** `equals` | **Value:** `hls.kolarea.com`
4.  *(Nhấn "And" để thêm điều kiện)*
5.  **Field:** `URI Path` | **Operator:** `contains` | **Value:** `/ts-proxy`
6.  **Cache eligibility:** Chọn `Eligible for cache`.
7.  **Edge Cache TTL:** Chọn `Override origin` -> `1 month`.
8.  Nhấn **Deploy**.

### 3. Cấu hình SSL/TLS
*   Vào mục **SSL/TLS** -> **Overview**.
*   Chọn chế độ **Full** hoặc **Full (Strict)**.

---

## Phần 3: Tối ưu hóa Code cho Cloudflare

Để Cloudflare nhận diện và cache tốt nhất, hãy đảm bảo file `src/routes/ts-proxy.ts` gửi đúng Header.

**Đoạn code cần kiểm tra/sửa đổi:**
```typescript
// Trong src/routes/ts-proxy.ts
setResponseHeaders(event, {
  'Content-Type': 'video/mp2t',
  'Access-Control-Allow-Origin': '*',
  'Cache-Control': 'public, max-age=31536000, immutable' // Ép Cloudflare và Trình duyệt cache 1 năm
});
```

---

## Phần 4: Cách sử dụng URL cuối cùng

Sau khi hoàn tất, URL của bạn sẽ rất gọn (không cần :3000):

**Link Playlist:**
`https://hls.kolarea.com/m3u8-proxy?url=[LINK_M3U8_GOC]&headers=[JSON_HEADERS]`

**Link Segment (Tự động sinh ra bên trong playlist):**
`https://hls.kolarea.com/ts-proxy?url=[LINK_TS_GOC]`

---

## Kiểm tra hiệu quả
1.  Mở link video qua proxy.
2.  Mở **Network Tab** trong trình duyệt (F12).
3.  Click vào một file `.ts`.
4.  Kiểm tra Header `cf-cache-status`:
    *   **MISS**: Lần đầu tiên tải (VPS đang gánh).
    *   **HIT**: Từ lần thứ 2 trở đi (Cloudflare đang gánh - **THÀNH CÔNG**).

---
*Người viết: Antigravity AI Assistant*
