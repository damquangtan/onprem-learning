# 🚨 Incident: Game Server bị lag đột ngột sau khi "optimize" networking

## Mô tả

Một game mobile multiplayer (battle royale) hoạt động bình thường. Dev backend quyết định "tối ưu" bằng cách chuyển game state sync từ **UDP sang TCP** để "đảm bảo dữ liệu không mất". 30 phút sau deploy, toàn bộ player báo lag, giật, delay 2-3 giây.

---

## Triệu chứng

- Player movement delay tăng từ ~50ms lên **2000-3000ms**
- Server CPU bình thường (15%), RAM bình thường
- Bandwidth bình thường
- Log không có error
- Chỉ xảy ra khi **>50 players** cùng phòng
- Mobile 4G bị nặng hơn WiFi

---

## Nguyên nhân

**TCP Head-of-Line Blocking** kết hợp với **congestion control** không phù hợp với game realtime.

```
Game gửi position update 20 lần/giây = mỗi 50ms 1 packet

Scenario với TCP:
  t=0ms   : Gửi packet #1 (position: x=100)
  t=50ms  : Gửi packet #2 (position: x=110)  <-- packet #1 bị drop trên mạng 4G
  t=100ms : Gửi packet #3 (position: x=120)
  
  TCP behavior:
    - Phát hiện packet #1 mất → trigger retransmit
    - Packet #2 và #3 đã tới server nhưng PHẢI CHỜ packet #1
    - TCP Nagle's Algorithm gộp các packet nhỏ lại → thêm delay
    - Retransmit timeout (RTO) mặc định: 200ms - 1000ms
    
  Kết quả: Player nhìn thấy position x=120 nhưng phải đợi 500ms+
           Trong khi với UDP: drop packet #1, nhảy thẳng đến x=120 → mượt
```

**50 players × 20 packets/s = 1000 TCP connections** cùng lúc làm congestion window của server bị thrashing.

---

## Cách debug

**1. Đo RTT thực tế vs perceived latency:**
```bash
# Trên server, capture traffic
tcpdump -i eth0 -w game_traffic.pcap port 7777

# Mở trong Wireshark, filter:
tcp.analysis.retransmission
tcp.analysis.out_of_order

# Thấy ngay: hàng nghìn retransmission trong 1 phút
```

**2. Check TCP socket buffer:**
```bash
ss -tnp | grep 7777
# Thấy Recv-Q tăng cao → buffer đầy, packets đang xếp hàng chờ
```

**3. So sánh timestamp:**
```python
# Log phía client
send_time = time.time()       # t=0ms, gửi packet position
recv_ack_time = time.time()   # t=850ms, server ACK

# Log phía server  
recv_time = time.time()       # t=840ms, nhận được
# → 840ms delay cho 1 position update = unplayable
```

**4. Reproduce có kiểm soát:**
```bash
# Giả lập mạng 4G kém (1% packet loss)
tc qdisc add dev eth0 root netem loss 1%

# TCP với 1% loss → latency tăng ~10x do retransmit
# UDP với 1% loss → mất 1% frame, game vẫn smooth
```

---

## Cách fix

**Fix ngay (rollback):** Chuyển lại UDP cho game state sync.

**Fix đúng (long term):** Dùng đúng protocol cho đúng mục đích:

```
UDP  → position, rotation, animation state (tolerates loss, latency-sensitive)
TCP  → chat, inventory changes, kill events (must not lose, latency-tolerant)
```

```python
# Thiết kế lại: Reliable UDP thay vì TCP
class GameTransport:
    def send_position(self, player_id, x, y, z):
        # UDP: fire and forget, server dùng snapshot mới nhất
        self.udp_socket.sendto(
            pack_position(player_id, x, y, z, seq=self.seq_num),
            self.server_addr
        )
        # KHÔNG cần ACK, KHÔNG cần retransmit
        # Server nhận seq=105 → tự bỏ seq=103,104 nếu chưa tới

    def send_item_pickup(self, item_id):
        # TCP: bắt buộc đảm bảo, chấp nhận delay
        self.tcp_socket.send(pack_item_event(item_id))
```

**Nếu muốn "reliable" mà vẫn dùng UDP → implement application-layer ACK:**
- Chỉ retransmit với **critical events** (damage, death)
- **Không bao giờ** retransmit positional data → dùng cái mới nhất

---

**Bài học:** TCP "đảm bảo không mất data" là con dao hai lưỡi — nó đảm bảo thứ tự và delivery bằng cách **chặn** toàn bộ stream lại để chờ. Với game realtime, data cũ bị delay còn tệ hơn data bị mất.
