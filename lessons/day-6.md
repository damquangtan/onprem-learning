# 🧠 Chủ đề: SSH Tunnel

## 📖 Giải thích

Hãy tưởng tượng bạn cần lấy tài liệu từ kho lưu trữ bí mật. Kho này nằm sâu trong tòa nhà — không có cổng trực tiếp ra ngoài. Nhưng bạn có thể vào văn phòng bảo vệ (bastion), và từ đó bảo vệ sẽ giúp bạn lấy tài liệu từ kho.

**SSH Tunnel** hoạt động y hệt vậy: forward traffic qua một kết nối SSH đã mã hóa, để bạn reach được những service không expose trực tiếp ra internet.

### 3 loại SSH Tunnel

**Loại 1 — Local Port Forwarding (`-L`): Kéo service về máy mình**

```
Máy bạn                  Bastion                  DB Server
localhost:15432  ──SSH──>  bastion  ──────────>  10.0.1.5:5432
```
"Mọi traffic gửi đến `localhost:15432` của tôi → đi qua SSH → ra `10.0.1.5:5432`"

**Loại 2 — Remote Port Forwarding (`-R`): Expose service local ra ngoài**

```
Internet                 Server public            Máy bạn
client  ──────────>  server:9090  ──SSH──>  localhost:3000
```
"Ai kết nối vào `server:9090` → đi qua SSH → đến `localhost:3000` của tôi"

**Loại 3 — Dynamic Forwarding (`-D`): SSH làm SOCKS proxy**

```
Browser (SOCKS proxy: localhost:1080)  ──SSH──>  Bastion  ──>  Bất kỳ host nào
```
"Dùng SSH server như VPN — route toàn bộ traffic qua đó"

## 🧠 Tại sao cần biết điều này?

**Tình huống thực tế bạn sẽ gặp ngay:**
- Database production không expose public — chỉ access được từ bastion → dùng `-L` để kết nối từ DBeaver/TablePlus trên máy bạn
- Cần demo app đang dev trên localhost cho khách hàng — dùng `-R` để expose tạm
- Cần truy cập Kibana, Grafana, hay internal dashboard mà không cần VPN — dùng `-D`

SSH Tunnel là "VPN nghèo" — nhanh setup, không cần cài thêm gì, dùng được ngay với SSH có sẵn.

## 🧪 Ví dụ thực tế

**Tình huống 1 — Kết nối DB production từ DBeaver:**

DB Production (`10.0.1.5:5432`) chỉ mở cho bastion. Bastion có địa chỉ `bastion.prod.com`.

```bash
# Tạo tunnel: local port 15432 → qua bastion → đến DB
ssh -fNL 15432:10.0.1.5:5432 ec2-user@bastion.prod.com
# -f : chạy nền (background) — không chiếm terminal
# -N : không mở shell — chỉ forward port, không làm gì khác
# -L 15432:10.0.1.5:5432 : local_port:remote_host:remote_port

# Giờ kết nối DBeaver đến localhost:15432 = vào được DB production
psql -h localhost -p 15432 -U myuser mydb
```

**Tình huống 2 — Demo app local cho khách:**

App đang chạy ở `localhost:3000`. Bạn có server public `myserver.com`.

```bash
ssh -fNR 9090:localhost:3000 user@myserver.com
# -R 9090:localhost:3000 : remote_port:local_host:local_port
# → Khách hàng vào myserver.com:9090 thấy app local của bạn
```

**Tình huống 3 — Xem Grafana internal qua SOCKS proxy:**

```bash
ssh -fND 1080 ec2-user@bastion.prod.com
# -D 1080 : tạo SOCKS proxy ở local port 1080
# → Cấu hình browser: SOCKS5 proxy localhost:1080
# → Browse http://grafana.internal:3000 như đang ở trong mạng internal
```

## 💻 Command (giải thích từng dòng)

```bash
# LOCAL FORWARDING (-L)
ssh -L [local_port]:[remote_host]:[remote_port] user@ssh_server

# Ví dụ đầy đủ, chạy nền
ssh -fNL 15432:db-internal:5432 user@bastion
# -f : fork to background (chạy nền)
# -N : no remote commands (không mở shell, chỉ forward)
# -L : local forwarding
# 15432 : port trên máy bạn
# db-internal:5432 : host:port đích (tính từ bastion)

# REMOTE FORWARDING (-R)
ssh -fNR 9090:localhost:3000 user@public-server

# DYNAMIC / SOCKS PROXY (-D)
ssh -fND 1080 user@bastion

# Kiểm tra tunnel đang chạy — tìm SSH processes
ps aux | grep 'ssh -fN'

# Kiểm tra port có đang listen không
ss -tlnp | grep 15432
# Nếu thấy → tunnel sống
# Nếu không thấy → tunnel đã chết dù process còn đó

# Kill tunnel
kill $(ps aux | grep 'ssh -fNL 15432' | grep -v grep | awk '{print $2}')
```

**Cấu hình `~/.ssh/config` để dùng lại dễ dàng:**
```
Host bastion-db
  HostName bastion.prod.com
  User ec2-user
  IdentityFile ~/.ssh/prod.pem
  LocalForward 15432 10.0.1.5:5432
  ServerAliveInterval 60       ← giữ tunnel sống, không bị firewall kill
  ServerAliveCountMax 3

Host bastion-proxy
  HostName bastion.prod.com
  User ec2-user
  DynamicForward 1080
  ServerAliveInterval 60
```

Sau đó: `ssh -fN bastion-db` là xong.

**autossh — tự reconnect khi tunnel chết:**
```bash
# Cài: sudo apt install autossh
autossh -M 0 -fNL 15432:db-internal:5432 \
  -o ServerAliveInterval=60 \
  -o ServerAliveCountMax=3 \
  user@bastion
# -M 0 : tắt monitoring port của autossh (dùng ServerAlive thay)
# autossh tự detect tunnel chết và reconnect
```

## ⚠️ Lưu ý

1. **Tunnel chết âm thầm**: Firewall/NAT kill TCP connection idle sau vài phút. SSH process vẫn còn trong `ps aux` nhưng port không còn forward nữa. **Luôn verify bằng `ss -tlnp`**, không chỉ `ps aux`.

2. **`-f` + `-N` là combo chuẩn**: `-f` chạy nền, `-N` không mở shell. Thiếu `-N` thì SSH mở shell và chờ — không đúng với mục đích chỉ forward port.

3. **Remote forwarding và GatewayPorts**: Mặc định `-R` chỉ bind `127.0.0.1` trên remote server — chỉ server đó tự access được. Muốn public access phải thêm `GatewayPorts yes` vào `/etc/ssh/sshd_config` trên server.

4. **Port conflict**: Nếu local port đã được dùng bởi process khác → SSH báo lỗi `bind: Address already in use`. Dùng `ss -tlnp | grep PORT` để check trước.

## 🔥 Bài tập

1. Tạo local forward từ `localhost:8080` đến một web server bạn có quyền SSH. Verify bằng `curl localhost:8080` và `ss -tlnp | grep 8080`.

2. Sau khi tạo tunnel, thử kill process SSH đó rồi chạy lại `ss -tlnp | grep 8080`. Quan sát port biến mất.

3. **Tình huống**: DB production chỉ mở port 5432 cho bastion (`54.x.x.x`). Từ máy dev, viết lệnh SSH tunnel để kết nối DB qua local port `15432`. Sau đó verify tunnel hoạt động.

4. Thêm cấu hình vào `~/.ssh/config` cho tunnel DB ở bài 3, với `ServerAliveInterval 60`. Test bằng cách dùng alias.
