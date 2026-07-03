#!/bin/bash

# ==========================================================
# Linux 网络优化脚本（BBR + IPv6 + 高并发）
# Author: Wyatt
# ==========================================================

set -e

# 检查是否为 root
if [ "$(id -u)" -ne 0 ]; then
    echo "❌ 请使用 root 用户运行此脚本！"
    exit 1
fi

echo "========================================="
echo "开始写入 /etc/sysctl.conf ..."
echo "========================================="

cat > /etc/sysctl.conf << 'EOF'
# 1. 基础文件句柄限制 (适配高并发)
fs.file-max                     = 6815744
fs.nr_open                      = 6815744

# 2. 网络队列与连接优化
net.core.somaxconn              = 65535
net.ipv4.tcp_max_syn_backlog    = 8192
net.ipv4.tcp_abort_on_overflow  = 1
net.ipv4.ip_local_port_range    = 1024 65535
net.core.netdev_max_backlog     = 65536

# 3. BBR 与 拥塞控制
net.core.default_qdisc          = fq
net.ipv4.tcp_congestion_control = bbr
net.ipv4.tcp_fastopen           = 3

# 4. TCP 窗口与缓冲区优化 (针对大带宽/长距离链路)
net.ipv4.tcp_window_scaling     = 1
net.ipv4.tcp_adv_win_scale      = 1
net.ipv4.tcp_moderate_rcvbuf    = 1
net.core.rmem_max               = 67108864
net.core.wmem_max               = 67108864
net.ipv4.tcp_rmem               = 4096 87380 67108864
net.ipv4.tcp_wmem               = 4096 65536 67108864
net.ipv4.udp_rmem_min           = 8192
net.ipv4.udp_wmem_min           = 8192

# 5. IPv6 专项开启与调优
net.ipv6.conf.all.disable_ipv6 = 0
net.ipv6.conf.default.disable_ipv6 = 0
net.ipv6.conf.lo.disable_ipv6 = 0
net.ipv6.conf.all.forwarding = 1
net.ipv6.conf.default.forwarding = 1

# 扩大 IPv6 路由缓存和邻居表，防止高并发时丢包
net.ipv6.route.max_size = 1048576
net.ipv6.neigh.default.gc_thresh1 = 1024
net.ipv6.neigh.default.gc_thresh2 = 4096
net.ipv6.neigh.default.gc_thresh3 = 8192

# 6. 时间戳与连接回收
net.ipv4.tcp_timestamps         = 1
net.ipv4.tcp_tw_reuse           = 1
net.ipv4.tcp_fin_timeout        = 30
net.ipv4.tcp_slow_start_after_idle = 0

# 7. 安全与转发配置
net.ipv4.conf.all.rp_filter     = 0
net.ipv4.conf.default.rp_filter = 0
net.ipv4.ip_forward             = 1
net.ipv4.conf.all.route_localnet= 1
net.ipv4.tcp_rfc1337            = 1
net.ipv4.tcp_ecn                = 0

# 8. 其他辅助优化
net.ipv4.tcp_no_metrics_save    = 1
net.ipv4.tcp_sack               = 1
net.ipv4.tcp_fack               = 1
net.ipv4.tcp_mtu_probing        = 1
EOF

echo
echo "========================================="
echo "配置文件写入完成，开始应用..."
echo "========================================="

sysctl -p
sysctl --system

echo
echo "========================================="
echo "✅ Sysctl 优化已完成！"
echo "========================================="

echo
echo "当前 BBR 状态："
sysctl net.ipv4.tcp_congestion_control
sysctl net.core.default_qdisc
