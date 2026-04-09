# 🧠 Chủ đề: DNS hoạt động như thế nào

## 📖 Giải thích

Hãy tưởng tượng bạn muốn gọi điện cho một người bạn. Bạn không nhớ số điện thoại của họ, nhưng bạn biết tên họ. Bạn tra danh bạ điện thoại → tìm ra số → gọi.

**DNS (Domain Name System)** là danh bạ của internet:
- Bạn nhớ tên: `google.com`
- Máy tính cần địa chỉ IP: `142.250.x.x`
- DNS là người dịch từ tên → địa chỉ IP

Không có DNS, bạn phải nhớ IP của mọi website bạn muốn vào — không thực tế.

### Cấu trúc phân cấp của DNS

DNS không phải một server duy nhất — nó là hệ thống phân cấp:

```
Root DNS Servers (13 cụm máy chủ gốc, quản lý ".")
    │
    ├── TLD Servers (Top Level Domain)
    │       .com, .vn, .org, .net...
    │
    └── Authoritative DNS Servers
            google.com → 142.250.x.x
            facebook.com → 31.13.x.x
```

### Luồng DNS query từ đầu đến cuối

Khi bạn gõ `google.com` vào browser:

```
Browser → [Cache local?] → Có → Dùng luôn
                         → Không → OS Cache → Có → Dùng luôn
                                             → Không → /etc/hosts → Có → Dùng luôn
                                                                  → Không → DNS Resolver (thường là router hoặc 8.8.8.8)
                                                                              │
                                                                              ├── Hỏi Root Server: ".com ở đâu?"
                                                                              ├── Root trả lời: "Hỏi TLD .com server"
                                                                              ├── Hỏi TLD .com: "google.com ở đâu?"
                                                                              ├── TLD trả lời: "Hỏi ns1.google.com"
                                                                              ├── Hỏi ns1.google.com: "google.com là IP gì?"
                                                                              └── Nhận: 142.250.x.x → Cache lại → Trả về browser
```

Quá trình này thường xảy ra trong vài millisecond vì DNS Resolver **cache** kết quả.

### TTL (Time To Live) trong DNS

Mỗi DNS record có TTL — thời gian được phép cache (đơn vị: giây):
- TTL = 300 → cache 5 phút, sau đó phải query lại
- TTL thấp → thay đổi DNS lan truyền nhanh, nhưng nhiều query hơn
- TTL cao → ít query hơn, nhưng khi thay đổi IP phải chờ lâu mới có hiệu lực

## 🧠 Tại sao cần biết điều này?

**Tình huống thực tế bạn sẽ gặp:**

1. Deploy app mới, đổi DNS trỏ sang server mới → tại sao một số user vẫn vào server cũ? (DNS cache chưa expire)
2. Trong Kubernetes, service discovery dùng DNS nội bộ → pod không tìm được service khác → debug DNS
3. App kết nối DB bằng hostname → DNS resolution fail → connection error
4. `nslookup` và `dig` là công cụ đầu tiên khi debug network issues

## 🧪 Ví dụ thực tế

**Tình huống 1:** Đổi IP server, cập nhật DNS record, nhưng sau 1 giờ một số user vẫn bị redirect sang server cũ.

→ Nguyên nhân: DNS record cũ có TTL = 3600 (1 giờ). Những user query trước khi bạn đổi đang dùng cache cũ. Phải chờ TTL expire. Bài học: **trước khi deploy migration, hạ TTL xuống 300 trước vài giờ**.

**Tình huống 2:** Trong Kubernetes, pod không connect được service khác:
```bash
# Trong pod:
curl http://my-service:8080/health
# → curl: (6) Could not resolve host: my-service

# Debug DNS trong pod:
nslookup my-service
# → Server: 10.96.0.10 (CoreDNS)
# → ** server can't find my-service: NXDOMAIN
# → DNS không biết my-service → service chưa tạo, hoặc sai namespace
```

## 💻 Command (giải thích từng dòng)

```bash
# Query DNS cơ bản — tìm IP của domain
nslookup google.com
# Output: Name: google.com, Address: 142.250.x.x

# dig — chi tiết hơn nslookup, dùng nhiều khi debug
dig google.com
# +ANSWER SECTION: google.com. 300 IN A 142.250.x.x
#                              │        │ └── IP address
#                              │        └──── A record (IPv4)
#                              └──────────── TTL còn lại: 300 giây

# Query loại record cụ thể
dig google.com A      # IPv4 address
dig google.com AAAA   # IPv6 address
dig google.com MX     # Mail server
dig google.com TXT    # Text records (SPF, DKIM...)
dig google.com NS     # Name servers

# Query đến một DNS server cụ thể (thay vì dùng DNS mặc định của hệ thống)
dig @8.8.8.8 google.com
# @ : chỉ định DNS server để hỏi (8.8.8.8 = Google DNS)

# Xem toàn bộ quá trình resolution từng bước
dig +trace google.com
# Hiện cả: Root → TLD → Authoritative → kết quả cuối

# Xem DNS đang được cấu hình trên máy
cat /etc/resolv.conf
# nameserver 8.8.8.8    ← DNS server máy bạn đang dùng

# Flush DNS cache (Linux với systemd-resolved)
sudo systemd-resolve --flush-caches

# Kiểm tra /etc/hosts (file override DNS, check trước khi query DNS)
cat /etc/hosts
```

**Các loại DNS record quan trọng:**

| Record | Dùng để |
|--------|---------|
| `A` | Map domain → IPv4 |
| `AAAA` | Map domain → IPv6 |
| `CNAME` | Alias domain → domain khác |
| `MX` | Mail server của domain |
| `TXT` | Text data (SPF, DKIM, xác minh domain) |
| `NS` | Name server của domain |

## ⚠️ Lưu ý

1. **`/etc/hosts` được check trước DNS**: Nếu bạn thêm `127.0.0.1 google.com` vào `/etc/hosts`, mọi DNS query cho google.com sẽ ra `127.0.0.1`. Hay dùng để test local.

2. **DNS dùng UDP port 53** (cho query nhỏ) và **TCP port 53** (cho response lớn hoặc zone transfer). Firewall block port 53 = DNS chết.

3. **Negative caching**: DNS cũng cache kết quả "không tìm thấy" (NXDOMAIN). Nếu bạn tạo record mới mà vẫn bị NXDOMAIN → có thể phải chờ negative TTL expire.

4. **DNS trong Docker/K8s**: Có DNS server riêng (CoreDNS). Service discovery dùng pattern `service-name.namespace.svc.cluster.local`.

## 🔥 Bài tập

1. Chạy `dig +trace google.com` và theo dõi từng bước — Root Server → TLD → Authoritative. Note lại TTL ở mỗi bước.

2. Chạy `dig google.com` 2 lần liên tiếp. Quan sát TTL thay đổi giữa 2 lần → giải thích tại sao.

3. Thêm dòng `127.0.0.1 testsite.local` vào `/etc/hosts`, rồi `ping testsite.local`. Chuyện gì xảy ra? Xóa dòng đó đi sau khi test.

4. **Tình huống**: App báo `getaddrinfo: Name or service not known` khi kết nối DB. Bạn sẽ debug bằng những lệnh nào, theo thứ tự nào?
