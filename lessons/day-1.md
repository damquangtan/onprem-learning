# 🧠 Chủ đề: ping và ICMP

## 📖 Giải thích

**ICMP (Internet Control Message Protocol)** là giao thức tầng network (OSI Layer 3) dùng để gửi thông báo lỗi và kiểm tra kết nối. Không truyền dữ liệu ứng dụng — chỉ dùng cho diagnostics.

**ping** dùng ICMP Echo Request/Reply để kiểm tra:
- Host có sống không?
- Latency (RTT — round trip time) là bao nhiêu?
- Có packet loss không?

Luồng hoạt động:
```
Client → [ICMP Echo Request] → Server
Client ← [ICMP Echo Reply]  ← Server
```

## 🧪 Ví dụ thực tế

Tình huống: Service A không gọi được Service B. Bước đầu tiên — kiểm tra network level:

```bash
ping service-b-host
```

- Nếu ping OK nhưng HTTP vẫn lỗi → vấn đề ở tầng ứng dụng (port, firewall rule, process chết)
- Nếu ping fail → vấn đề ở tầng network (routing, host down, firewall block ICMP)

## 💻 Command

```bash
# Ping cơ bản
ping google.com

# Giới hạn số lần (Linux)
ping -c 4 google.com

# Giới hạn số lần (Windows)
ping -n 4 google.com

# Ping với packet size lớn hơn (test MTU)
ping -s 1400 google.com

# Đọc output
# 64 bytes from 142.250.x.x: icmp_seq=1 ttl=118 time=12.3 ms
#                                          ^^^^^^^^^^^       ^^^^^^^
#                                          TTL còn lại       RTT
```

## ⚠️ Lưu ý

1. **Ping bị block ≠ host down**: Nhiều server/firewall chặn ICMP. Ping fail không có nghĩa service chết.
2. **TTL (Time To Live)**: Mỗi hop giảm 1. Linux mặc định TTL=64, Windows=128.
3. **Ping không test port**: Ping OK không đảm bảo port 80/443 mở. Dùng `curl` hoặc `telnet` để test port.
4. **Trong container/k8s**: Pod ping được nhau nhưng DNS có thể chưa resolve — phải test thêm.

## 🔥 Bài tập

1. Chạy `ping -c 10 8.8.8.8` và giải thích: TTL là gì, packet loss bao nhiêu %?
2. Thử `ping localhost` và `ping 127.0.0.1` — khác gì nhau?
3. Nếu `ping db-server` thành công nhưng app báo "Connection refused" — nguyên nhân có thể là gì?
