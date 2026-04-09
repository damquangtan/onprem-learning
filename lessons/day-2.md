# 🧠 Chủ đề: TCP vs UDP

## 📖 Giải thích

Hãy tưởng tượng bạn gửi tài liệu quan trọng. Bạn có 2 lựa chọn:

**Lựa chọn 1 — Bưu điện có xác nhận (TCP):** Người giao hàng gõ cửa, chờ ký nhận. Nếu bạn không nhà → họ thử lại. Bạn chắc chắn 100% tài liệu đến nơi, đúng thứ tự.

**Lựa chọn 2 — Thả tờ rơi qua khe cửa (UDP):** Cứ nhét vào, không cần biết bạn có nhà không. Nhanh hơn nhiều, nhưng có thể mất.

Trong mạng máy tính, **TCP** và **UDP** là hai giao thức truyền dữ liệu với triết lý tương tự.

### TCP (Transmission Control Protocol)

TCP thiết lập kết nối qua **3-way handshake** trước khi gửi dữ liệu:

```
Client              Server
  |                    |
  |  --- SYN --->      |   "Tôi muốn kết nối"
  |  <-- SYN-ACK ---   |   "OK, tôi sẵn sàng"
  |  --- ACK --->      |   "Bắt đầu thôi"
  |                    |
  |  (gửi data)        |
  |  <-- ACK -----     |   "Nhận được rồi"
  |  (mất packet)      |
  |  (timeout → gửi lại)|
```

Mỗi packet gửi đi đều được xác nhận (ACK). Mất → tự động gửi lại.

### UDP (User Datagram Protocol)

Không handshake. Cứ gửi thẳng:

```
Client              Server
  |                    |
  | --- Packet 1 --->  |
  | --- Packet 2 --->  |  ← Packet 3 bị mất, không ai báo
  | --- Packet 4 --->  |
```

### So sánh

| Tiêu chí | TCP | UDP |
|----------|-----|-----|
| Kết nối | Bắt buộc (handshake) | Không cần |
| Đảm bảo đến nơi | Có (retry tự động) | Không |
| Đảm bảo thứ tự | Có | Không |
| Tốc độ | Chậm hơn | Nhanh hơn |
| Dùng cho | Độ chính xác | Tốc độ realtime |

## 🧠 Tại sao cần biết điều này?

Khi debug network issues, bạn cần biết service đang dùng TCP hay UDP để chọn đúng công cụ:
- Test TCP port: `telnet`, `nc`, `curl`
- Test UDP: `nc -u`, `dig` (DNS)

Ngoài ra, hiểu TCP giúp bạn debug các lỗi phổ biến như `Too many connections`, `Connection reset`, hay tại sao restart server đôi khi bị lỗi `Address already in use`.

## 🧪 Ví dụ thực tế

**Dùng TCP:**
- **REST API / HTTP** → mất 1 byte trong JSON là parse lỗi hết
- **Database** (MySQL, PostgreSQL) → dữ liệu sai vì thiếu byte là thảm họa
- **SSH** → lệnh phải đến đúng thứ tự
- **File transfer** → file corrupt = vô dụng

**Dùng UDP:**
- **Video call** (Zoom) → mất 1 frame thì giật nhẹ. Nếu phải retry thì video đứng hình = tệ hơn
- **Online game** → vị trí nhân vật cần realtime. Dữ liệu cũ 100ms thà bỏ đi còn hơn gửi lại
- **DNS lookup** → query nhỏ vài chục byte, miss thì client tự retry ngay
- **Live streaming** → có buffer, mất vài frame không ai biết

**Thực tế hiện đại:** HTTP/3 (QUIC) chạy trên UDP nhưng tự implement reliability — lấy tốc độ của UDP kết hợp độ tin cậy tự build.

## 💻 Command (giải thích từng dòng)

```bash
# Xem các port đang LISTEN (chờ kết nối đến)
ss -tlnp
# -t : chỉ hiện TCP
# -l : chỉ hiện listening sockets (đang chờ kết nối)
# -n : hiện số IP thay vì resolve hostname (nhanh hơn)
# -p : hiện process nào đang listen port đó

# Xem tất cả TCP connections hiện tại
netstat -tn
# -t : TCP
# -n : dùng số, không resolve hostname

# Test TCP port có mở không bằng netcat
nc -zv 10.0.0.5 5432
# -z : chỉ test kết nối, không gửi data
# -v : verbose — hiện kết quả rõ ràng (succeeded/failed)

# Test UDP port (ví dụ: DNS ở port 53)
nc -zuv 8.8.8.8 53
# -u : dùng UDP thay vì TCP mặc định

# Bắt packet để quan sát TCP handshake (cần sudo)
sudo tcpdump -i any host google.com and tcp
# Rồi ở terminal khác: curl https://google.com
# Bạn sẽ thấy: Flags [S] = SYN, Flags [S.] = SYN-ACK, Flags [.] = ACK
```

**Đọc output `ss -tlnp`:**
```
State   Recv-Q  Send-Q  Local Address:Port  Peer Address:Port  Process
LISTEN  0       128     0.0.0.0:5432        0.0.0.0:*          users:(("postgres",pid=1234))
│                       │       │
│                       │       └── Port 5432 đang listen
│                       └────────── 0.0.0.0 = listen trên tất cả interfaces
└────────────────────────────────── LISTEN = đang chờ kết nối đến
```

## ⚠️ Lưu ý

1. **TIME_WAIT**: Sau khi đóng TCP connection, socket ở trạng thái `TIME_WAIT` ~2 phút. Lý do restart server nhanh hay bị `Address already in use`. Fix: thêm `SO_REUSEADDR` trong code server.

2. **Connection refused vs timeout**:
   - `Connection refused`: Host đến được nhưng không có gì listen ở port — process chết hoặc port sai
   - `Connection timeout`: Không reach được host, hoặc firewall drop packet không gửi lỗi về

3. **UDP không báo lỗi**: Gửi UDP đến host không tồn tại → không có error. App phải tự implement timeout và retry.

4. **Firewall và UDP**: Nhiều firewall khó filter UDP vì không có state. Dễ bị dùng để DDoS (UDP flood).

## 🔥 Bài tập

1. Chạy `ss -tlnp` trên máy bạn. Liệt kê những service nào đang listen, ở port nào.

2. Thử `nc -zv 8.8.8.8 53` (DNS TCP) và `nc -zuv 8.8.8.8 53` (DNS UDP). Cái nào thành công? Tại sao?

3. **Tình huống**: Service mới deploy ở port 8080. `ss -tlnp | grep 8080` không thấy gì. `curl localhost:8080` báo "Connection refused". Nguyên nhân là gì?

4. **Tư duy**: Nếu build app chat realtime (như Slack), bạn chọn TCP hay UDP để gửi tin nhắn? Tại sao?
