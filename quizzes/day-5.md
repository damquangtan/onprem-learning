Dưới đây là 3 câu quiz về SSH cơ bản:

---

## Câu 1 (trắc nghiệm)

Lệnh nào dùng để kết nối SSH vào server `192.168.1.10` với user `admin` qua port `2222`?

a) `ssh admin@192.168.1.10 -p 2222`
b) `ssh -port 2222 admin@192.168.1.10`
c) `ssh admin:2222@192.168.1.10`
d) `ssh 192.168.1.10 -u admin -p 2222`

**Đáp án: a) `ssh admin@192.168.1.10 -p 2222`**

---

## Câu 2 (trắc nghiệm)

File nào trên server chứa danh sách public key được phép đăng nhập SSH không cần mật khẩu?

a) `~/.ssh/id_rsa.pub`
b) `~/.ssh/known_hosts`
c) `~/.ssh/authorized_keys`
d) `/etc/ssh/ssh_config`

**Đáp án: c) `~/.ssh/authorized_keys`**

> `id_rsa.pub` là public key của client; `known_hosts` lưu fingerprint server đã kết nối; `ssh_config` là cấu hình phía client. Server đọc `authorized_keys` để xác thực key-based login.

---

## Câu 3 (tự luận)

Bạn tạo cặp key SSH bằng `ssh-keygen` và copy public key lên server, nhưng khi SSH vẫn bị hỏi mật khẩu. Nêu ít nhất 3 nguyên nhân phổ biến và cách kiểm tra/sửa từng nguyên nhân.

**Đáp án gợi ý:**

1. **Quyền file/thư mục sai trên server** — SSH rất khắt khe về permission:
   - `~/.ssh/` phải là `700`: `chmod 700 ~/.ssh`
   - `~/.ssh/authorized_keys` phải là `600`: `chmod 600 ~/.ssh/authorized_keys`

2. **Public key chưa được copy đúng** — Kiểm tra nội dung:
   - `cat ~/.ssh/authorized_keys` trên server, so sánh với `cat ~/.ssh/id_rsa.pub` trên client
   - Dùng `ssh-copy-id user@server` để copy tự động và an toàn

3. **Server chưa bật xác thực bằng key** — Kiểm tra `/etc/ssh/sshd_config`:
   - `PubkeyAuthentication yes` phải được bật
   - Sau khi sửa: `systemctl restart sshd`

---

Bạn có muốn lưu vào file `quizzes/ssh-basics.md` không?
