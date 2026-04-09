# 📝 Quiz: SSH Tunnel

## Câu 1 (trắc nghiệm)

Bạn chạy `ssh -fNL 15432:db-internal:5432 user@bastion` rồi `psql -h localhost -p 15432`. Nhưng psql báo "Connection refused". Lệnh `ps aux | grep ssh` vẫn thấy tunnel process. Nguyên nhân khả năng nhất là gì?

a) Lệnh SSH sai cú pháp, port 15432 chưa được bind
b) Tunnel đã chết âm thầm vì firewall kill idle TCP connection — process còn nhưng port không còn forward
c) psql cần dùng IP thay vì localhost
d) Cần thêm flag `-v` để tunnel hoạt động

**Đáp án: b)**

**Giải thích:**
- Đây là lỗi phổ biến nhất với SSH tunnel. Firewall/NAT kill TCP connection idle sau vài phút. SSH process vẫn còn trong `ps aux` nhưng kết nối thực đã chết.
- Cách verify: `ss -tlnp | grep 15432` — nếu không thấy port đang listen → tunnel chết.
- Cách fix: kill process cũ và tạo tunnel mới, thêm `ServerAliveInterval 60` để tránh tái phát.
- a) Sai — nếu cú pháp sai thì SSH báo lỗi ngay từ đầu, không chạy được.
- c) Sai — localhost và 127.0.0.1 giống nhau, không phải vấn đề.
- d) Sai — `-v` chỉ là verbose mode để debug, không ảnh hưởng hoạt động.

---

## Câu 2 (trắc nghiệm)

Sự khác biệt chính giữa Local Forwarding (`-L`) và Remote Forwarding (`-R`) là gì?

a) `-L` dùng TCP còn `-R` dùng UDP
b) `-L` kéo service remote về local; `-R` expose service local ra phía remote
c) `-L` cần root permission còn `-R` thì không
d) `-L` chỉ dùng được với HTTP còn `-R` dùng được với mọi giao thức

**Đáp án: b)**

**Giải thích:**
- `-L local_port:remote_host:remote_port`: traffic vào `localhost:local_port` → đi qua SSH → ra `remote_host:remote_port`. Bạn đang "kéo" service ở xa về máy mình.
- `-R remote_port:local_host:local_port`: traffic vào `ssh_server:remote_port` → đi qua SSH → vào `local_host:local_port` của bạn. Bạn đang "đẩy" service local ra phía server.
- a) Sai — cả hai đều dùng TCP cho tunnel SSH. Giao thức bên trong tunnel có thể là bất kỳ thứ gì.
- c) Sai — cả hai không cần root (trừ khi bind port < 1024).
- d) Sai — cả hai hoạt động với mọi giao thức TCP, không chỉ HTTP.

---

## Câu 3 (tự luận)

Bạn đang dev một REST API ở `localhost:3000`. Bạn muốn cho khách hàng ở nơi khác thử API mà không cần deploy lên server. Bạn có một VPS với IP public `45.x.x.x`. Mô tả cách dùng SSH tunnel để làm điều này, và lệnh cụ thể cần chạy.

**Đáp án gợi ý:**

Dùng Remote Port Forwarding (`-R`) để expose `localhost:3000` ra `VPS:8080`:

```bash
ssh -fNR 8080:localhost:3000 user@45.x.x.x
# -R 8080:localhost:3000 : traffic vào VPS:8080 → forward qua SSH → localhost:3000
# -f : chạy nền
# -N : không mở shell
```

Khách hàng sau đó truy cập `http://45.x.x.x:8080`.

Lưu ý quan trọng: mặc định, port 8080 trên VPS chỉ bind ở `127.0.0.1` — khách hàng bên ngoài không vào được. Cần thêm `GatewayPorts yes` vào `/etc/ssh/sshd_config` trên VPS rồi restart sshd:
```bash
sudo systemctl restart sshd
```
Sau đó tạo lại tunnel.
