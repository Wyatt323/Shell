#!/bin/bash

set -e

echo "===== Swap 自动配置脚本 ====="

# 检查是否已存在 swap
if swapon --show | grep -q "file"; then
    echo "⚠️ 已检测到 Swap 已启用，跳过创建"
    swapon --show
    exit 0
fi

# 获取内存大小（MB）
mem=$(free -m | awk '/Mem:/ {print $2}')

# 自动计算 swap（简单策略）
if [ "$mem" -le 1024 ]; then
    swap_size=2048
elif [ "$mem" -le 2048 ]; then
    swap_size=2048
elif [ "$mem" -le 4096 ]; then
    swap_size=4096
else
    swap_size=4096
fi

echo "📊 内存: ${mem}MB"
echo "🧠 建议 Swap: ${swap_size}MB"

# 创建 swap 文件
echo "📁 创建 swapfile..."
fallocate -l ${swap_size}M /swapfile || dd if=/dev/zero of=/swapfile bs=1M count=$swap_size

chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile

# 写入 fstab
if ! grep -q "/swapfile" /etc/fstab; then
    echo "/swapfile none swap sw 0 0" >> /etc/fstab
fi

# 优化参数
echo "⚙️ 设置 swappiness=10"
sysctl vm.swappiness=10
echo "vm.swappiness=10" >> /etc/sysctl.conf

echo "✅ Swap 配置完成！"
swapon --show
free -h
