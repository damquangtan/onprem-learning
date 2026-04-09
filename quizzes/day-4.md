# 📝 Quiz: HTTP vs HTTPS

## Câu 1 (trắc nghiệm)

API trả về status code `502 Bad Gateway`. Điều này có nghĩa là gì và bạn nên debug ở đâu?

a) Client gửi request sai format — cần sửa phía client
b) Server không tìm thấy endpoint — cần kiểm tra URL
c) Reverse proxy (nginx/load balancer) không kết nối được đến backend service — cần debug backend
d) Client chưa authenticate — cần gửi lại token

**Đáp án: c)**

**Giải thích:**
- `502 Bad Gateway` xảy ra khi một proxy/gateway (nginx, load balancer) nhận request nhưng không nhận được response hợp lệ từ upstream server (backend app).
- Nơi debug: kiểm tra backend service có đang chạy không, nginx log, kết nối giữa nginx và backend.
- a) Sai — request sai format trả về `400 Bad Request`.
- b) Sai — không tìm thấy endpoint trả về `404 Not Found`.
- d) Sai — chưa authenticate trả về `401 Unauthorized`.

---

## Câu 2 (trắc nghiệm)

Tại sao HTTPS cần Certificate từ một CA (Certificate Authority) được tin tưởng, thay vì tự ký (self-signed)?

a) Self-signed certificate không thể mã hóa dữ liệu được
b) CA certificate nhanh hơn và ít tốn tài nguyên hơn
c) CA xác minh bạn thực sự sở hữu domain đó — tránh giả mạo. Self-signed thì ai cũng có thể tạo cho bất kỳ domain nào
d) Self-signed certificate không hỗ trợ HTTP/2

**Đáp án: c)**

**Giải thích:**
- CA đóng vai trò "người chứng nhận" — họ kiểm tra bạn thực sự kiểm soát domain trước khi cấp certificate. Browser tin tưởng CA → tin tưởng certificate của bạn.
- Self-signed: bạn tự ký certificate, không ai xác minh bạn thực sự là chủ domain. Kẻ tấn công có thể tạo self-signed certificate cho `google.com` và lừa đảo.
- a) Sai — self-signed vẫn mã hóa được hoàn toàn, chỉ không được tin tưởng về danh tính.
- b) Sai — không liên quan đến tốc độ hay tài nguyên.
- d) Sai — HTTP/2 không liên quan đến loại certificate.

---

## Câu 3 (tự luận)

Giải thích bằng lời: sự khác nhau giữa `401 Unauthorized` và `403 Forbidden` là gì? Cho ví dụ thực tế cho từng trường hợp.

**Đáp án gợi ý:**

`401 Unauthorized` — "Tôi không biết bạn là ai." Server chưa xác định được danh tính của bạn. Thường kèm header `WWW-Authenticate` gợi ý cách auth.
- Ví dụ: Gọi API không kèm token, hoặc token sai/hết hạn → server không biết đây là ai.

`403 Forbidden` — "Tôi biết bạn là ai, nhưng bạn không có quyền làm điều này." Server đã xác định được danh tính nhưng từ chối vì không đủ permission.
- Ví dụ: User thường đăng nhập thành công (token hợp lệ) nhưng cố gọi API chỉ dành cho admin → 403.

Cách phân biệt khi debug: nếu 401 → kiểm tra auth (token có không, có đúng không, có hết hạn không). Nếu 403 → kiểm tra permission/role của user trong hệ thống.
