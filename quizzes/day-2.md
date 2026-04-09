# 📝 Quiz: TCP vs UDP

## Câu 1 (trắc nghiệm)

Tại sao DNS thường dùng UDP thay vì TCP?

a) UDP an toàn hơn TCP cho việc truyền domain name
b) DNS query và response rất nhỏ, UDP nhanh hơn và đủ dùng — client tự retry nếu mất
c) TCP không hỗ trợ truyền domain name
d) UDP đảm bảo thứ tự tốt hơn TCP cho DNS

**Đáp án: b)**

**Giải thích:**
- DNS query thường chỉ vài chục byte. Overhead của TCP (3-way handshake, ACK) cho một packet nhỏ như vậy là không cần thiết.
- UDP gửi ngay, nhanh hơn. Nếu mất → client chờ timeout rồi gửi lại, vẫn nhanh hơn setup TCP connection.
- a) Sai — UDP không an toàn hơn TCP, thực ra UDP không có built-in security nào cả.
- c) Sai — TCP hoàn toàn có thể dùng cho DNS (DNS over TCP), thực tế DNS dùng TCP khi response quá lớn.
- d) Sai — UDP không đảm bảo thứ tự. TCP mới đảm bảo thứ tự.

---

## Câu 2 (trắc nghiệm)

App của bạn connect đến database và nhận lỗi "Connection timed out" thay vì "Connection refused". Điều gì nhiều khả năng đã xảy ra?

a) Process database đã chết và không còn listen ở port đó
b) Database đang quá tải và từ chối kết nối mới
c) Firewall đang drop packet mà không gửi lỗi về, hoặc server không reach được
d) Sai username/password khi kết nối

**Đáp án: c)**

**Giải thích:**
- "Connection timed out": packet gửi đi nhưng không có reply gì cả — như thả đá xuống giếng không nghe tiếng. Thường do firewall drop silently, hoặc route đến server bị đứt.
- "Connection refused": server nhận được packet nhưng không có gì listen ở port đó → gửi RST ngay.
- a) Sai — nếu process chết thì OS sẽ gửi RST ngay lập tức → "Connection refused", không phải timeout.
- b) Sai — quá tải thường trả về lỗi ở tầng ứng dụng, không phải TCP timeout.
- d) Sai — sai password xảy ra sau khi TCP đã kết nối thành công.

---

## Câu 3 (tự luận)

Giải thích bằng lời: TIME_WAIT trong TCP là gì? Tại sao nó tồn tại? Và khi nào bạn gặp vấn đề vì nó?

**Đáp án gợi ý:**

Sau khi đóng một TCP connection, socket không biến mất ngay mà ở trạng thái TIME_WAIT trong khoảng 2 phút (2 × MSL — Maximum Segment Lifetime).

Tại sao cần TIME_WAIT: Đảm bảo mọi packet "lạc đường" của connection cũ đã hết hiệu lực trước khi port đó được dùng lại. Tránh trường hợp packet cũ bị nhầm vào connection mới.

Vấn đề gặp phải: Khi server xử lý nhiều connection ngắn (ví dụ HTTP request nhiều), có thể có hàng nghìn socket ở TIME_WAIT → hết port → không tạo được connection mới → "Cannot assign requested address". Fix: `net.ipv4.tcp_tw_reuse = 1` hoặc cấu hình `SO_REUSEADDR` trong code.
