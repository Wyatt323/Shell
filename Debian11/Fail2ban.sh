#!/bin/bash
# Fail2ban OneKey Script
# Author: ChatGPT
# OS: Debian / Ubuntu

set -e

echo "==============================="
echo "  Fail2ban 防暴力破解一键脚本"
echo "==============================="

# 必须 root
if [ "$EUID" -ne 0 ]; then
  echo "❌ 请使用 root 用户运行"
  exit 1
fi

# 安装 fail2ban
echo "▶ 安装 fail2ban..."
apt update -y
apt install -y fail2ban

# 获取 SSH 端口
SSH_PORT=$(ss -tnlp | grep sshd | awk '{print $4}' | awk -F: '{print $NF}' | head -n1)
[ -z "$SSH_PORT" ] && SSH_PORT=22

echo "▶ 检测到 SSH 端口: $SSH_PORT"

# 写入 jail.local
cat > /etc/fail2ban/jail.local <<EOF
[DEFAULT]
ignoreip = 127.0.0.1/8
bantime  = 1314000
findtime = 600
maxretry = 2
backend = systemd

[sshd]
enabled = true
port    = $SSH_PORT
logpath = %(sshd_log)s
EOF

# 启动并设置开机自启
systemctl enable fail2ban
systemctl restart fail2ban

# 状态输出
echo "▶ Fail2ban 状态："
fail2ban-client status sshd

echo "==============================="
echo "✅ Fail2ban 已成功部署"
echo "📌 SSH 端口: $SSH_PORT"
echo "📌 封禁次数: 5 次"
echo "📌 封禁时间: 1 年"
echo "==============================="