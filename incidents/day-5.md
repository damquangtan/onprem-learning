Đây là nội dung incident — bạn có thể tự lưu hoặc cho phép tôi ghi:

---

# 🚨 Incident: SSH Permission Denied — Deploy Pipeline Sập Hoàn Toàn

## Mô tả

CI/CD pipeline bị sập lúc 09:15 sau khi team DevOps rotate SSH key trên toàn bộ production servers. Tất cả automated deployment từ GitLab CI đều fail với lỗi `Permission denied (publickey)`. Không có release nào có thể deploy được. Hotfix đang chờ không thể lên production.

---

## Triệu chứng

- GitLab CI job log hiển thị:
  ```
  ssh: connect to host 10.10.1.50 port 22
  Permission denied (publickey).
  fatal: Could not read from remote repository.
  ```
- Dev SSH thủ công vào server bằng key cá nhân vẫn OK → chỉ CI bị ảnh hưởng
- Tất cả môi trường (staging, prod) đều fail cùng lúc
- `git pull` và `ansible-playbook` từ pipeline đều bị chặn
- Monitoring vẫn xanh — server đang chạy bình thường, chỉ deploy không được

---

## Nguyên nhân

Team DevOps rotate SSH key theo security policy định kỳ hàng quý. Họ đã:

1. Generate key pair mới cho CI/CD service account (`deploy_user`)
2. Cập nhật `~/.ssh/authorized_keys` trên tất cả server với **public key mới**
3. **Quên cập nhật private key tương ứng vào GitLab CI/CD Variables**

GitLab CI vẫn đang dùng private key cũ (`$SSH_PRIVATE_KEY`) không còn match với public key trên server nữa.

```
Server authorized_keys:  ssh-rsa AAAA...NEW_KEY deploy_user   ← key mới
GitLab CI variable:      ssh-rsa AAAA...OLD_KEY               ← key cũ ← MISMATCH
```

---

## Cách debug

**Bước 1** — Đọc log CI, xác nhận `Permission denied (publickey)` — auth fail, không phải network/firewall.

**Bước 2** — SSH thủ công từ local để xác nhận server còn sống:
```bash
ssh deploy_user@10.10.1.50
```

**Bước 3** — Vào GitLab → Settings → CI/CD → Variables → xem `$SSH_PRIVATE_KEY` được set lúc nào.

**Bước 4** — Kiểm tra `authorized_keys` trên server, so sánh fingerprint:
```bash
cat ~/.ssh/authorized_keys
echo "$SSH_PRIVATE_KEY" | ssh-keygen -l -f -
```

**Bước 5** — SSH verbose để thấy key nào đang được thử:
```bash
ssh -vvv deploy_user@10.10.1.50 2>&1 | grep "Offering\|Authentications"
```

---

## Cách fix

**Hotfix ngay (5 phút):** Cập nhật private key mới vào GitLab CI/CD Variable `$SSH_PRIVATE_KEY`, trigger pipeline manual để test.

**Fix dài hạn:**

1. Thêm smoke test SSH vào đầu pipeline:
```yaml
test_ssh_connection:
  stage: pre-deploy
  script:
    - eval $(ssh-agent -s)
    - echo "$SSH_PRIVATE_KEY" | ssh-add -
    - ssh -o StrictHostKeyChecking=no deploy_user@$DEPLOY_HOST "echo SSH OK"
```

2. Cập nhật runbook rotate key — bắt buộc có bước kiểm tra CI/CD secrets sau khi rotate.

3. Xét dùng SSH certificate với TTL ngắn thay vì static key pair để giảm rủi ro mỗi lần rotate.

---

> **Lesson learned:** "Dev SSH được bình thường" ≠ CI/CD cũng OK. Chúng dùng credential khác nhau. Rotate credential phải đi kèm test ngay sau đó.
