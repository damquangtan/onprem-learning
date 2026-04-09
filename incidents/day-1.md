# 🚨 Incident: Ping OK nhưng app không kết nối được database

## Mô tả

Sau một lần deploy version mới, monitoring dashboard báo health check của service `order-api` fail. On-call engineer vào kiểm tra, thấy app log đầy lỗi "connection refused" khi kết nối đến database server.

## Triệu chứng

- Health check endpoint `/health` của `order-api` trả về `503 Service Unavailable`
- App log: `dial tcp 10.0.1.5:5432: connect: connection refused`
- `ping 10.0.1.5` từ app server → thành công, 0% packet loss
- Database server vẫn nhận được ping bình thường

## Nguyên nhân gốc rễ

Version mới của app có memory leak nghiêm trọng. Sau khoảng 10 phút chạy, app bị OOM (Out Of Memory) kill bởi Linux kernel. Tuy nhiên, **không phải app `order-api` bị kill — mà là `postgres` process trên DB server bị kill**.

Lý do: DB server và app server dùng chung một máy vật lý nhỏ trong môi trường staging-prod hybrid. Khi app dùng hết RAM, kernel chọn `postgres` (process dùng nhiều RAM nhất lúc đó) để kill.

Kết quả: DB server vẫn sống (ping OK), nhưng PostgreSQL process đã chết → không có gì listen ở port 5432 → `connection refused`.

## Cách debug từng bước

**Bước 1: Xác nhận network ổn**
```bash
ping 10.0.1.5
# → Thành công → Vấn đề không phải network tầng IP
# Ping OK không có nghĩa là database ổn, chỉ có nghĩa host đang sống
```

**Bước 2: Test port trực tiếp**
```bash
nc -zv 10.0.1.5 5432
# → nc: connect to 10.0.1.5 port 5432 (tcp) failed: Connection refused
# → Port 5432 không có gì listen → database process chết, hoặc port sai
```
Lệnh `nc -zv` (netcat) thử kết nối TCP đến host:port cụ thể và cho biết thành công hay thất bại. Khác ping ở chỗ: ping test tầng IP, nc test tầng TCP/port.

**Bước 3: SSH vào DB server, kiểm tra process**
```bash
ssh ubuntu@10.0.1.5
ps aux | grep postgres
# → Không thấy postgres process nào
# ps aux : hiện tất cả process đang chạy
# grep postgres : lọc chỉ những process có chữ "postgres"
```

**Bước 4: Kiểm tra port đang listen trên DB server**
```bash
ss -tlnp | grep 5432
# → Không có output → không có gì listen ở port 5432
# ss -tlnp : hiện tất cả TCP ports đang listen và process nào giữ chúng
```

**Bước 5: Kiểm tra OOM killer**
```bash
dmesg | grep -i "killed process"
# → [12345.678] Out of memory: Killed process 4521 (postgres) score 892
# dmesg : hiện kernel messages (log từ kernel)
# grep killed : lọc ra những dòng liên quan đến process bị kill
```

**Bước 6: Kiểm tra memory usage hiện tại**
```bash
free -m
# → Thấy RAM gần hết
# free -m : hiện RAM usage theo megabyte (available, used, free)
```

## Cách fix

```bash
# Restart PostgreSQL ngay lập tức
sudo systemctl restart postgresql
# systemctl restart : dừng rồi khởi động lại service

# Verify PostgreSQL đã chạy lại
systemctl status postgresql
# → Active: active (running)

# Test kết nối
nc -zv localhost 5432
# → Connection to localhost 5432 port [tcp/postgresql] succeeded!

# Giảm app xuống version cũ để tránh memory leak
# (rollback deployment)
```

## Bài học

1. **Ping chỉ kiểm tra host còn sống, không kiểm tra được service**. Khi debug "không kết nối được", luôn dùng thêm `nc -zv host port` để test port cụ thể.

2. **Khi thấy "connection refused" sau khi ping OK** → check ngay: process có chạy không (`ps aux`), port có listen không (`ss -tlnp`), OOM killer có hoạt động không (`dmesg | grep killed`).

3. **Tách DB server và app server** ra máy riêng ở production để tránh resource contention.
