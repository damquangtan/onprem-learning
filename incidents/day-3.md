# 🚨 Incident: Deploy mới xong — một số user không vào được app

## Mô tả

Team deploy version mới của `web-app`, bao gồm đổi domain từ `app.company.com` sang `www.company.com`. DNS record được update và đã verify bằng `dig` từ máy của engineer. Nhưng 2 giờ sau deploy, vẫn có user báo vào app bị lỗi "This site can't be reached" hoặc vào được nhưng thấy version cũ.

## Triệu chứng

- Khoảng 30% user báo lỗi hoặc thấy nội dung cũ
- Từ máy engineer: `dig www.company.com` → IP mới ✓
- Từ máy user bị lỗi: `dig www.company.com` → IP cũ (server đã tắt)
- Không có lỗi ở phía server mới

## Nguyên nhân gốc rễ

DNS record cũ có **TTL = 86400 giây (24 giờ)**. Những user đã visit app trong 24 giờ trước khi deploy đang có DNS cache trỏ về IP cũ. IP cũ đã bị tắt → "This site can't be reached".

Engineer verify từ máy mình thành công vì máy đó chưa từng query `www.company.com` nên không có cache cũ.

## Cách debug từng bước

**Bước 1: Verify DNS record từ authoritative server (bỏ qua cache)**
```bash
dig @8.8.8.8 www.company.com
# @8.8.8.8 : query thẳng đến Google DNS (bypass local cache)
# → Kết quả: IP mới ✓
# → DNS record đã cập nhật đúng trên authoritative server
```

**Bước 2: Kiểm tra TTL còn lại**
```bash
dig www.company.com
# Xem dòng ANSWER SECTION:
# www.company.com. 82340 IN A 1.2.3.4
#                  ^^^^^
#                  TTL còn lại: 82340 giây (~22 giờ nữa cache mới expire)
```

**Bước 3: Query từ nhiều DNS resolver khác nhau để xác nhận**
```bash
dig @1.1.1.1 www.company.com   # Cloudflare DNS
dig @8.8.8.8 www.company.com   # Google DNS
dig @208.67.222.222 www.company.com  # OpenDNS
# Nếu tất cả đều trả về IP mới → vấn đề là client cache, không phải propagation
```

**Bước 4: Hướng dẫn user bị lỗi flush DNS cache**
```bash
# Linux (systemd-resolved)
sudo systemd-resolve --flush-caches

# macOS
sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder

# Windows
ipconfig /flushdns

# Sau khi flush, thử lại → vào được → xác nhận vấn đề là client DNS cache
```

**Bước 5: Kiểm tra TTL ban đầu của record cũ**
```bash
# Xem lịch sử qua DNS history tool, hoặc hỏi team DNS admin
# TTL cũ là 86400 (24 giờ) → user nào query trong 24h trước deploy đều bị cache cũ
```

## Cách fix

**Tức thì (giảm thiểu tác động):**
- Hướng dẫn user bị ảnh hưởng flush DNS cache (xem lệnh bước 4)
- Nếu có thể: giữ server cũ sống thêm vài giờ hoặc setup redirect từ IP cũ sang IP mới

**Lâu dài (quy trình chuẩn cho lần sau):**

Trước khi migration DNS, luôn thực hiện "TTL lowering":
```
T-48h: Hạ TTL từ 86400 xuống 300 (5 phút)
T-0h:  Chờ ít nhất 48 giờ (bằng TTL cũ) để cache cũ expire
       Sau đó đổi IP → chỉ cần chờ tối đa 5 phút là tất cả user thấy IP mới
T+1h:  Sau khi verify ổn, tăng TTL lại về 3600 hoặc 86400
```

## Bài học

1. **TTL cao = thay đổi lan chậm**. TTL 24 giờ nghĩa là một số user có thể thấy địa chỉ cũ đến 24 giờ sau khi bạn thay đổi.

2. **Luôn hạ TTL trước khi migration DNS** — ít nhất bằng thời gian TTL hiện tại để cache cũ expire.

3. **Dùng `dig @8.8.8.8`** khi verify DNS — query thẳng đến authoritative, không bị ảnh hưởng bởi local cache của máy bạn.

4. **Không tắt server cũ ngay** sau khi đổi DNS. Giữ vài giờ để xử lý user còn cache cũ.
