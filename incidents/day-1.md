# 🚨 Incident: Ping OK nhưng service chết

## Mô tả

Sau một lần deploy, monitoring báo service health check fail liên tục. On-call check ping thấy host vẫn sống nên nghĩ không có vấn đề network.

## Triệu chứng

- `ping app-server` → thành công, 0% loss
- `curl http://app-server:8080/health` → Connection refused
- Load balancer báo backend unhealthy

## Nguyên nhân

App bị OOM (Out Of Memory) kill sau deploy do memory leak trong version mới. Process không còn chạy nhưng host vẫn sống bình thường — đó là lý do ping vẫn OK.

## Cách debug

```bash
# 1. SSH vào server
ssh app-server

# 2. Kiểm tra process còn chạy không
systemctl status myapp
# hoặc
ps aux | grep myapp

# 3. Kiểm tra có gì đang listen port 8080 không
ss -tlnp | grep 8080

# 4. Xem log gần nhất
journalctl -u myapp -n 50

# 5. Kiểm tra OOM killer
dmesg | grep -i "out of memory"
dmesg | grep -i "killed process"
```

## Cách fix

```bash
# Restart tạm thời
systemctl restart myapp

# Điều tra memory leak
# - Xem memory usage trước khi crash trong metrics/logs
# - Profile app ở môi trường staging
# - Rollback version nếu cần
systemctl rollback myapp
```

**Bài học:** Ping chỉ kiểm tra được tầng network (host còn sống). Luôn phải kiểm tra thêm port và process khi debug service failure.
