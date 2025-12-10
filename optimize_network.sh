#!/bin/bash

# ============================================================ #
# 🚀 Network Optimization Script for VLESS/Xray
#      v2.1.1 (2025) © Ivan.Nginx
# ------------------------------------------------------------ #
# 🧾 Description:
#    ★ Tunes TCP buffers & low-latency for high throughput
#    ★ Installs BBR3 via external trusted script
#    ★ Compatible with Debian 12+ / Ubuntu 22.04+
# ------------------------------------------------------------ #
# 🔹 Usage:
#    ➤ ./optimize_network.sh
# ============================================================ #

set -e

echo "============================================"
echo " 🚀 Network optimization started..."
echo "============================================"
echo
# --- Root check --- #
if [[ $EUID -ne 0 ]]; then
  echo "❌ Please run this script as root."
  exit 1
fi

echo " 🔧 Writing buffers..."
echo "--------------------------------------------"
mkdir -p /etc/sysctl.d

cat <<EOF >/etc/sysctl.d/99-network-optimizations.conf
# --- Buffer tuning for high throughput --- #
net.core.rmem_max = 33554432
net.core.wmem_max = 33554432
net.ipv4.tcp_rmem = 4096 87380 33554432
net.ipv4.tcp_wmem = 4096 65536 33554432

# --- Reduce latency --- #
net.ipv4.tcp_low_latency = 1
EOF

# --- Apply changes --- #
sysctl --system >/dev/null

# --- Applying BBR (external installer) --- #
echo
echo " ⚙ Installing BBR3 (external script)..."
echo "--------------------------------------------"

TMP_BBR_SCRIPT="/tmp/install_bbr3.sh"

if wget -q -O "$TMP_BBR_SCRIPT" "https://raw.githubusercontent.com/XDflight/bbr3-debs/refs/heads/build/install_latest.sh"; then
  chmod +x "$TMP_BBR_SCRIPT"
  bash "$TMP_BBR_SCRIPT"
  echo
  echo " 🔍 Final verification:"
  echo "--------------------------------------------"
  cc_value=$(sysctl -n net.ipv4.tcp_congestion_control 2>/dev/null || echo "unknown")
  qdisc_value=$(sysctl -n net.core.default_qdisc 2>/dev/null || echo "unknown")
  tfo_value=$(sysctl -n net.ipv4.tcp_fastopen 2>/dev/null || echo "unknown")
  ecn_value=$(sysctl -n net.ipv4.tcp_ecn 2>/dev/null || echo "unknown")
  krn_version=$(uname -r 2>/dev/null || echo "unknown")

  rmem_max=$(sysctl -n net.core.rmem_max)
  wmem_max=$(sysctl -n net.core.wmem_max)
  tcp_rmem=$(sysctl -n net.ipv4.tcp_rmem)
  tcp_wmem=$(sysctl -n net.ipv4.tcp_wmem)
  low_lat=$(sysctl -n net.ipv4.tcp_low_latency)

  echo " ✅ Congestion control: $cc_value"
  echo " ✅ Queue discipline:   $qdisc_value"
  echo " ✅ TCP Fast Open:      $tfo_value"
  echo " ✅ ECN:                $ecn_value"
  echo " ✅ Kernel version:     $krn_version"
  echo
  echo " 📦 Buffers:"
  echo "     rmem_max:    $rmem_max"
  echo "     wmem_max:    $wmem_max"
  echo "     tcp_rmem:    $tcp_rmem"
  echo "     tcp_wmem:    $tcp_wmem"
  echo "     low_latency: $low_lat"
  echo
  echo "============================================"
  echo " ✨ Done."
  echo "============================================"
  echo
  echo "            🍺 Есть сотка?)"
else
  echo "❌ Failed to download BBR3 installer. Check your network or URL."
  exit 1
fi
