# 🧠 Chủ đề: DNS hoạt động như thế nào

## 📖 Giải thích

DNS (Domain Name System) là "danh bạ điện thoại" của internet — chuyển đổi tên miền dễ nhớ (`google.com`) thành địa chỉ IP máy tính hiểu được (`142.250.185.46`).

### Luồng xử lý khi bạn gõ `google.com`:

```
Browser → OS Cache → Recursive Resolver (ISP/8.8.8.8)
         → Root Nameserver (.) 
         → TLD Nameserver (.com)
         → Authoritative Nameserver (google.com)
         → Trả về IP
```

**Chi tiết từng bước:**

| Bước | Ai xử lý | Làm gì |
|------|----------|--------|
| 1 | OS/Browser | Kiểm tra cache local (`/etc/hosts`, browser cache) |
| 2 | Recursive Resolver | Nhận yêu cầu, đi hỏi thay client |
| 3 | Root Nameserver | "`.com`? Hỏi nameserver này đi" |
| 4 | TLD Nameserver | "`google.com`? Hỏi nameserver này đi" |
| 5 | Authoritative NS | "IP của `google.com` là `142.250.x.x`" |
| 6 | Cache + trả về | Resolver cache lại theo TTL, trả IP cho client |

### Các loại DNS Record quan trọng:

```
A       → domain → IPv4          (google.com → 142.250.185.46)
AAAA    → domain → IPv6
CNAME   → alias → domain thật    (www.google.com → google.com)
MX      → mail server
TXT     → metadata (SPF, DKIM, verify ownership)
NS      → nameserver của domain
PTR     → reverse DNS (IP → domain)
```

---

## 🧪 Ví dụ thực tế

**Tình huống:** Bạn deploy app lên server mới, trỏ domain về IP mới.

```
Trước: api.myapp.com → 103.1.2.3  (server cũ)
Sau:   api.myapp.com → 103.9.9.9  (server mới)
```

Bạn update DNS record lúc 10:00 AM. Nhưng đồng nghiệp vẫn bị lỗi lúc 10:30 AM vì:
- TTL của record cũ là 3600s (1 tiếng)
- Resolver của họ đang cache IP cũ
- Phải chờ TTL hết hạn mới fetch lại

**Lesson:** Trước khi migrate, hạ TTL xuống 60-300s trước 24h để rollout nhanh hơn.

---

**Tình huống 2:** CNAME vs A record

```
# Dùng CNAME cho subdomain trỏ về load balancer
app.mycompany.com  CNAME  → lb-prod.aws.amazon.com
                           (AWS tự quản lý IP thay đổi)

# Dùng A record khi biết IP cố định
admin.mycompany.com  A  → 10.0.0.5
```

---

## 💻 Command

```bash
# Tra cứu DNS cơ bản
nslookup google.com
dig google.com

# Xem toàn bộ record
dig google.com ANY

# Xem record cụ thể
dig google.com A
dig google.com MX
dig google.com TXT

# Hỏi thẳng một nameserver cụ thể (bypass cache local)
dig @8.8.8.8 google.com A

# Xem TTL còn lại
dig +ttlunits google.com A

# Reverse DNS (IP → domain)
dig -x 142.250.185.46

# Trace toàn bộ hành trình DNS
dig +trace google.com

# Kiểm tra DNS propagation (so sánh nhiều resolver)
dig @1.1.1.1 api.myapp.com A   # Cloudflare
dig @8.8.8.8 api.myapp.com A   # Google
dig @9.9.9.9 api.myapp.com A   # Quad9
```

```bash
# Flush DNS cache local (Windows)
ipconfig /flushdns

# Flush DNS cache (Linux systemd)
sudo systemd-resolve --flush-caches

# Xem /etc/hosts (override DNS)
cat /etc/hosts
```

---

## ⚠️ Lưu ý

**1. TTL ảnh hưởng trực tiếp đến tốc độ rollback**
- TTL cao (3600s) = cache lâu = khó rollback nhanh
- TTL thấp (60s) = nhiều query hơn, nhưng thay đổi nhanh
- Best practice: TTL 300s bình thường, hạ xuống 60s trước khi migrate

**2. `/etc/hosts` luôn thắng DNS**
```bash
# Dev thường dùng để mock domain local
127.0.0.1  api.myapp.local
127.0.0.1  db.myapp.local
```

**3. DNS không mã hóa (trừ DoH/DoT)**
- DNS thường → plaintext, bị ISP/attacker nhìn thấy
- DNS over HTTPS (DoH) / DNS over TLS (DoT) → mã hóa
- Cloudflare `1.1.1.1` hỗ trợ DoH/DoT

**4. DNS poisoning**
- Attacker inject record giả vào cache của resolver
- Phòng chống: DNSSEC (ký số các record)

**5. Propagation không phải lúc nào cũng 48h**
- Phụ thuộc vào TTL cũ, không phải con số cố định
- Sau khi TTL cũ hết, record mới được fetch ngay

---

## 🔥 Bài tập

**Bài 1 — Trace một domain:**
```bash
dig +trace github.com
```
Giải thích từng dòng output: Root NS nào được hỏi? TLD NS là gì? Authoritative NS là gì?

**Bài 2 — So sánh propagation:**
```bash
# Chọn 1 domain bất kỳ, query từ 3 resolver khác nhau
dig @1.1.1.1 stackoverflow.com A
dig @8.8.8.8 stackoverflow.com A
dig @208.67.222.222 stackoverflow.com A  # OpenDNS
# IP có giống nhau không? TTL có khác nhau không? Tại sao?
```

**Bài 3 — Mock domain local:**
Thêm vào `/etc/hosts`:
```
127.0.0.1  myapi.local
```
Sau đó chạy một HTTP server đơn giản và truy cập `http://myapi.local`. Giải thích tại sao nó hoạt động mà không cần DNS server.

**Bài 4 — Tư duy hệ thống:**
> Công ty bạn có domain `api.prod.com` với TTL = 3600s, đang trỏ về server A. Lúc 9:00 AM server A chết, bạn cần failover sang server B. Mất bao lâu tối đa để tất cả user thấy IP mới? Làm gì để giảm downtime lần sau?

---

**Tóm tắt 1 dòng:** DNS = danh bạ internet, hiểu TTL + record types là đủ để làm việc hàng ngày hiệu quả.
