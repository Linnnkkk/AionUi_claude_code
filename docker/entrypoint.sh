#!/bin/bash
set -e

# ============================================
# 容器启动入口脚本
# 功能: 初始化环境，启动 Supervisor，设置 AionUi 密码
# 版本: 4.0
# ============================================

echo "=========================================="
echo "Starting OpenClaw v4.0"
echo "=========================================="
echo "Code-Server Port: ${CODE_SERVER_PORT:-8000}"
echo "AionUi Port: ${AIONUI_PORT:-25808}"
echo "noVNC Port: ${NOVNC_PORT:-6080}"
echo "Chrome CDP Port: ${CDP_PORT:-9222}"
echo "=========================================="

# === 确保脚本可执行 ===
chmod +x /vnc-entrypoint.sh
chmod +x /chrome-entrypoint.sh
chmod +x /aionui-password-setup.sh

# === 启动 Supervisor（管理所有进程）===
# 后台启动 Supervisor
supervisord -n -c /etc/supervisor/conf.d/supervisord.conf &
SUPERVISOR_PID=$!

# === 如果设置了 AIONUI_PASSWORD，等待 AionUi 启动后设置密码 ===
if [ -n "$AIONUI_PASSWORD" ]; then
    echo ""
    echo "=========================================="
    echo "检测到 AIONUI_PASSWORD，准备设置 AionUi 密码"
    echo "=========================================="

    # 等待 AionUi 数据库创建
    /aionui-password-setup.sh
fi

# === 等待 Supervisor 进程 ===
wait $SUPERVISOR_PID
