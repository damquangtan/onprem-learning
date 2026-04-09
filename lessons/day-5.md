# 🧠 Chủ đề: SSH cơ bản

## 📖 Giải thích

Hãy tưởng tượng bạn cần vào phòng server ở một tòa nhà khác để gõ lệnh. Trước đây, người ta phải dùng **Telnet** — như nói chuyện qua loa phóng thanh giữa hai tòa nhà, ai cũng nghe được. **SSH** giống như đường hầm bí mật có khóa — chỉ bạn và server đó biết, toàn bộ giao tiếp được mã hóa.

**SSH (Secure Shell)** là giao thức cho phép bạn:
- Đăng nhập và điều khiển server từ xa qua terminal
- Truyền file bảo mật (SCP, SFTP)
- Tạo tunnel mã hóa (Port Forwarding — sẽ học ở Day 6)

Mặc định chạy ở **port 22**.

### Hai cách xác thực SSH

**Cách 1 — Password:** Gõ mật khẩu mỗi lần kết nối. Đơn giản nhưng kém an toàn (có thể bị brute force).

**Cách 2 — SSH Key (khuyên dùng):**
- Bạn tạo một cặp key: **private key** (giữ bí mật trên máy bạn) và **public key** (đặt lên server)
- Khi kết nối, server thách đố bạn bằng bài toán chỉ private key mới giải được
- Không cần gõ mật khẩu, an toàn hơn nhiều

```
Máy bạn                         Server
  │                                 │
  │  Có private key                 │  Có public key của bạn
  │                                 │
  │  "Cho tôi vào với tên user1"    │
  │  ────────────────────────────>  │
  │                                 │  [Server tạo challenge bằng public key]
  │  <──── Challenge ───────────    │
  │                                 │
  │  [Giải bằng private key]        │
  │  ──── Response ──────────────>  │
  │                                 │  [Verify → đúng → cho vào]
  │  <──── Shell ───────────────    │
```

## 🧠 Tại sao cần biết điều này?

SSH là công cụ hàng ngày của mọi developer/engineer làm việc với server:
- Deploy code lên server
- Xem log, restart service khi có incident
- Debug vấn đề trực tiếp trên production
- Kết nối DB, Redis... qua SSH tunnel

Không biết SSH = không làm được việc với server thực tế.

## 🧪 Ví dụ thực tế

**Tình huống 1:** Cần xem log app đang chạy trên production server:
```bash
ssh ubuntu@10.0.0.5
# Vào được server rồi
tail -f /var/log/myapp/app.log
```

**Tình huống 2:** Copy file config từ local lên server:
```bash
scp ./config.yaml ubuntu@10.0.0.5:/etc/myapp/config.yaml
```

**Tình huống 3:** Chạy lệnh một lần mà không cần vào shell:
```bash
ssh ubuntu@10.0.0.5 "systemctl status myapp"
# Chạy lệnh xong là thoát luôn, không mở interactive shell
```

## 💻 Command (giải thích từng dòng)

```bash
# Kết nối cơ bản
ssh username@hostname_or_ip
# Ví dụ: ssh ubuntu@10.0.0.5

# Chỉ định port khác (mặc định 22)
ssh -p 2222 ubuntu@10.0.0.5
# -p : port

# Chỉ định key file cụ thể
ssh -i ~/.ssh/my_key.pem ubuntu@10.0.0.5
# -i : identity file (private key)

# Chạy lệnh từ xa mà không cần vào shell
ssh ubuntu@10.0.0.5 "df -h && free -m"

# Tạo SSH key pair
ssh-keygen -t ed25519 -C "myemail@example.com"
# -t ed25519 : loại key (ed25519 mạnh và nhanh hơn RSA)
# -C : comment để nhận diện key
# Tạo ra 2 file: ~/.ssh/id_ed25519 (private) và ~/.ssh/id_ed25519.pub (public)

# Copy public key lên server (để login không cần password)
ssh-copy-id -i ~/.ssh/id_ed25519.pub ubuntu@10.0.0.5
# Lệnh này tự thêm public key vào ~/.ssh/authorized_keys trên server

# SCP — copy file từ local lên server
scp localfile.txt ubuntu@10.0.0.5:/remote/path/
# SCP — copy file từ server về local
scp ubuntu@10.0.0.5:/remote/file.txt ./local/

# SCP thư mục (recursive)
scp -r ./local-dir ubuntu@10.0.0.5:/remote/path/
```

**Cấu hình `~/.ssh/config` — tránh gõ lại thông tin mỗi lần:**
```
Host prod-server
  HostName 10.0.0.5
  User ubuntu
  IdentityFile ~/.ssh/prod_key.pem
  Port 22

Host staging
  HostName 10.0.0.10
  User ec2-user
  IdentityFile ~/.ssh/staging_key.pem
```

Sau đó chỉ cần: `ssh prod-server` thay vì `ssh -i ~/.ssh/prod_key.pem ubuntu@10.0.0.5`

**Debug kết nối SSH:**
```bash
ssh -v ubuntu@10.0.0.5
# -v : verbose — hiện từng bước handshake, giúp debug tại sao không kết nối được
# -vv hoặc -vvv : càng nhiều v càng chi tiết
```

## ⚠️ Lưu ý

1. **Quyền file private key**: Private key phải có permission `600` (chỉ owner đọc được). Nếu permission quá rộng, SSH từ chối dùng:
   ```bash
   chmod 600 ~/.ssh/id_ed25519
   ```

2. **`~/.ssh/authorized_keys` trên server**: File này chứa public key của những ai được phép đăng nhập. Permission phải là `600` hoặc `644`. Nếu sai permission → SSH không đọc → không login được dù key đúng.

3. **Disable password auth**: Sau khi setup SSH key, nên tắt password authentication trong `/etc/ssh/sshd_config`:
   ```
   PasswordAuthentication no
   ```
   → Chỉ key-based login, tránh brute force.

4. **`known_hosts`**: Lần đầu SSH đến server mới, được hỏi "The authenticity of host... can't be established. Continue?" → Yes để thêm vào `~/.ssh/known_hosts`. Lần sau không hỏi nữa. Nếu server thay đổi key (reinstall OS) → báo lỗi MITM warning → xóa entry cũ khỏi `known_hosts`.

## 🔥 Bài tập

1. Tạo SSH key pair bằng `ssh-keygen -t ed25519`. Xem nội dung public key: `cat ~/.ssh/id_ed25519.pub`. Public key trông như thế nào?

2. Tạo file `~/.ssh/config` với ít nhất 1 Host entry cho server bạn hay dùng. Test bằng cách kết nối qua alias.

3. **Tình huống**: Bạn vừa tạo key pair mới và copy public key lên server bằng `ssh-copy-id`. Nhưng `ssh ubuntu@server` vẫn hỏi password. Kiểm tra những gì?

4. **Bảo mật**: Tại sao không nên dùng password authentication cho SSH server ở môi trường production? Nêu ít nhất 2 lý do.
