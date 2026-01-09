# Tổng quan hệ thống HLS Proxy (Overview)

Chào mừng bạn đến với hệ thống **HLS Proxy** - giải pháp tối ưu để stream video chất lượng cao, vượt rào cản CORS và tiết kiệm băng thông tối đa cho VPS.

---

## 🚀 Mục tiêu của dự án
Hệ thống này được thiết kế để giải quyết 3 vấn đề lớn nhất khi làm web phim:
1.  **Bypass CORS:** Cho phép trình duyệt tải video từ các nguồn chặn domain (như Google Drive, CDN bên thứ 3).
2.  **Bảo mật Origin:** Che giấu link gốc của video, tránh bị lộ nguồn dữ liệu.
3.  **Tối ưu băng thông (Cost-Effective):** Sử dụng Cloudflare làm lớp đệm (Cache) để phục vụ hàng ngàn người dùng chỉ với một VPS cấu hình thấp.

---

## 🏗️ Kiến trúc hệ thống (Architecture)

Hệ thống là sự kết hợp hoàn hảo giữa 3 tầng công nghệ:

1.  **Frontend (Vercel):** Nơi chứa giao diện người dùng (filmlearning.com). Giao diện mượt mà, tốc độ tải trang cực nhanh nhờ hạ tầng của Vercel.
2.  **Edge Network (Cloudflare):** Đóng vai trò là "người gác cổng" và bộ nhớ đệm. Cloudflare sẽ lưu lại các phân đoạn video (.ts) và phân phối chúng từ các server gần người dùng nhất (Việt Nam, Singapore...).
3.  **Backend Proxy (VPS + Nginx + Node.js):**
    *   **Nginx:** Xử lý HTTPS (SSL) và điều phối request.
    *   **Node.js (Nitro):** "Bộ não" xử lý logic, parse playlist m3u8 và stream dữ liệu trực tiếp từ nguồn về cho Cloudflare.

---

## 🛠️ Các thành phần chính trong tài liệu

Để vận hành hệ thống này một cách trơn tru, bạn nên đọc qua các hướng dẫn theo thứ tự sau:

1.  [**01. Hướng dẫn triển khai (Deployment Guide)**](./01_DEPLOYMENT_GUIDE.md): Các bước cài đặt cơ bản trên VPS và sơ đồ luồng dữ liệu.
2.  [**02. Thiết lập Nginx (Nginx Setup)**](./02_NGINX_SETUP_GUIDE.md): Cách cấu hình Nginx làm Reverse Proxy chuyên nghiệp.
3.  [**03. Cài đặt SSL (SSL Setup)**](./03_SSL_SETUP_GUIDE.md): Hướng dẫn sử dụng Certbot để có HTTPS "xịn" cho VPS.
4.  [**04. Tối ưu Cloudflare (Cloudflare Cache)**](./04_CLOUDFLARE_CACHE_GUIDE.md): Bí kíp cấu hình Cache Rules để gánh 95% băng thông.

---

## 📈 Hiệu quả kỳ vọng
*   **Khả năng chịu tải:** 1000 - 5000 người xem cùng lúc (tùy thuộc vào cấu hình Cache).
*   **Độ trễ (Latency):** Giảm 70-80% so với việc stream trực tiếp từ VPS không có cache.
*   **Chi phí:** Cực thấp, chỉ tốn tiền thuê 1 VPS cơ bản.

---
*Người viết: Antigravity AI Assistant*
