# 📝 Quiz: ping và ICMP

## Câu 1 (trắc nghiệm)

ICMP hoạt động ở tầng nào trong mô hình OSI?

a) Tầng 7 - Application
b) Tầng 4 - Transport
c) Tầng 3 - Network
d) Tầng 2 - Data Link

**Đáp án: c) Tầng 3 - Network**

**Giải thích:**
- ICMP nằm ở tầng Network (Layer 3), cùng tầng với IP. Nó dùng IP để truyền đi nhưng không phải giao thức tầng Transport.
- a) Sai — Application layer là nơi HTTP, DNS, SSH... hoạt động. ICMP không phải giao thức ứng dụng.
- b) Sai — Transport layer là nơi TCP và UDP hoạt động. ICMP không có port, không phải Transport.
- d) Sai — Data Link là tầng Ethernet, MAC address. ICMP không liên quan.

---

## Câu 2 (trắc nghiệm)

Bạn chạy `ping db-server` và nhận được kết quả thành công (0% packet loss). Nhưng app báo lỗi "Connection refused" khi kết nối đến DB. Điều gì có thể đã xảy ra?

a) Kết quả ping bị sai, thực ra server đã down
b) DB server đang sống nhưng process PostgreSQL đã chết hoặc port 5432 bị block
c) Mạng bị lỗi nhưng ICMP vẫn hoạt động bình thường
d) Cần chạy ping nhiều lần hơn để kết quả chính xác

**Đáp án: b) DB server đang sống nhưng process PostgreSQL đã chết hoặc port 5432 bị block**

**Giải thích:**
- Ping thành công chứng minh: server đang sống, có kết nối mạng tầng IP. Nhưng ping **không** kiểm tra được port hay process.
- "Connection refused" nghĩa là reach được server nhưng không có gì đang listen ở port 5432 → PostgreSQL chết, hoặc đang listen sai interface, hoặc firewall chặn port đó.
- a) Sai — ping 0% loss nghĩa là server thực sự đang sống và đang reply.
- c) Sai — nếu mạng lỗi thì ping cũng fail.
- d) Sai — không liên quan đến số lần ping.

---

## Câu 3 (tự luận)

Giải thích bằng lời của bạn: TTL trong ping là gì? Tại sao nó tồn tại? Nếu bạn ping một server và thấy TTL=57 trong kết quả, điều đó cho bạn biết điều gì?

**Đáp án gợi ý:**

TTL (Time To Live) là một con số gắn với mỗi packet. Mỗi lần packet đi qua một router (một "hop"), TTL giảm đi 1. Khi TTL = 0, router hủy packet và gửi thông báo lỗi về.

Tại sao cần TTL: để tránh packet đi vòng vòng mãi trong mạng nếu có lỗi routing (routing loop). Không có TTL, packet có thể chạy mãi không dừng.

TTL = 57 có nghĩa: Linux thường dùng TTL gốc = 64. 64 - 57 = 7 → packet đã đi qua 7 router (7 hop) trước khi đến bạn. Nếu server dùng Windows (TTL gốc = 128) thì 128 - 57 = 71 hop.
