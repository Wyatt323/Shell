#!/bin/bash

cat > /etc/sysctl.conf << 'EOF'
# ================================
# 系统文件句柄限制
# ================================
fs.file-max = 6815744
fs.nr_open = 6815744

# ================================
# 网络队列优化
# ================================
net.core.somaxconn = 65535
net.core.netdev_max_backlog = 65536
net.ipv4.tcp_max_syn_backlog = 8192

# ================================
# BBR 拥塞控制
# ================================
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr
net.ipv4.tcp_fastopen = 3

# ================================
# 端口范围
# ================================
net.ipv4.ip_local_port_range = 1024 65535

# ================================
# TCP 缓冲区优化
# ================================
net.ipv4.tcp_window_scaling = 1
net.ipv4.tcp_moderate_rcvbuf = 1

net.core.rmem_max = 16777216
net.core.wmem_max = 16777216

net.ipv4.tcp_rmem = 4096 87380 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216

net.ipv4.udp_rmem_min = 8192
net.ipv4.udp_wmem_min = 8192

# ================================
# TCP 连接优化
# ================================
net.ipv4.tcp_fin_timeout = 30
net.ipv4.tcp_slow_start_after_idle = 0
net.ipv4.tcp_mtu_probing = 1

net.ipv4.tcp_sack = 1
net.ipv4.tcp_no_metrics_save = 1

# ================================
# IP 转发
# ================================
net.ipv4.ip_forward = 1

# ================================
# IPv6 开启
# ================================
net.ipv6.conf.all.disable_ipv6 = 0
net.ipv6.conf.default.disable_ipv6 = 0
net.ipv6.conf.lo.disable_ipv6 = 0

EOF

echo "正在应用 sysctl 配置..."
sysctl --system

echo
echo "========================================"
echo "当前 BBR 状态"
echo "========================================"

echo -n "当前拥塞控制算法: "
sysctl -n net.ipv4.tcp_congestion_control

echo
echo "已加载的 BBR 模块:"
lsmod | grep bbr

echo
echo "========================================"
echo "优化完成"
echo "========================================"
