# 🚨 Incident: Không SSH được vào server sau khi "tăng bảo mật"

## Mô tả

Junior engineer được giao task "tăng bảo mật SSH cho production server". Sau khi thực hiện một số thay đổi trong `/etc/ssh/sshd_config` và restart SSH service, toàn bộ team bị khóa ra ngoài — không ai SSH được vào server nữa. Server vẫn chạy (website vẫn online) nhưng không có cách nào vào quản lý.

## Triệu chứng

- `ssh ubuntu@prod-server` → "Connection refused"
- `ssh -p 2222 ubuntu@prod-server` → "Connection refused" (sau khi thử nhiều port)
- `ping prod-server` → Thành công (server vẫn sống)
- Website đang chạy trên server vẫn phục vụ user bình thường
- Không có ai trong team còn session SSH nào đang mở

## Nguyên nhân gốc rễ

Engineer thực hiện 2 thay đổi:
1. Đổi SSH port từ 22 sang 2222 trong `sshd_config`
2. Thêm rule firewall chặn tất cả inbound connections ngoài port 80 và 443

Vấn đề: **Firewall rule được thêm trước khi restart SSH với port mới**. Kết quả: SSH ở port 22 bị firewall chặn (đã thêm rule), SSH ở port 2222 cũng bị chặn (port mới chưa được mở trong firewall). Mọi đường vào đều bị block.

## Cách debug từng bước

**Bước 1: Xác nhận server vẫn sống**
```bash
ping prod-server -c 4
# → 0% packet loss → Host sống, vấn đề không phải server down
```

**Bước 2: Test SSH port**
```bash
nc -zv prod-server 22
# → Connection refused  hoặc  timeout

nc -zv prod-server 2222
# → Connection refused  hoặc  timeout

# "Connection refused" = có gì chặn ở đây
# "Timeout" = firewall drop packet không gửi RST về
```

**Bước 3: Scan xem port nào đang mở từ ngoài**
```bash
nmap -p 1-65535 prod-server
# → PORT    STATE  SERVICE
# → 80/tcp  open   http
# → 443/tcp open   https
# → Không thấy port SSH nào → firewall chặn hết port trừ 80 và 443
```

**Bước 4: Tìm phương án vào server không qua SSH**

Đây là lúc cần **out-of-band access** — tức là cách vào server không qua network thông thường:
- Cloud provider (AWS, GCP, Azure): dùng **EC2 Instance Connect**, **Serial Console**, hoặc **VNC** từ web console
- VPS provider: thường có console access từ control panel
- Bare metal: cần physical access hoặc IPMI/iDRAC

```bash
# Ví dụ với AWS EC2
aws ec2-instance-connect send-ssh-public-key \
  --instance-id i-1234567890abcdef0 \
  --availability-zone us-east-1a \
  --instance-os-user ubuntu \
  --ssh-public-key file://~/.ssh/id_ed25519.pub
```

**Bước 5: Sau khi vào được bằng console, sửa firewall**
```bash
# Xem firewall rules hiện tại
sudo iptables -L -n
# hoặc nếu dùng ufw:
sudo ufw status verbose

# Mở port SSH (port mới 2222)
sudo ufw allow 2222/tcp
sudo ufw reload

# Hoặc thêm rule iptables
sudo iptables -I INPUT -p tcp --dport 2222 -j ACCEPT
```

**Bước 6: Verify SSH hoạt động trước khi logout console**
```bash
# Mở terminal khác, test SSH
ssh -p 2222 ubuntu@prod-server
# → Phải vào được trước khi đóng console session
```

## Cách fix

```bash
# 1. Mở port SSH mới trong firewall
sudo ufw allow 2222/tcp

# 2. Verify sshd đang listen đúng port
ss -tlnp | grep sshd
# → LISTEN 0 128 0.0.0.0:2222 ...

# 3. Test từ máy khác trước khi đóng session hiện tại
ssh -p 2222 ubuntu@prod-server  # (từ terminal khác)
# → Vào được ✓

# 4. Sau khi verify OK, có thể xóa rule cho port 22 cũ
sudo ufw delete allow 22/tcp
```

## Bài học

1. **Không bao giờ thay đổi SSH config và đóng session mà không verify trước**. Luôn mở terminal thứ 2, test SSH với config mới trong khi vẫn giữ session cũ.

2. **Thứ tự thay đổi firewall quan trọng**: Mở port mới trước → verify → mới đóng port cũ. Không bao giờ ngược lại.

3. **Biết out-of-band access** của provider bạn đang dùng trước khi cần. Khi bị lock out thì không có thời gian nghiên cứu.

4. **Test từng thay đổi nhỏ**, không thay đổi nhiều thứ cùng lúc. Đổi port SSH một mình trước, verify xong rồi mới động đến firewall.
