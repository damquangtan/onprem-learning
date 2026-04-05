## Quiz: TCP vs UDP

---

### Câu 1 — Trắc nghiệm

**TCP khác UDP ở điểm nào sau đây?**

A. TCP nhanh hơn UDP trong mọi trường hợp
B. TCP đảm bảo dữ liệu đến đúng thứ tự và không bị mất
C. UDP yêu cầu bắt tay 3 bước (3-way handshake) trước khi truyền
D. UDP có cơ chế kiểm soát lỗi mạnh hơn TCP

**Đáp án: B**
> TCP có cơ chế xác nhận (ACK), đánh số thứ tự gói tin và truyền lại nếu mất. UDP thì không — gói tin có thể mất hoặc đến lộn xộn mà không được xử lý.

---

### Câu 2 — Trắc nghiệm

**Ứng dụng nào sau đây phù hợp nhất với UDP?**

A. Giao dịch ngân hàng trực tuyến
B. Tải file qua FTP
C. Gọi video trực tuyến (VoIP/Zoom)
D. Đăng nhập SSH

**Đáp án: C**
> Gọi video ưu tiên tốc độ thời gian thực hơn độ chính xác — mất vài gói tin chỉ gây giật nhẹ, còn trễ cao sẽ làm cuộc gọi không dùng được. UDP phù hợp vì overhead thấp, không cần thiết lập kết nối.

---

### Câu 3 — Tự luận ngắn

**Tại sao DNS thường dùng UDP thay vì TCP? Nêu ít nhất 2 lý do.**

**Đáp án gợi ý:**

1. **Truy vấn nhỏ và nhanh** — Gói tin DNS thường chỉ vài chục byte, một gói UDP là đủ, không cần overhead của việc thiết lập kết nối TCP (3-way handshake).
2. **Hiệu suất cao hơn** — Không cần duy trì trạng thái kết nối, server DNS có thể xử lý hàng triệu truy vấn đồng thời với tài nguyên ít hơn.
3. *(Bonus)* Nếu gói tin bị mất, ứng dụng client tự retry — cơ chế đủ đơn giản để không cần TCP lo.

> **Lưu ý:** DNS vẫn dùng TCP khi dữ liệu phản hồi lớn hơn 512 bytes (ví dụ: zone transfer).
