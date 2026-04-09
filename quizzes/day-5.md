# 📝 Quiz: SSH cơ bản

## Câu 1 (trắc nghiệm)

Bạn thử `ssh ubuntu@10.0.0.5` và nhận lỗi: `WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED!`. Điều gì đã xảy ra?

a) Mật khẩu của user ubuntu đã bị đổi trên server
b) SSH key của bạn đã hết hạn và cần tạo mới
c) SSH key fingerprint của server khác với lần trước — server có thể đã reinstall OS, hoặc đây là MITM attack
d) Bạn cần update phiên bản SSH client

**Đáp án: c)**

**Giải thích:**
- Lần đầu SSH đến server, SSH client lưu fingerprint (dấu vân tay) của server vào `~/.ssh/known_hosts`. Lần sau nếu fingerprint khác → cảnh báo.
- Nguyên nhân phổ biến: server reinstall OS (tạo SSH key mới), hoặc thực sự đang bị tấn công MITM (ai đó chen vào giữa).
- Cách xử lý: xác nhận với admin server rằng server đã reinstall, rồi xóa entry cũ: `ssh-keygen -R 10.0.0.5`
- a) Sai — đổi mật khẩu không ảnh hưởng SSH host key.
- b) Sai — SSH key không có ngày hết hạn.
- d) Sai — không liên quan đến phiên bản client.

---

## Câu 2 (trắc nghiệm)

Sau khi chạy `ssh-copy-id ubuntu@server`, bạn vẫn bị hỏi mật khẩu khi SSH. Nguyên nhân nào sau đây KHÔNG phải là nguyên nhân có thể?

a) File `~/.ssh/authorized_keys` trên server có permission sai (ví dụ: 777)
b) Private key trên máy bạn có permission 644 thay vì 600
c) Server chưa cài OpenSSH
d) `PubkeyAuthentication no` trong `/etc/ssh/sshd_config` của server

**Đáp án: c) Server chưa cài OpenSSH**

**Giải thích:**
- Nếu server chưa cài OpenSSH thì bạn không thể SSH vào từ đầu, kể cả bằng mật khẩu. Vậy đây không phải lý do "vẫn bị hỏi mật khẩu sau ssh-copy-id".
- a) Có thể xảy ra — SSH daemon từ chối đọc `authorized_keys` nếu permission quá rộng (phải là 600 hoặc 644).
- b) Có thể xảy ra — SSH client từ chối dùng private key nếu permission quá rộng (phải là 600).
- d) Có thể xảy ra — nếu PubkeyAuthentication tắt thì key-based login không hoạt động.

---

## Câu 3 (tự luận)

Giải thích tại sao SSH key authentication an toàn hơn password authentication. Cơ chế nào giúp private key không bao giờ phải truyền qua mạng?

**Đáp án gợi ý:**

Password: khi login, bạn gửi mật khẩu lên server để server kiểm tra. Dù SSH mã hóa kết nối, mật khẩu vẫn đến tay server. Nếu server bị compromise → mật khẩu bị lộ. Hacker có thể brute force thử hàng nghìn mật khẩu tự động.

SSH key: Private key **không bao giờ rời khỏi máy bạn**. Cơ chế hoạt động:
1. Server tạo một "challenge" ngẫu nhiên, mã hóa bằng public key của bạn
2. Chỉ private key mới giải mã được challenge đó
3. Bạn ký kết quả bằng private key, gửi lại
4. Server verify chữ ký bằng public key → xác nhận bạn có private key

Kể cả nếu ai nghe được toàn bộ traffic → họ chỉ thấy challenge và chữ ký, không có private key. Không thể brute force vì cần giải bài toán toán học cực khó không có private key.
