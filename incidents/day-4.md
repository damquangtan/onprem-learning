Bạn chưa cấp quyền ghi file. Đây là nội dung incident — bạn có thể tự lưu hoặc cho phép tôi ghi:

---

# 🚨 Incident: Mixed Content / HTTP vs HTTPS

## Mô tả

Sau khi migrate toàn bộ hệ thống lên HTTPS, một số API call từ frontend bị block hoàn toàn trên trình duyệt. Tính năng upload ảnh và thanh toán không hoạt động. Phát hiện lúc 14:30, ảnh hưởng ~30% user đang dùng Chrome/Firefox phiên bản mới.

---

## Triệu chứng

- Browser console hiển thị lỗi:
  ```
  Mixed Content: The page at 'https://app.example.com' was loaded over HTTPS,
  but requested an insecure resource 'http://api.example.com/upload'.
  This request has been blocked; the content must be served over HTTPS.
  ```
- API call trả về `net::ERR_BLOCKED_BY_CLIENT`, không có response
- Safari vẫn hoạt động bình thường (policy khác nhau giữa các browser)
- Postman test trực tiếp `http://api.example.com` vẫn OK → dev không phát hiện sớm

---

## Nguyên nhân

Frontend deploy lên `https://app.example.com`, nhưng config production vẫn hardcode endpoint cũ:

```js
// config/production.js  ← thủ phạm
const API_BASE_URL = "http://api.example.com";  // ← thiếu S
```

Browser thực thi **Mixed Content Policy**: trang HTTPS không được phép gọi resource HTTP. Active mixed content (XHR/fetch) bị block hoàn toàn.

Lý do bị bỏ sót:
- Dev test bằng Postman — không có Mixed Content policy
- Staging chạy HTTP → HTTP, không trigger lỗi
- Không có E2E test trên browser thật với HTTPS

---

## Cách debug

**Bước 1** — `F12 → Console` → tìm `Mixed Content` hoặc `ERR_BLOCKED`

**Bước 2** — `F12 → Network` → lọc `Blocked/Failed` → xem Request URL có `http://` không

**Bước 3** — Scan bundle đã build:
```bash
grep -r "http://api" ./dist/
```

**Bước 4** — Kiểm tra CSP header:
```bash
curl -I https://app.example.com
# Tìm: Content-Security-Policy: upgrade-insecure-requests
```

**Bước 5** — Kiểm tra Nginx có forward `X-Forwarded-Proto` đúng không:
```bash
grep -r "proxy_set_header X-Forwarded-Proto" /etc/nginx/
```

---

## Cách fix

**Hotfix ngay:**
```js
const API_BASE_URL = "https://api.example.com";  // thêm S, redeploy
```

**Fix dài hạn:**

1. Dùng env variable thay vì hardcode:
   ```js
   const API_BASE_URL = process.env.VITE_API_URL;
   ```

2. Thêm CSP header ở Nginx:
   ```nginx
   add_header Content-Security-Policy "upgrade-insecure-requests";
   ```

3. Redirect HTTP → HTTPS ở API server:
   ```nginx
   server {
       listen 80;
       server_name api.example.com;
       return 301 https://$host$request_uri;
   }
   ```

4. Thêm bước scan vào CI/CD pipeline:
   ```bash
   grep -r "http://" ./dist/ && echo "ERROR: HTTP endpoint in build" && exit 1
   ```

5. E2E test chạy trên browser thật với staging HTTPS.

---

> **Lesson learned:** Postman và curl không có Mixed Content Policy. Luôn test trên browser thật với đúng scheme HTTPS trước khi release. Dev environment HTTP → HTTP che giấu lỗi chỉ xuất hiện trên production HTTPS.
