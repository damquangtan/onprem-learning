# 🚨 Incident: Deployment mới lên production — một số user không vào được app

## Mô tả

Team vừa migrate service `api.company.com` từ server cũ (IP `203.0.113.10`) sang server mới (IP `203.0.113.99`). Đã update DNS record, tưởng xong. Nhưng 2 tiếng sau vẫn có ~30% user báo lỗi connection timeout.

---

## Triệu chứng

- User A (Hà Nội): vào app bình thường
- User B (TP.HCM): `ERR_CONNECTION_TIMED_OUT`
- Server mới chạy tốt, health check pass
- `curl https://api.company.com` từ máy dev → OK
- Monitoring thấy traffic vào server mới đúng, nhưng server cũ vẫn nhận ~30% request

---

## Nguyên nhân

**DNS TTL còn quá cao + DNS caching nhiều tầng.**

Trước khi migrate, DNS record `api.company.com A 203.0.113.10` có TTL = **7200 giây (2 tiếng)**.

Khi update record sang IP mới, các DNS resolver đã cache record cũ sẽ tiếp tục dùng IP cũ cho đến khi TTL hết hạn. Tùy vào thời điểm resolver của từng user cache lại:

```
User A resolver cache → đã expire → resolve IP mới ✅
User B resolver cache → còn 90 phút TTL → vẫn trỏ IP cũ ❌
```

Server cũ đã bị tắt → user B timeout.

---

## Cách debug

**1. Kiểm tra record hiện tại đang resolve về đâu:**
```bash
# Hỏi authoritative nameserver — luôn trả về record mới nhất
dig @ns1.company.com api.company.com

# Hỏi public resolver — có thể còn cache cũ
dig @8.8.8.8 api.company.com
dig @1.1.1.1 api.company.com
```

**2. Kiểm tra TTL còn lại của cache:**
```bash
# Số giây còn lại trong cache của 8.8.8.8
dig @8.8.8.8 api.company.com | grep -i ttl
```

**3. Xác nhận server cũ đã down:**
```bash
curl -v --resolve api.company.com:443:203.0.113.10 https://api.company.com
# → Connection refused hoặc timeout = confirm root cause
```

**4. Theo dõi propagation toàn cầu:**
```
whatsmydns.net → check api.company.com từ nhiều location
```

---

## Cách fix

**Fix ngay (tạm thời):**

Bật lại server cũ, forward traffic sang server mới để user không bị timeout trong lúc chờ TTL expire:

```nginx
# Trên server cũ — proxy sang server mới
location / {
    proxy_pass http://203.0.113.99;
}
```

**Fix gốc rễ — rút kinh nghiệm cho lần sau:**

Hạ TTL **trước khi migrate** ít nhất bằng TTL hiện tại:

```
# 48h trước migration
api.company.com A 203.0.113.10 TTL=300   ← hạ xuống 5 phút

# Lúc migrate — chỉ cần chờ 5 phút là toàn bộ cache expire
api.company.com A 203.0.113.99 TTL=300

# Sau khi ổn định — tăng TTL lại
api.company.com A 203.0.113.99 TTL=3600
```

**Checklist migration DNS chuẩn:**

| Bước | Timing | Action |
|------|--------|--------|
| 1 | T-48h | Hạ TTL xuống 300s |
| 2 | T-0 | Đổi IP, chờ `300s` |
| 3 | T+5m | Verify bằng `dig` nhiều resolver |
| 4 | T+1h | Tắt server cũ |
| 5 | T+24h | Tăng TTL trở lại |

---

**Bài học:** TTL không phải chỉ là metadata — nó quyết định bao lâu thế giới "quên" IP cũ của bạn. Migrate DNS mà không hạ TTL trước = đặt cược vào may mắn.
