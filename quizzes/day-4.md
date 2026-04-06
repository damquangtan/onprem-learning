## Quiz: HTTP vs HTTPS

---

### Câu 1 (Trắc nghiệm)

**HTTP sử dụng port mặc định nào?**

A) 443  
B) 80  
C) 8080  
D) 22  

**Đáp án: B) 80**

---

### Câu 2 (Trắc nghiệm)

**HTTPS bảo mật dữ liệu bằng cách nào?**

A) Nén dữ liệu trước khi gửi  
B) Mã hóa dữ liệu bằng TLS/SSL  
C) Xác thực địa chỉ IP của client  
D) Giới hạn số lượng kết nối đồng thời  

**Đáp án: B) Mã hóa dữ liệu bằng TLS/SSL**

---

### Câu 3 (Tự luận ngắn)

**Tại sao các website ngân hàng và thương mại điện tử bắt buộc phải dùng HTTPS thay vì HTTP?**

**Đáp án gợi ý:**

HTTP truyền dữ liệu dưới dạng plaintext (văn bản thô), không được mã hóa — kẻ tấn công có thể thực hiện **man-in-the-middle attack** để đọc hoặc chỉnh sửa dữ liệu đang truyền (ví dụ: username, password, số thẻ tín dụng).

HTTPS sử dụng TLS/SSL để **mã hóa toàn bộ dữ liệu** giữa client và server, đồng thời **xác thực danh tính server** qua certificate — đảm bảo người dùng đang kết nối đúng server thật, không phải server giả mạo.
