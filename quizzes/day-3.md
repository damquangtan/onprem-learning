## Quiz: DNS Hoạt Động Như Thế Nào

---

### Câu 1 — Trắc nghiệm

**Khi bạn gõ `google.com` vào trình duyệt, thứ tự tra cứu DNS nào là đúng?**

A. Root DNS → TLD DNS → Authoritative DNS → Recursive Resolver  
B. Recursive Resolver → Cache → Root DNS → TLD DNS → Authoritative DNS  
C. Authoritative DNS → TLD DNS → Root DNS → Recursive Resolver  
D. Cache → Authoritative DNS → Root DNS → TLD DNS  

**Đáp án: B**

> Trình duyệt hỏi Recursive Resolver (thường do ISP cung cấp). Resolver kiểm tra cache trước; nếu không có thì hỏi Root DNS → TLD DNS (`.com`) → Authoritative DNS của `google.com` để lấy địa chỉ IP.

---

### Câu 2 — Trắc nghiệm

**Record DNS nào dùng để ánh xạ tên miền sang địa chỉ IPv4?**

A. AAAA  
B. CNAME  
C. A  
D. MX  

**Đáp án: C**

> `A record` ánh xạ domain → IPv4. `AAAA record` ánh xạ domain → IPv6. `CNAME` là alias trỏ tên miền này sang tên miền khác. `MX` dùng cho mail server.

---

### Câu 3 — Tự luận ngắn

**TTL (Time To Live) trong DNS là gì? Nếu TTL của một record được đặt quá thấp, điều gì sẽ xảy ra?**

**Đáp án:**

TTL là khoảng thời gian (tính bằng giây) mà một DNS record được phép lưu trong cache trước khi bị xóa và phải tra cứu lại. Ví dụ `TTL = 300` nghĩa là cache tồn tại trong 5 phút.

Nếu TTL quá thấp:
- Cache bị xóa liên tục → mỗi request đều phải tra cứu lại từ đầu
- Tăng số lượng query đến DNS server → tốn băng thông và làm chậm phản hồi
- Phù hợp khi cần thay đổi IP nhanh (ví dụ failover), nhưng không nên dùng thường xuyên
