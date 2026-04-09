# 🚨 Incident: Certificate hết hạn lúc 3 giờ sáng — toàn bộ API down

## Mô tả

Lúc 3:15 sáng, toàn bộ mobile app của công ty ngừng hoạt động. User không thể login, không thể dùng bất kỳ tính năng nào. Monitoring báo 100% API calls fail với lỗi SSL. On-call engineer nhận alert lúc 3:20.

## Triệu chứng

- App mobile báo: "The certificate for this server is invalid"
- Browser: `NET::ERR_CERT_DATE_INVALID`
- `curl https://api.company.com/health` báo: `curl: (60) SSL certificate problem: certificate has expired`
- HTTP (không HTTPS) vẫn hoạt động nhưng app không có fallback HTTP
- 100% user không dùng được app

## Nguyên nhân gốc rễ

SSL/TLS certificate của `api.company.com` hết hạn đúng lúc 3:00 AM. Certificate được mua từ CA 1 năm trước, không có auto-renewal. Không ai setup cảnh báo về ngày hết hạn.

## Cách debug từng bước

**Bước 1: Xác nhận vấn đề là certificate**
```bash
curl -v https://api.company.com/health 2>&1 | grep -A5 "SSL"
# -v : verbose, hiện chi tiết SSL handshake
# → SSL certificate problem: certificate has expired
# Xác nhận ngay: vấn đề là certificate, không phải server down hay DNS
```

**Bước 2: Xem thông tin certificate chi tiết**
```bash
echo | openssl s_client -connect api.company.com:443 2>/dev/null | openssl x509 -noout -dates -subject
# openssl s_client -connect : kết nối SSL đến host:port
# openssl x509 -noout -dates : đọc certificate và hiện ngày hết hạn
# -subject : hiện certificate được cấp cho domain nào

# Output:
# subject=CN = api.company.com
# notBefore=Jan 15 00:00:00 2023 GMT
# notAfter=Jan 15 00:00:00 2024 GMT   ← đã hết hạn
```

**Bước 3: Verify certificate hiện tại trên server**
```bash
ssh ubuntu@api-server
ls -la /etc/nginx/ssl/
# → api.company.com.crt (thấy file, nhưng nội dung đã expire)

# Xem ngày hết hạn của cert file trực tiếp
openssl x509 -in /etc/nginx/ssl/api.company.com.crt -noout -enddate
# → notAfter=Jan 15 00:00:00 2024 GMT  ← hết hạn
```

## Cách fix

**Fix ngay (trong đêm):**
```bash
# Cài certbot nếu chưa có
sudo apt install certbot python3-certbot-nginx

# Lấy certificate mới từ Let's Encrypt (miễn phí)
sudo certbot --nginx -d api.company.com
# certbot tự verify domain, lấy cert mới, cấu hình nginx, reload nginx

# Verify cert mới
echo | openssl s_client -connect api.company.com:443 2>/dev/null | openssl x509 -noout -dates
# → notAfter=Apr 15 00:00:00 2024 GMT  ← 90 ngày từ hôm nay

# Test HTTPS
curl https://api.company.com/health
# → {"status":"ok"}  ✓
```

**Fix lâu dài — tránh tái phát:**
```bash
# Setup auto-renewal với certbot (Let's Encrypt cert hết hạn sau 90 ngày, cần renew mỗi 60 ngày)
sudo crontab -e
# Thêm dòng này:
# 0 3 * * * certbot renew --quiet && systemctl reload nginx
# → Chạy lúc 3AM mỗi ngày, renew nếu cert sắp hết hạn (trong 30 ngày)

# Setup monitoring cảnh báo trước 30 ngày hết hạn
# Prometheus blackbox exporter hoặc script cron:
echo | openssl s_client -connect api.company.com:443 2>/dev/null \
  | openssl x509 -noout -checkend 2592000  # 30 ngày = 2592000 giây
# → exit code 1 nếu cert hết hạn trong 30 ngày → trigger alert
```

## Bài học

1. **Certificate hết hạn là sự cố hoàn toàn tránh được**. Setup auto-renewal ngay từ đầu, đừng quản lý manually.

2. **Let's Encrypt + certbot** là lựa chọn miễn phí, phổ biến, hỗ trợ auto-renewal tốt.

3. **Monitor ngày hết hạn certificate** — alert ít nhất 30 ngày trước. Nhiều monitoring tool (Datadog, Prometheus, UptimeRobot) có tính năng này.

4. **Test HTTPS sau mỗi lần renew**: `curl -v https://domain.com` để xác nhận cert mới hoạt động.
