# 🚨 Incident: Game server lag đột ngột sau khi "optimize" networking

## Mô tả

Team dev của một game mobile realtime quyết định "tối ưu" networking bằng cách chuyển từ UDP sang TCP cho việc gửi vị trí nhân vật (position updates) — với lý do "TCP đáng tin cậy hơn". Sau khi deploy lên production, hàng nghìn user báo game lag nặng, giật, không chơi được.

## Triệu chứng

- Ping từ client đến server vẫn thấp (~20ms)
- Nhưng nhân vật trong game di chuyển giật, đứng hình cách nhau 200-500ms
- CPU và RAM server bình thường
- Số lượng TCP connections tăng vọt lên ~50,000 connections đồng thời
- Server bắt đầu báo `Too many open files` sau 30 phút

## Nguyên nhân gốc rễ

**Đổi từ UDP sang TCP cho position updates là sai về mặt kiến trúc.**

Position update gửi 30 lần/giây từ mỗi client. Với TCP:
1. **Head-of-line blocking**: Nếu 1 packet bị mất → TCP block toàn bộ stream, chờ retry. Trong lúc đó vị trí nhân vật đứng hình.
2. **Dữ liệu stale**: Khi TCP retry thành công và gửi vị trí cũ → game nhận vị trí của 200ms trước → hiển thị sai.
3. **Connection overhead**: 10,000 players × 1 TCP connection mỗi player = 10,000 connections × resources (socket buffer, memory).

Với UDP trước đây: mất 1 packet → bỏ qua (vị trí cũ vài ms không quan trọng) → tiếp tục với packet mới nhất.

## Cách debug từng bước

**Bước 1: Xác nhận latency tầng network vẫn ổn**
```bash
ping game-server.example.com -c 20
# → 0% packet loss, avg 20ms
# → Network không phải vấn đề. Vấn đề ở tầng ứng dụng
```

**Bước 2: Kiểm tra số lượng TCP connections**
```bash
ss -tn | grep :7777 | wc -l
# ss -tn : hiện tất cả TCP connections (số thay hostname)
# grep :7777 : lọc port game server
# wc -l : đếm số dòng = số connections
# → Kết quả: 47,832 connections
```

**Bước 3: Xem trạng thái connections**
```bash
ss -tn | grep :7777 | awk '{print $1}' | sort | uniq -c
# → 45000 ESTAB (established — đang kết nối)
# → 2000 TIME_WAIT (đang đóng — TCP giữ lại 2 phút)
# Quá nhiều TIME_WAIT là dấu hiệu connection được tạo và đóng liên tục
```

**Bước 4: Kiểm tra file descriptor limit**
```bash
cat /proc/$(pgrep game-server)/limits | grep "open files"
# → Max open files: 65536
# Mỗi TCP connection = 1 file descriptor
# 50,000 connections gần đến giới hạn → "Too many open files"
```

**Bước 5: Xem memory usage của buffer TCP**
```bash
cat /proc/net/sockstat
# → TCP: inuse 47832 ... mem 98304
# → Mỗi TCP socket có send buffer và receive buffer (mặc định ~4-8KB mỗi loại)
# → 47,832 sockets × 16KB = ~750MB chỉ cho socket buffers
```

## Cách fix

**Fix ngay — rollback về UDP:**
```bash
# Rollback deployment về version cũ (dùng UDP)
kubectl rollout undo deployment/game-server
# Hoặc với systemd:
systemctl stop game-server
# Deploy binary cũ
systemctl start game-server
```

**Fix đúng — kiến trúc phù hợp:**
- Giữ UDP cho position updates (data realtime, stale data có thể bỏ)
- Dùng TCP cho những gì cần reliability: chat, purchase, match result

```
# Verify sau khi rollback
ss -tn | grep :7777 | wc -l
# → Số connections giảm đáng kể
# → Game không còn lag
```

## Bài học

1. **Chọn đúng giao thức cho đúng use case**. TCP "đáng tin cậy hơn" không có nghĩa là tốt hơn cho mọi trường hợp. Realtime data (vị trí, trạng thái) thường cần UDP.

2. **Head-of-line blocking của TCP**: Khi 1 packet bị delay → toàn bộ stream phải chờ. Với realtime game, đây là killer feature (theo nghĩa xấu).

3. **Load test trước khi deploy**: 10,000 TCP connections × resource overhead = vấn đề rõ ràng nếu có load test trước.
