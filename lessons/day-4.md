# 🧠 Chủ đề: HTTP vs HTTPS

## 📖 Giải thích

**HTTP (HyperText Transfer Protocol)** — giao thức truyền dữ liệu giữa client và server. Dữ liệu truyền đi **dạng plaintext**, ai cũng đọc được nếu bắt được packet.

**HTTPS = HTTP + TLS (Transport Layer Security)** — dữ liệu được **mã hóa** trước khi truyền. Ai bắt được packet cũng chỉ thấy rác.

### Cách hoạt động của TLS Handshake (đơn giản hóa):

```
Client                          Server
  |                               |
  |--- ClientHello -------------->|  (Tôi hỗ trợ TLS 1.3, cipher suites này)
  |<-- ServerHello + Certificate -|  (Dùng TLS 1.3, đây là cert của tôi)
  |--- Verify cert + Key Exchange>|  (Cert hợp lệ, trao đổi session key)
  |<-- Finished ------------------|  (OK, bắt đầu mã hóa)
  |=== Encrypted Data ============|
```

### So sánh nhanh:

| Tiêu chí | HTTP | HTTPS |
|---|---|---|
| Port mặc định | 80 | 443 |
| Mã hóa | Không | Có (TLS) |
| Certificate | Không cần | Cần (SSL cert) |
| SEO Google | Bị penalize | Ưu tiên |
| Tốc độ | Nhỉnh hơn chút | Gần như tương đương (HTTP/2) |

---

## 🧪 Ví dụ thực tế

**Tình huống:** User login vào web app của bạn.

**Với HTTP:**
```
POST /login HTTP/1.1
Host: myapp.com

username=admin&password=SuperSecret123
```
Kẻ tấn công dùng Wireshark trên cùng WiFi → đọc được password ngay.

**Với HTTPS:**
```
# Packet bắt được chỉ thấy:
TLSv1.3 Record Layer: Application Data Protocol: http-over-tls
    Encrypted Application Data: a3f8c2d1e9b4... (rác)
```

**Tình huống thực tế hơn — dev hay gặp:**
```bash
# Gọi API không có HTTPS → browser chặn Mixed Content
# Web bạn chạy HTTPS nhưng gọi:
fetch("http://api.internal/data")  # ❌ Browser block ngay

# Phải dùng:
fetch("https://api.internal/data")  # ✅
```

---

## 💻 Command

**Kiểm tra certificate của một domain:**
```bash
# Xem cert info
curl -vI https://google.com 2>&1 | grep -E "SSL|subject|expire|issuer"

# Kiểm tra ngày hết hạn cert
echo | openssl s_client -connect google.com:443 2>/dev/null \
  | openssl x509 -noout -dates
```

**Test HTTP vs HTTPS response:**
```bash
# HTTP → thường redirect sang HTTPS
curl -I http://github.com
# HTTP/1.1 301 Moved Permanently
# Location: https://github.com/

# HTTPS → trả về 200
curl -I https://github.com
# HTTP/2 200
```

**Tạo self-signed cert cho local dev:**
```bash
# Dùng mkcert (recommended cho dev)
brew install mkcert
mkcert -install
mkcert localhost 127.0.0.1

# Output: localhost+1.pem và localhost+1-key.pem
# Dùng trong Nginx/Node.js/etc.
```

**Config Nginx HTTPS cơ bản:**
```nginx
server {
    listen 443 ssl;
    server_name myapp.com;

    ssl_certificate     /etc/ssl/certs/myapp.pem;
    ssl_certificate_key /etc/ssl/private/myapp.key;
    ssl_protocols       TLSv1.2 TLSv1.3;  # Bỏ TLS 1.0, 1.1 vì đã deprecated

    location / {
        proxy_pass http://localhost:3000;
    }
}

# Redirect HTTP → HTTPS
server {
    listen 80;
    return 301 https://$host$request_uri;
}
```

---

## ⚠️ Lưu ý

**1. HTTPS không có nghĩa là site an toàn tuyệt đối**
> Chỉ đảm bảo dữ liệu *truyền đi* được mã hóa. Server vẫn có thể bị hack, code vẫn có thể có lỗ hổng.

**2. Mixed Content là lỗi phổ biến**
```
# Symptom: HTTPS site nhưng browser báo "Not Secure"
# Nguyên nhân: load resource qua HTTP
<img src="http://cdn.example.com/logo.png">  # ❌
<img src="https://cdn.example.com/logo.png"> # ✅
```

**3. Cert hết hạn = downtime**
```bash
# Dùng Let's Encrypt + certbot để auto-renew
certbot renew --dry-run  # test trước
# Thêm vào crontab để chạy mỗi ngày
0 0 * * * certbot renew --quiet
```

**4. TLS 1.0 và 1.1 đã bị deprecated (2020)**
> Nếu server vẫn support → bị scanner báo lỗi bảo mật, browser cũng cảnh báo.

**5. HTTP/2 chỉ chạy trên HTTPS**
> Muốn tận dụng HTTP/2 (multiplexing, header compression, nhanh hơn) → bắt buộc phải HTTPS.

---

## 🔥 Bài tập

**Bài 1 — Quan sát thực tế:**
```bash
# Dùng curl kiểm tra 3 site sau, xem response header khác nhau gì:
curl -I http://example.com
curl -I https://example.com
curl -I http://facebook.com  # Xem redirect như thế nào
```

**Bài 2 — Phân tích cert:**
```bash
# Kiểm tra cert của github.com
# Trả lời: cert do ai cấp? Hết hạn ngày nào? Hỗ trợ TLS version nào?
echo | openssl s_client -connect github.com:443 2>/dev/null | openssl x509 -noout -text | grep -E "Issuer|Not After|Version"
```

**Bài 3 — Setup local HTTPS:**
> Cài `mkcert`, tạo cert cho `localhost`, chạy một server Node.js/Nginx với HTTPS. Truy cập `https://localhost` không bị cảnh báo trên browser.

**Bài 4 — Tư duy:**
> Tại sao các internal service trong Kubernetes cluster (pod-to-pod) thường dùng HTTP thay vì HTTPS? Khi nào thì cần bật mTLS cho internal traffic?

---

> **Key takeaway:** HTTP = bưu thiếp (ai cũng đọc được). HTTPS = thư trong phong bì có khóa. Năm 2026, không có lý do gì để dùng HTTP cho production.
