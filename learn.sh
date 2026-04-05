#!/bin/bash

# Add claude CLI to PATH
export PATH="$PATH:/c/Users/damqu/.vscode/extensions/anthropic.claude-code-2.1.92-win32-x64/resources/native-binary"

STATE_FILE="state.json"

DAY=$(grep -o '[0-9]*' $STATE_FILE)

echo "📅 Ngày học: $DAY"
echo "----------------------------------"

# ROADMAP 30 NGÀY - NETWORKING & LINUX
TOPICS=(
"ping và ICMP"
"TCP vs UDP"
"DNS hoạt động như thế nào"
"HTTP vs HTTPS"
"SSH cơ bản"
"SSH Tunnel"
"NAT là gì"
"Port và socket"
"netstat và ss"
"traceroute"
"curl debug API"
"top / htop"
"process và PID"
"systemctl"
"firewall cơ bản"
"iptables"
"Load Balancer"
"Reverse Proxy"
"LAN vs WAN"
"VPN"
"Database connection"
"Kafka cơ bản"
"Retry và timeout"
"Health check"
"Log và monitoring"
"Disk và IO"
"CPU và memory"
"Thread vs process"
"Debug production"
"Tổng hợp hệ thống"
)

# ROADMAP BARE METAL
TOPICS_BARE_METAL=(
"Bare metal là gì và so sánh với VM"
"BIOS và UEFI"
"RAID: các loại và cách chọn"
"Network bonding và teaming"
"IPMI và quản lý server từ xa"
"Cài OS từ PXE boot"
"Disk partitioning và LVM"
"Filesystem: ext4 vs xfs vs btrfs"
"NFS và mount network storage"
"iSCSI và SAN cơ bản"
"Kernel tuning và sysctl"
"Hardware troubleshooting"
"Firmware update và driver"
"Power management và NUMA"
"Monitoring phần cứng: ipmitool, smartctl"
)

# ROADMAP KUBERNETES
TOPICS_K8S=(
"Kubernetes architecture: control plane và worker node"
"Pod là gì và vòng đời pod"
"Deployment và ReplicaSet"
"Service: ClusterIP, NodePort, LoadBalancer"
"ConfigMap và Secret"
"Persistent Volume và Persistent Volume Claim"
"Namespace và RBAC"
"Ingress và Ingress Controller"
"DaemonSet và StatefulSet"
"Resource requests và limits"
"Liveness và Readiness probe"
"HorizontalPodAutoscaler"
"kubectl debug và troubleshoot"
"Helm cơ bản"
"Network Policy"
"etcd và backup cluster"
"Kubernetes storage: StorageClass"
"Node affinity và taints/tolerations"
"CI/CD với Kubernetes"
"Debug pod crash và OOMKilled"
)

if [ "$DAY" -le 30 ]; then
  SECTION="Networking & Linux"
  TOPIC=${TOPICS[$((DAY-1))]}
elif [ "$DAY" -le 45 ]; then
  SECTION="Bare Metal"
  TOPIC=${TOPICS_BARE_METAL[$((DAY-31))]}
else
  SECTION="Kubernetes"
  TOPIC=${TOPICS_K8S[$((DAY-46))]}
fi

echo "📚 Section: $SECTION"
echo "🧠 Chủ đề hôm nay: $TOPIC"
echo ""

LESSON_FILE="lessons/day-$DAY.md"
QUIZ_FILE="quizzes/day-$DAY.md"
INCIDENT_FILE="incidents/day-$DAY.md"

# 🎓 LESSON
if [ -f "$LESSON_FILE" ]; then
  echo "⏭️  $LESSON_FILE đã tồn tại, bỏ qua."
else
  claude -p "
Bạn là Senior System Engineer.

Dạy chủ đề: $TOPIC

Yêu cầu:
- Tiếng Việt
- Ngắn gọn (5-10 phút đọc)
- Có ví dụ thực tế dev dễ hiểu

Format:
# 🧠 Chủ đề: $TOPIC

## 📖 Giải thích
## 🧪 Ví dụ thực tế
## 💻 Command
## ⚠️ Lưu ý
## 🔥 Bài tập
" > $LESSON_FILE
  echo "✅ $LESSON_FILE"
fi

# 📝 QUIZ
if [ -f "$QUIZ_FILE" ]; then
  echo "⏭️  $QUIZ_FILE đã tồn tại, bỏ qua."
else
  claude -p "
Tạo 3 câu hỏi quiz về: $TOPIC

- 2 trắc nghiệm
- 1 tự luận ngắn

Có đáp án

Tiếng Việt
" > $QUIZ_FILE
  echo "✅ $QUIZ_FILE"
fi

# 🚨 INCIDENT
if [ -f "$INCIDENT_FILE" ]; then
  echo "⏭️  $INCIDENT_FILE đã tồn tại, bỏ qua."
else
  claude -p "
Tạo 1 tình huống sự cố production liên quan: $TOPIC

Format:
# 🚨 Incident

## Mô tả
## Triệu chứng
## Nguyên nhân
## Cách debug
## Cách fix
" > $INCIDENT_FILE
  echo "✅ $INCIDENT_FILE"
fi

# 👉 Tăng ngày
NEXT_DAY=$((DAY+1))
echo "{ \"day\": $NEXT_DAY }" > $STATE_FILE