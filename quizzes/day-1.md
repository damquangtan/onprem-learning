# 📝 Quiz: ping và ICMP

## Câu 1 (trắc nghiệm)

ICMP hoạt động ở tầng nào trong mô hình OSI?

a) Tầng 4 - Transport
b) Tầng 3 - Network
c) Tầng 2 - Data Link
d) Tầng 7 - Application

**Đáp án: b) Tầng 3 - Network**

---

## Câu 2 (trắc nghiệm)

Lệnh nào dừng ping sau 5 lần trên Linux?

a) `ping -n 5 host`
b) `ping -t 5 host`
c) `ping -c 5 host`
d) `ping -l 5 host`

**Đáp án: c) `ping -c 5 host`**

---

## Câu 3 (tự luận)

Ping từ máy dev đến production server thành công (0% loss, 20ms RTT), nhưng `curl http://prod-server:8080/health` vẫn timeout. Hãy nêu 3 nguyên nhân có thể và cách kiểm tra từng nguyên nhân.

**Đáp án gợi ý:**

1. Port 8080 bị firewall block → `telnet prod-server 8080` hoặc `curl -v ...`
2. Process web server chết → SSH vào, chạy `systemctl status myapp` hoặc `ss -tlnp | grep 8080`
3. App bind sai interface (chỉ listen 127.0.0.1) → `ss -tlnp | grep 8080` kiểm tra địa chỉ bind
