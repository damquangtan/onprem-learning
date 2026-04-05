#!/bin/bash

# Add claude CLI to PATH
export PATH="$PATH:/c/Users/damqu/.vscode/extensions/anthropic.claude-code-2.1.92-win32-x64/resources/native-binary"

STATE_FILE="state.json"

DAY=$(grep -o '[0-9]*' $STATE_FILE)

echo "📅 Ngày học: $DAY"
echo "----------------------------------"

# ROADMAP 30 NGÀY
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

TOPIC=${TOPICS[$((DAY-1))]}

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