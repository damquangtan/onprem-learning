# 🧠 Chủ đề: TCP vs UDP

---

## 📖 Giải thích

### TCP (Transmission Control Protocol)
- **Có kết nối** (connection-oriented): bắt tay 3 bước trước khi gửi data
- **Đảm bảo thứ tự** và **không mất gói**
- **Chậm hơn** vì phải xác nhận từng packet (ACK)
- Dùng khi: **data chính xác quan trọng hơn tốc độ**

```
Client → SYN   → Server
Client ← SYN-ACK ← Server
Client → ACK   → Server
✅ Kết nối thiết lập, bắt đầu gửi data
```

### UDP (User Datagram Protocol)
- **Không kết nối** (connectionless): gửi thẳng, không hỏi
- **Không đảm bảo** thứ tự, có thể mất gói
- **Nhanh hơn** vì không overhead
- Dùng khi: **tốc độ quan trọng hơn độ chính xác**

```
Client → Packet 1 → Server
Client → Packet 2 → Server  ← có thể mất, không ai biết
Client → Packet 3 → Server
```

### So sánh nhanh

| | TCP | UDP |
|---|---|---|
| Kết nối | Bắt buộc | Không cần |
| Độ tin cậy | Cao | Thấp |
| Thứ tự | Đảm bảo | Không đảm bảo |
| Tốc độ | Chậm hơn | Nhanh hơn |
| Overhead | Cao | Thấp |

---

## 🧪 Ví dụ thực tế

### Dùng TCP khi nào?
- **REST API / HTTP/HTTPS** → mất 1 byte trong response JSON là hỏng hết
- **Database connection** (MySQL, PostgreSQL) → query sai là thảm họa
- **File transfer** (FTP, SCP) → file corrupt = vô dụng
- **Email** (SMTP, IMAP) → thiếu chữ = hiểu sai ý

### Dùng UDP khi nào?
- **Video call** (Zoom, Google Meet) → mất 1 frame thì hơi giật, chấp nhận được
- **Online game** (PUBG, CS:GO) → vị trí player cần realtime, cũ 1ms = lag
- **DNS lookup** → query nhỏ, trả lời nhanh, miss thì retry
- **Live streaming** (Twitch, YouTube Live) → buffer 1-2s, không cần mọi frame
- **IoT sensors** → gửi nhiệt độ mỗi giây, mất 1 packet không sao

---

## 💻 Command

### Kiểm tra connections TCP/UDP đang mở

```bash
# Xem tất cả TCP connections
netstat -tnp

# Xem tất cả UDP
netstat -unp

# Xem port đang listen (Linux)
ss -tlnp

# Xem port đang listen (Windows)
netstat -ano | findstr LISTENING
```

### Test TCP connection

```bash
# Test TCP port có mở không
telnet google.com 443
nc -zv google.com 443        # netcat

# Scan TCP port với nmap
nmap -sT -p 80,443 google.com
```

### Test UDP

```bash
# Test UDP port
nc -zuv 8.8.8.8 53           # DNS dùng UDP port 53

# Capture packets (cần sudo)
tcpdump -i eth0 udp port 53
tcpdump -i eth0 tcp port 80
```

### Ví dụ code Python — TCP Server/Client

```python
# TCP Server
import socket
server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
server.bind(('0.0.0.0', 9000))
server.listen(1)
conn, addr = server.accept()
print(conn.recv(1024).decode())

# TCP Client
client = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
client.connect(('127.0.0.1', 9000))
client.send(b'Hello TCP!')
```

```python
# UDP Server
import socket
server = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
server.bind(('0.0.0.0', 9001))
data, addr = server.recvfrom(1024)
print(data.decode())

# UDP Client - gửi thẳng, không cần connect
client = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
client.sendto(b'Hello UDP!', ('127.0.0.1', 9001))
```

---

## ⚠️ Lưu ý

**TCP:**
- **TIME_WAIT state**: sau khi đóng kết nối, socket vẫn giữ ~2 phút → có thể gây `address already in use` khi restart server nhanh → fix bằng `SO_REUSEADDR`
- **Head-of-line blocking**: 1 packet bị delay → toàn bộ stream phải chờ (HTTP/2 bị vấn đề này → HTTP/3 dùng QUIC trên UDP để giải quyết)
- **TCP keepalive**: connection idle lâu có thể bị firewall kill mà không báo → cần cấu hình keepalive

**UDP:**
- **Không tự retry**: app phải tự xử lý mất packet nếu cần
- **Buffer overflow**: gửi quá nhanh → receiver drop packets không báo lỗi
- **UDP flooding**: dễ bị dùng để DDoS vì không cần handshake

**Thực tế hiện đại:**
- **HTTP/3 (QUIC)** → chạy trên UDP nhưng tự implement reliability → best of both worlds
- **WebRTC** → dùng UDP cho media, TCP cho signaling

---

## 🔥 Bài tập

**Level 1 — Nhận biết:**
> Với từng service sau, đoán xem dùng TCP hay UDP: DNS, SSH, Zoom video, PostgreSQL, DHCP, NTP (time sync), Kubernetes health check HTTP.

**Level 2 — Thực hành:**
```bash
# 1. Dùng tcpdump bắt DNS query, xác nhận UDP
tcpdump -i any udp port 53 &
nslookup google.com

# 2. Dùng netcat tạo TCP server ở port 8888
#    rồi connect từ terminal khác và gửi message
nc -l 8888         # terminal 1
nc 127.0.0.1 8888  # terminal 2
```

**Level 3 — Tình huống:**
> Bạn build game mobile realtime. Player gửi vị trí lên server 60 lần/giây. Chọn TCP hay UDP? Nếu mất packet thì xử lý thế nào? Viết pseudocode cho logic đó.

---

> **TL;DR:** TCP = registered mail (chắc chắn đến, biết mất). UDP = thả tờ rơi (nhanh, ai nhặt được thì nhặt). Chọn đúng protocol = app chạy đúng mục đích.
