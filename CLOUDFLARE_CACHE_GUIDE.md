# Hướng dẫn chi tiết: Cấu hình Caching Video qua Cloudflare (Best Practice)

Tài liệu này tập trung vào việc tối ưu hóa Cloudflare để gánh 90-95% băng thông video, giúp VPS của bạn phục vụ được 1000+ user cùng lúc mà không bị nghẽn mạng.

---

## Bước 1: Kích hoạt Cloudflare cho Tên miền (BẮT BUỘC)

Trước khi cấu hình Cache, Cloudflare phải nắm quyền quản lý DNS của bạn.

1.  **Đổi Nameservers:** Đăng nhập vào quản trị tên miền (Vietnix/Mắt Bão...) và đổi Nameservers thành:
    *   `arushi.ns.cloudflare.com`
    *   `thomas.ns.cloudflare.com`
2.  **Kiểm tra DNS:** Đảm bảo các bản ghi cũ của website chính (`kolarea.com`) đã được copy sang Cloudflare để không làm sập web hiện tại.
3.  **Thêm Subdomain Proxy:**
    *   **Type:** `A` | **Name:** `hls` | **Content:** `163.227.230.130` (IP VPS)
    *   **Proxy status:** Phải là **Màu cam (Proxied)**.

---

## Bước 2: Cấu hình SSL/TLS (Để có HTTPS)

Để link video có dạng `https://hls.kolarea.com/...` mượt mà:

1.  Vào mục **SSL/TLS** -> **Overview**:
    *   Chọn chế độ **Flexible** (Nếu VPS chưa cài SSL).
    *   Chọn chế độ **Full** (Nếu đã cài Nginx/SSL trên VPS).
2.  Vào mục **SSL/TLS** -> **Edge Certificates**:
    *   Bật **Always Use HTTPS**: Tự động chuyển `http` sang `https`.

---

## Bước 3: Cấu hình Cache Rules (Trái tim của hệ thống)

Mặc định Cloudflare không cache file video `.ts`. Bạn phải ép nó lưu lại bằng Rule sau:

1.  Vào **Caching** -> **Cache Rules** -> nhấn **Create rule**.
2.  **Rule name:** `Cache HLS Segments`
3.  **If incoming requests match... (Điều kiện):**
    *   Field: `Hostname` | Operator: `equals` | Value: `hls.kolarea.com`
    *   *(Nhấn "And")*
    *   Field: `URI Path` | Operator: `contains` | Value: `/ts-proxy`
4.  **Then... (Hành động):**
    *   **Cache eligibility:** Chọn `Eligible for cache`.
    *   **Edge Cache TTL:** Chọn `Override origin` -> `1 month` (Lưu trên server Cloudflare 1 tháng).
    *   **Browser Cache TTL:** Chọn `Override origin` -> `1 day` (Lưu trên máy người dùng 1 ngày).
5.  Nhấn **Deploy**.

---

## Bước 4: Cấu hình Tiered Cache (Tăng hiệu quả)

Tính năng này giúp các server Cloudflare chia sẻ cache với nhau, giảm tối đa số lần phải quay về hỏi VPS của bạn.

1.  Vào **Caching** -> **Configuration**.
2.  Tìm mục **Tiered Cache**.
3.  Bật **Argo Tiered Cache** (Miễn phí cho gói Free).

---

## Bước 5: Kiểm tra và Xác nhận (XEM KỸ)

Sau khi cấu hình xong, bạn hãy mở một link phim qua proxy và làm theo các bước:

1.  Mở **Chrome DevTools (F12)** -> Tab **Network**.
2.  Click vào một file có tên là `ts-proxy?url=...`
3.  Nhìn vào phần **Headers** -> **Response Headers**:
    *   **cf-cache-status: MISS**: Lần đầu tiên xem (Cloudflare đang lấy từ VPS).
    *   **cf-cache-status: HIT**: Từ lần thứ 2 trở đi (Cloudflare đang gánh - **THÀNH CÔNG**).
    *   **cf-cache-status: REVALIDATED**: Cloudflare đang kiểm tra lại file cũ (Vẫn tốt).

---

## Thông số kỳ vọng cho 1000 User:
*   **Băng thông VPS:** Chỉ tốn khoảng 5-10Mbps (để nạp file cho Cloudflare lần đầu).
*   **Băng thông Cloudflare:** Gánh 2000-3000Mbps (phục vụ người dùng).
*   **Trải nghiệm:** Tua phim cực nhanh vì dữ liệu được tải từ server Cloudflare đặt tại Việt Nam (VNPT/Viettel/FPT).

---
*Người viết: Antigravity AI Assistant*
