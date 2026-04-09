# 🧠 Chủ đề: HTTP vs HTTPS

## 📖 Giải thích

Hãy tưởng tượng bạn gửi thư tay cho ngân hàng, trong đó có số tài khoản và mật khẩu. Có 2 cách:

**HTTP — Gửi thư thường (không phong bì):** Ai cũng có thể đọc trên đường đi — người đưa thư, người ngồi cạnh xe, ai cũng thấy.

**HTTPS — Gửi thư trong hộp có khóa:** Chỉ bạn và ngân hàng có chìa khóa. Người khác bắt được hộp cũng không đọc được nội dung.

**HTTP (HyperText Transfer Protocol)** là giao thức truyền dữ liệu giữa browser và web server. **HTTPS** = HTTP + **TLS** (Transport Layer Security) — lớp mã hóa bảo vệ dữ liệu.

### HTTP hoạt động như thế nào?

```
Browser                         Web Server
  |                                  |
  |  GET /index.html HTTP/1.1        |
  |  Host: example.com               |
  |  ─────────────────────────────>  |
  |                                  |
  |  HTTP/1.1 200 OK                 |
  |  Content-Type: text/html         |
  |  <html>...</html>                |
  |  <─────────────────────────────  |
```

Toàn bộ nội dung này **gửi dưới dạng plaintext** — không mã hóa.

### HTTPS thêm TLS Handshake

Trước khi gửi/nhận bất cứ gì, browser và server phải "thỏa thuận" cách mã hóa:

```
Browser                         Server
  |                                  |
  |  "Tôi hỗ trợ TLS 1.3,           |
  |   dùng cipher suite nào?"        |
  |  ─────────────────────────────>  |
  |                                  |
  |  "Dùng AES-256. Đây là           |
  |   Certificate của tôi"           |
  |  <─────────────────────────────  |
  |                                  |
  |  [Verify Certificate]            |
  |  "Certificate hợp lệ.            |
  |   Đây là session key"            |
  |  ─────────────────────────────>  |
  |                                  |
  |  [Kết nối đã mã hóa]             |
  |  GET /index.html ...             |
  |  ═════════════════════════════>  |
```

### Certificate là gì?

Certificate (chứng chỉ SSL/TLS) giống như CMND của website:
- Chứng minh website này thực sự là `google.com`, không phải ai giả mạo
- Được cấp bởi **CA (Certificate Authority)** — tổ chức uy tín mà browser tin tưởng (Let's Encrypt, DigiCert...)
- Chứa **public key** dùng để thiết lập mã hóa

## 🧠 Tại sao cần biết điều này?

- Dùng HTTP thay HTTPS → dữ liệu user (password, token) bị lộ khi qua mạng công cộng
- Certificate hết hạn → browser báo lỗi, user không vào được
- Misconfigured HTTPS → app gửi mixed content (HTTP trong HTTPS) → browser block
- Debug API calls cần hiểu HTTP headers, status code, request/response format

## 🧪 Ví dụ thực tế

**Tình huống 1:** API trả về `401 Unauthorized` dù bạn đã gửi token.

Kiểm tra bằng curl:
```bash
curl -v -H "Authorization: Bearer mytoken123" https://api.example.com/data
# -v : verbose — hiện toàn bộ request và response headers
```
Output `< HTTP/1.1 401` + xem response body để hiểu lý do cụ thể.

**Tình huống 2:** Browser báo `NET::ERR_CERT_DATE_INVALID`.

→ Certificate hết hạn. Kiểm tra:
```bash
echo | openssl s_client -connect example.com:443 2>/dev/null | openssl x509 -noout -dates
# notAfter=... ← ngày hết hạn
```

**Tình huống 3:** App HTTP trong môi trường production bị chặn.

→ Nhiều browser hiện nay tự redirect HTTP → HTTPS. Server phải có HTTPS hoặc dùng redirect 301.

## 💻 Command (giải thích từng dòng)

```bash
# curl cơ bản — gửi GET request
curl https://api.example.com/health

# -v : verbose — hiện cả request headers và response headers
curl -v https://api.example.com/health

# -I : chỉ lấy headers, không lấy body (HTTP HEAD request)
curl -I https://google.com
# HTTP/2 200
# content-type: text/html; charset=UTF-8
# ...

# -X POST : gửi POST request
# -H : thêm header
# -d : request body (data)
curl -X POST https://api.example.com/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"secret"}'

# -L : follow redirect (HTTP 301/302)
curl -L http://google.com
# HTTP/1.1 301 → redirect đến https://google.com
# HTTP/2 200 → trang thật

# Kiểm tra certificate của một domain
openssl s_client -connect example.com:443
# Hiện thông tin certificate, ngày hết hạn, CA

# Xem ngày hết hạn certificate
echo | openssl s_client -connect example.com:443 2>/dev/null | openssl x509 -noout -dates
# notBefore=Jan 1 00:00:00 2024 GMT
# notAfter=Jan 1 00:00:00 2025 GMT  ← hết hạn ngày này
```

**HTTP Status Code quan trọng:**

| Code | Ý nghĩa | Gặp khi |
|------|---------|---------|
| `200` | OK | Thành công |
| `201` | Created | POST tạo resource thành công |
| `301/302` | Redirect | Domain đổi, HTTP → HTTPS |
| `400` | Bad Request | Request sai format/thiếu field |
| `401` | Unauthorized | Chưa auth hoặc token sai |
| `403` | Forbidden | Đã auth nhưng không có quyền |
| `404` | Not Found | URL không tồn tại |
| `500` | Internal Server Error | Bug phía server |
| `502` | Bad Gateway | Reverse proxy không reach được backend |
| `503` | Service Unavailable | Server quá tải hoặc đang down |

## ⚠️ Lưu ý

1. **HTTP/1.1 vs HTTP/2 vs HTTP/3**: HTTP/1.1 dùng một kết nối per request. HTTP/2 multiplexing — nhiều request qua 1 kết nối. HTTP/3 dùng QUIC (UDP-based). Khi debug, biết phiên bản HTTP đang dùng giúp hiểu performance.

2. **Mixed content**: Nếu trang HTTPS load resource qua HTTP (ảnh, script) → browser block. Luôn dùng HTTPS cho mọi resource.

3. **Self-signed certificate**: Certificate tự ký không được tin tưởng bởi browser. OK cho internal/dev, không dùng production. `curl -k` để bỏ qua verify certificate (chỉ dùng khi debug).

4. **HSTS (HTTP Strict Transport Security)**: Header báo browser "chỉ dùng HTTPS cho domain này". Một khi set, browser từ chối HTTP hoàn toàn — kể cả khi server cho phép.

## 🔥 Bài tập

1. Chạy `curl -v https://google.com 2>&1 | head -50`. Đọc output và xác định:
   - TLS version đang dùng là gì?
   - HTTP version là gì?
   - Status code là gì?

2. Chạy `curl -I http://google.com`. Thấy status code gì? Tại sao?

3. Kiểm tra certificate của một website bất kỳ bằng `openssl s_client`. Xem ngày hết hạn.

4. **Tình huống**: API trả về `403 Forbidden` dù bạn đã đăng nhập thành công và có token. 3 nguyên nhân có thể là gì?
