# 🚨 Incident: SSH Tunnel chết âm thầm — app báo DB timeout

## Mô tả

SSH tunnel kết nối app → DB on-prem qua bastion bị drop bởi firewall idle timeout, nhưng SSH process vẫn còn trong `ps aux` → app tưởng tunnel sống → DB query timeout.

## Triệu chứng

- `ps aux | grep ssh` vẫn thấy tunnel process còn sống
- `psql -h localhost -p 15432` báo: `Connection refused`
- App log: DB query timeout sau 8-15s
- Xảy ra sau khoảng 5-10 phút không có traffic

## Nguyên nhân

Firewall giữa client và bastion kill TCP connection idle sau 5 phút. SSH process tồn tại trong OS nhưng kết nối thực sự đã chết. Port không còn được forward — `ss -tlnp` không thấy port đó nữa.

## Cách debug

```bash
# ĐỪNG chỉ nhìn ps aux — nó không nói lên tunnel còn sống hay không
ps aux | grep ssh   # ← misleading

# Kiểm tra port thực sự có listen không
ss -tlnp | grep 15432

# Thử kết nối thực tế
nc -zv localhost 15432

# Hoặc
psql -h localhost -p 15432 -U myuser -c "SELECT 1"
```

## Cách fix

```bash
# Tức thì: kill và restart tunnel
kill $(ps aux | grep 'ssh -.*15432' | grep -v grep | awk '{print $2}')
ssh -fNL 15432:db-internal:5432 user@bastion

# Đúng: thêm keepalive khi tạo tunnel
ssh -fNL 15432:db-internal:5432 \
  -o ServerAliveInterval=60 \
  -o ServerAliveCountMax=3 \
  -o ExitOnForwardFailure=yes \
  user@bastion

# Dài hạn: dùng autossh tự reconnect
autossh -M 0 -fNL 15432:db-internal:5432 \
  -o ServerAliveInterval=60 \
  -o ServerAliveCountMax=3 \
  user@bastion
```

**Bài học:** `ps aux` thấy SSH process ≠ tunnel đang hoạt động. Luôn verify bằng `ss -tlnp` hoặc thử kết nối thực tế.
