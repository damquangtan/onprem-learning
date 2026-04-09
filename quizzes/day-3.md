# 📝 Quiz: DNS hoạt động như thế nào

## Câu 1 (trắc nghiệm)

Bạn vừa đổi DNS record của `api.myapp.com` từ IP cũ sang IP mới. Sau 30 phút, một số user vẫn bị điều hướng đến server cũ. Nguyên nhân khả năng nhất là gì?

a) DNS propagation chưa xong do lỗi của nhà cung cấp DNS
b) DNS record cũ có TTL cao (ví dụ: 3600 giây), client đang dùng cache chưa expire
c) User đó đang dùng VPN nên DNS bị chặn
d) Cần xóa DNS record cũ trước khi tạo record mới

**Đáp án: b)**

**Giải thích:**
- TTL (Time To Live) quy định bao lâu DNS resolver được phép cache kết quả. TTL = 3600 → cache 1 giờ. User đã query trước khi bạn đổi → đang dùng cache cũ trỏ về IP cũ.
- a) Sai — DNS propagation thường xảy ra trong vài phút khi bạn save record. Vấn đề là client cache, không phải propagation.
- c) Sai — VPN thay đổi DNS resolver nhưng vẫn bị ảnh hưởng bởi TTL.
- d) Sai — không cần xóa trước. Khi update record, record mới ghi đè record cũ.

**Bài học thực tế:** Trước khi migration, hạ TTL xuống 300 (5 phút) và chờ ít nhất bằng TTL cũ. Sau đó đổi IP → chỉ cần chờ 5 phút là user thấy IP mới.

---

## Câu 2 (trắc nghiệm)

Lệnh nào cho phép bạn query DNS và xem toàn bộ quá trình từ Root Server → TLD → Authoritative DNS?

a) `nslookup -debug google.com`
b) `dig +trace google.com`
c) `dig @8.8.8.8 google.com`
d) `host -v google.com`

**Đáp án: b) `dig +trace google.com`**

**Giải thích:**
- `dig +trace` thực hiện iterative query: query Root Server trước, nhận danh sách TLD server, query TLD, nhận Authoritative server, query Authoritative → hiện từng bước.
- a) Sai — `nslookup -debug` hiện thêm thông tin nhưng không trace từng bước như +trace.
- c) Sai — `dig @8.8.8.8` chỉ query thẳng đến 8.8.8.8 và nhận kết quả cuối, không trace.
- d) Sai — `host -v` hiện verbose output nhưng không trace qua các tầng DNS.

---

## Câu 3 (tự luận)

Giải thích sự khác nhau giữa file `/etc/hosts` và DNS server. Khi nào bạn nên dùng `/etc/hosts`? Có rủi ro gì không?

**Đáp án gợi ý:**

`/etc/hosts` là file text trên máy local, map hostname → IP trực tiếp. OS check file này **trước** khi query DNS. Bạn có thể thêm bất kỳ mapping nào mà không cần DNS server.

DNS server là hệ thống phân tán — chứa records cho toàn internet hoặc internal network, có TTL, có thể update mà không cần vào từng máy.

Dùng `/etc/hosts` khi:
- Test local: map `api.myapp.com` → `127.0.0.1` để test trước khi deploy
- Override DNS: trỏ domain về IP khác để test với production domain
- Môi trường không có DNS server (máy offline, container đặc biệt)

Rủi ro:
- Quên xóa entry test → bug khó hiểu khi deploy (app vẫn trỏ về localhost)
- Không scale được — phải thêm vào từng máy thủ công
- Không có TTL — override vĩnh viễn cho đến khi xóa thủ công
