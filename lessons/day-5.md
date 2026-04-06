# 🧠 Chủ đề: SSH cơ bản

## 📖 Giải thích

**SSH (Secure Shell)** là giao thức cho phép bạn kết nối và điều khiển máy chủ từ xa một cách bảo mật qua mạng.

**Cách hoạt động:**
- Client gửi yêu cầu kết nối → Server xác thực → Tạo tunnel mã hóa
- Mọi dữ liệu truyền qua đều được mã hóa (không bị sniff)

**Hai cách xác thực phổ biến:**

| Cách | Mô tả | Dùng khi nào |
|------|-------|--------------|
| Password | Nhập mật khẩu | Dev local, tạm thời |
| SSH Key | Cặp public/private key | Production, CI/CD, GitHub |

**SSH Key hoạt động thế nào:**
```
Private Key (giữ ở máy bạn) ←→ Public Key (để ở server)
     ~/.ssh/id_rsa                  ~/.ssh/authorized_keys
```
Khi connect, server thử mã hóa bằng public key → chỉ private key của bạn mới giải mã được → xác thực thành công.

---

## 🧪 Ví dụ thực tế

**Tình huống:** Bạn vừa được cấp một VPS để deploy app Node.js.

1. Tạo SSH key trên máy local
2. Copy public key lên VPS
3. SSH vào VPS, kéo code, chạy app

Không cần nhập password mỗi lần — CI/CD pipeline cũng dùng cách này để tự động deploy.

---

## 💻 Command

**1. Tạo SSH key pair:**
```bash
ssh-keygen -t ed25519 -C "your@email.com"
# Sinh ra: ~/.ssh/id_ed25519 (private) + ~/.ssh/id_ed25519.pub (public)
```

**2. Copy public key lên server:**
```bash
ssh-copy-id user@192.168.1.100
# Hoặc thủ công:
cat ~/.ssh/id_ed25519.pub | ssh user@server "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"
```

**3. Kết nối SSH:**
```bash
ssh user@192.168.1.100          # kết nối cơ bản
ssh -p 2222 user@server.com     # port tùy chỉnh
ssh -i ~/.ssh/my_key user@server # chỉ định key cụ thể
```

**4. Cấu hình SSH Config (tiết kiệm thời gian):**
```bash
# ~/.ssh/config
Host myserver
    HostName 192.168.1.100
    User ubuntu
    IdentityFile ~/.ssh/id_ed25519
    Port 22
```
```bash
ssh myserver  # thay vì gõ dài dòng
```

**5. SSH Tunnel (port forwarding) — rất hay dùng:**
```bash
# Truy cập database trên server về máy local port 5433
ssh -L 5433:localhost:5432 user@server

# Sau đó connect local: psql -h localhost -p 5433
```

**6. Copy file qua SSH:**
```bash
scp file.txt user@server:/home/user/         # upload
scp user@server:/var/log/app.log ./          # download
rsync -avz ./dist/ user@server:/var/www/     # sync folder
```

---

## ⚠️ Lưu ý

- **Không bao giờ** share private key (`id_rsa`, `id_ed25519`) — chỉ share public key (`.pub`)
- Set permission đúng, SSH sẽ từ chối nếu sai:
  ```bash
  chmod 700 ~/.ssh
  chmod 600 ~/.ssh/id_ed25519
  chmod 644 ~/.ssh/id_ed25519.pub
  ```
- Dùng `ed25519` thay vì `rsa` (mới hơn, bảo mật hơn, key ngắn hơn)
- Server production nên **tắt password auth**, chỉ dùng key:
  ```bash
  # /etc/ssh/sshd_config
  PasswordAuthentication no
  ```
- Đổi port mặc định từ `22` sang port khác giảm bot scan (security through obscurity, không phải giải pháp hoàn toàn)

---

## 🔥 Bài tập

**Bài 1 — Basic (10 phút):**
Tạo SSH key mới với tên custom (`dev_key`), xem nội dung public key, thêm vào GitHub SSH keys và test kết nối:
```bash
ssh -T git@github.com
# Expected: Hi <username>! You've successfully authenticated...
```

**Bài 2 — Intermediate (15 phút):**
Cấu hình `~/.ssh/config` với ít nhất 2 host (GitHub + 1 server thật/VM). SSH vào server bằng alias ngắn.

**Bài 3 — Advanced (20 phút):**
Dùng SSH tunnel để forward port database từ server về local, sau đó kết nối bằng DBeaver/TablePlus vào `localhost:port_local` — không mở port database ra ngoài internet.
