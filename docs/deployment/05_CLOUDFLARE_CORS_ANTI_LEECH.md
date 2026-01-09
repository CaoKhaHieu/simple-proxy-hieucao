# Hướng dẫn thiết lập CORS và Anti-Leech trên Cloudflare

Việc cấu hình bảo mật tại Cloudflare (Edge) giúp chặn các yêu cầu "xài chùa" link proxy ngay lập tức, tiết kiệm 100% tài nguyên cho server của bạn.

---

## 1. Thiết lập CORS (Cho phép Web của bạn truy cập)

Sử dụng **Transform Rules** để tự động thêm các header CORS vào phản hồi từ server.

### Các bước thực hiện:
1.  Truy cập **Cloudflare Dashboard** -> Chọn tên miền của bạn.
2.  Menu bên trái: Chọn **Rules** -> **Transform Rules**.
3.  Chọn tab **Modify Response Header** -> Nhấn **Create rule**.
4.  **Rule name**: `Add CORS Headers for HLS Proxy`.
5.  **If incoming requests match**:
    *   Field: `Hostname`
    *   Operator: `equals`
    *   Value: `hls.filmlearning.com`
6.  **Then modify response header**:
    *   Chọn **Set static**:
        *   Header: `Access-Control-Allow-Origin` | Value: `https://filmlearning.com`
    *   Nhấn **+ Add**:
        *   Header: `Access-Control-Allow-Methods` | Value: `GET, POST, OPTIONS`.
    *   Nhấn **+ Add**:
        *   Header: `Access-Control-Allow-Headers` | Value: `*`.
    *   Nhấn **+ Add**:
        *   Header: `Access-Control-Allow-Credentials` | Value: `true`.
7.  Nhấn **Deploy**.

---

## 2. Thiết lập Anti-Leech (Chặn tuyệt đối web lạ & truy cập trực tiếp)

Sử dụng **WAF (Web Application Firewall)** để đảm bảo video **CHỈ** có thể xem được khi nhúng vào trang web của bạn.

### Các bước thực hiện:
1.  Menu bên trái: Chọn **Security** -> **WAF**.
2.  Tại tab **Custom rules**, nhấn **Create rule**.
3.  **Rule name**: `Strict Block Unauthorized HLS Access`.
4.  **If incoming requests match** (Thiết lập 3 điều kiện nối với nhau bằng **And**):

    *   **Điều kiện 1**:
        *   Field: `Hostname`
        *   Operator: `equals`
        *   Value: `hls.filmlearning.com`
    *   *Nhấn nút **And***
    *   **Điều kiện 2**:
        *   Field: `Referer`
        *   Operator: `does not contain`
        *   Value: `filmlearning.com`
    *   *Nhấn nút **And***
    *   **Điều kiện 3**:
        *   Field: `HTTP Method`
        *   Operator: `does not equal`
        *   Value: `OPTIONS`

5.  **Choose action**: Chọn `Block`.
6.  Nhấn **Deploy**.

---

## 3. Lưu ý quan trọng

### Tránh trùng lặp Header
Khi đã bật CORS trên Cloudflare, bạn nên để trống biến `ALLOWED_DOMAINS` trong file `.env` của server để tránh việc trình duyệt nhận được 2 header CORS (gây lỗi).

### Kiểm tra sau khi thiết lập
1.  **Trên web của bạn**: Video phải play bình thường.
2.  **Dán link m3u8 trực tiếp vào trình duyệt**: Phải nhận được lỗi `403 Forbidden`.
3.  **Dùng web khác nhúng link**: Phải bị chặn bởi cả CORS và WAF.

---
*Người viết: Antigravity AI Assistant*
