#!/bin/bash
# Interactive Fail2ban + Telegram Notify + Daily Report
# Debian / Ubuntu

set -e

echo "====================================="
echo " Fail2ban 防暴力破解（交互式安装）"
echo " 支持 TG 通知 & 每日统计推送"
echo "====================================="

# root 检查
if [ "$EUID" -ne 0 ]; then
  echo "❌ 请使用 root 用户运行"
  exit 1
fi

# ===== 交互输入 =====
read -p "请输入允许失败次数（maxretry，建议 3-5）: " MAXRETRY
read -p "请输入封禁时间（秒，建议 3600 / 86400）: " BANTIME
read -p "是否开启 Telegram 通知？(y/n): " ENABLE_TG

MAXRETRY=${MAXRETRY:-5}
BANTIME=${BANTIME:-86400}

USE_TG=false

if [[ "$ENABLE_TG" =~ ^[Yy]$ ]]; then
  USE_TG=true
  read -p "请输入【主机名称】（用于 TG 通知展示）: " HOST_ALIAS
  read -p "请输入 Telegram Bot Token: " BOT_TOKEN
  read -p "请输入 Telegram Chat ID: " CHAT_ID

  if [[ -z "$HOST_ALIAS" || -z "$BOT_TOKEN" || -z "$CHAT_ID" ]]; then
    echo "❌ 主机名 / Token / Chat ID 不能为空"
    exit 1
  fi
fi

# ===== 安装 =====
echo "▶ 安装 fail2ban..."
apt update -y
apt install -y fail2ban curl cron

# 获取 SSH 端口
SSH_PORT=$(ss -tnlp | grep sshd | awk '{print $4}' | awk -F: '{print $NF}' | head -n1)
[ -z "$SSH_PORT" ] && SSH_PORT=22

# ===== TG 即时通知 =====
if [ "$USE_TG" = true ]; then
  echo "▶ 配置 Telegram 即时通知..."

  cat > /etc/fail2ban/tg_notify.sh <<EOF
#!/bin/bash
ACTION=\$1
IP=\$2
JAIL=\$3
DATE=\$(date "+%Y-%m-%d %H:%M:%S")

HOST_ALIAS="$HOST_ALIAS"
BOT_TOKEN="$BOT_TOKEN"
CHAT_ID="$CHAT_ID"

if [ "\$ACTION" = "ban" ]; then
  TEXT="🚫 *Fail2ban 封禁通知*\\n主机: \$HOST_ALIAS\\n服务: \$JAIL\\nIP: \$IP\\n时间: \$DATE"
else
  TEXT="✅ *Fail2ban 解封通知*\\n主机: \$HOST_ALIAS\\n服务: \$JAIL\\nIP: \$IP\\n时间: \$DATE"
fi

curl -s -X POST "https://api.telegram.org/bot\${BOT_TOKEN}/sendMessage" \
 -d chat_id="\${CHAT_ID}" \
 -d parse_mode=Markdown \
 -d text="\$TEXT" >/dev/null 2>&1
EOF

  chmod +x /etc/fail2ban/tg_notify.sh

  cat > /etc/fail2ban/action.d/tg.conf <<EOF
[Definition]
actionban = /etc/fail2ban/tg_notify.sh ban <ip> <name>
actionunban = /etc/fail2ban/tg_notify.sh unban <ip> <name>
EOF
fi

# ===== Fail2ban 配置 =====
cat > /etc/fail2ban/jail.local <<EOF
[DEFAULT]
ignoreip = 127.0.0.1/8
bantime  = $BANTIME
findtime = 600
maxretry = $MAXRETRY
backend  = systemd
EOF

if [ "$USE_TG" = true ]; then
cat >> /etc/fail2ban/jail.local <<EOF
action = %(action_mwl)s
         tg
EOF
fi

cat >> /etc/fail2ban/jail.local <<EOF

[sshd]
enabled = true
port    = $SSH_PORT
logpath = %(sshd_log)s
EOF

# ===== 每日统计脚本 =====
if [ "$USE_TG" = true ]; then
  echo "▶ 配置每日 23:59 统计推送..."

  cat > /usr/local/bin/fail2ban_daily_report.sh <<EOF
#!/bin/bash

DATE=\$(date "+%Y-%m-%d")
COUNT=\$(grep "\$DATE" /var/log/fail2ban.log | grep "Ban" | awk '{print \$NF}' | sort -u | wc -l)

TEXT="📊 *Fail2ban 每日统计*\\n主机: $HOST_ALIAS\\n日期: \$DATE\\n今日封禁 IP 数量: \$COUNT"

curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" \
 -d chat_id="$CHAT_ID" \
 -d parse_mode=Markdown \
 -d text="\$TEXT" >/dev/null 2>&1
EOF

  chmod +x /usr/local/bin/fail2ban_daily_report.sh

  # 写入 cron（避免重复）
  (crontab -l 2>/dev/null | grep -v fail2ban_daily_report; \
   echo "59 23 * * * /usr/local/bin/fail2ban_daily_report.sh") | crontab -
fi

# ===== 启动 =====
systemctl enable fail2ban
systemctl restart fail2ban

echo "====================================="
echo "✅ 安装完成"
echo "SSH 端口: $SSH_PORT"
echo "最大失败次数: $MAXRETRY"
echo "封禁时间: $BANTIME 秒"
echo "TG 通知: $([ "$USE_TG" = true ] && echo 已开启 || echo 未开启)"
echo "====================================="