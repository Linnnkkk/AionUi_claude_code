#!/bin/bash
set -e

# ============================================
# VNC Server 启动脚本
# 功能: 启动 Xvfb + x11vnc + noVNC
# 版本: 1.0
# ============================================

# === 环境变量（支持覆盖）===
DISPLAY="${DISPLAY:-:99}"
VNC_PORT="${VNC_PORT:-5900}"
NOVNC_PORT="${NOVNC_PORT:-6080}"
GEOMETRY="${VNC_GEOMETRY:-1280x720}"
DEPTH="${VNC_DEPTH:-24}"

echo "=========================================="
echo "Starting VNC Server..."
echo "=========================================="
echo "Display: $DISPLAY"
echo "VNC Port: $VNC_PORT"
echo "noVNC Port: $NOVNC_PORT"
echo "Geometry: $GEOMETRY"
echo "Depth: $DEPTH"
echo "=========================================="

# === 清理僵尸 X11 锁文件 ===
# 当容器异常停止时，锁文件可能残留，导致 Xvfb 无法启动
echo "[VNC] Cleaning stale X11 lock files..."
DISPLAY_NUM=${DISPLAY#:}
rm -f /tmp/.X"$DISPLAY_NUM"-lock
rm -f /tmp/.X11-unix/X"$DISPLAY_NUM"
echo "[VNC] Lock files cleaned"

# === 检查是否已运行 ===
if pgrep -f "Xvfb.*$DISPLAY" > /dev/null; then
    echo "[VNC] Xvfb already running on $DISPLAY"
else
    # === 启动 X 虚拟帧缓冲 (Xvfb) ===
    echo "[VNC] Starting Xvfb on display $DISPLAY..."
    Xvfb "$DISPLAY" -screen 0 "${GEOMETRY}x${DEPTH}" -ac +extension GLX +render -noreset &
    XVFB_PID=$!
    echo "[VNC] Xvfb started (PID: $XVFB_PID)"

    # 等待 Xvfb 启动
    sleep 2
fi

# === 检查 x11vnc 是否已运行 ===
if pgrep -f "x11vnc.*$VNC_PORT" > /dev/null; then
    echo "[VNC] x11vnc already running on port $VNC_PORT"
else
    # === 启动 x11vnc ===
    echo "[VNC] Starting x11vnc on port $VNC_PORT..."
    x11vnc -display "$DISPLAY" -forever -nopw -rfbport "$VNC_PORT" -shared -dontdisconnect &
    X11VNC_PID=$!
    echo "[VNC] x11vnc started (PID: $X11VNC_PID)"

    # 等待 x11vnc 启动
    sleep 2
fi

# === 检查 websockify/noVNC 是否已运行 ===
if pgrep -f "websockify.*$NOVNC_PORT" > /dev/null; then
    echo "[VNC] noVNC already running on port $NOVNC_PORT"
else
    # === 启动 noVNC (通过 websockify 转发) ===
    echo "[VNC] Starting noVNC on port $NOVNC_PORT..."
    websockify --web=/usr/share/novnc "$NOVNC_PORT" localhost:"$VNC_PORT" &
    WEBSOCKIFY_PID=$!
    echo "[VNC] noVNC started (PID: $WEBSOCKIFY_PID)"
fi

echo ""
echo "=========================================="
echo "VNC Server is ready!"
echo "=========================================="
echo "VNC Client: localhost:$VNC_PORT"
echo "Web VNC: http://localhost:$NOVNC_PORT"
echo "=========================================="

# === 保持脚本运行，等待信号 ===
trap 'echo "[VNC] Stopping VNC server..."; kill $XVFB_PID $X11VNC_PID $WEBSOCKIFY_PID 2>/dev/null; exit 0' SIGTERM SIGINT

# === 监控进程 ===
while true; do
    # 检查 Xvfb 是否还在运行
    if ! pgrep -f "Xvfb.*$DISPLAY" > /dev/null; then
        echo "[VNC] ERROR: Xvfb process died, restarting..."
        Xvfb "$DISPLAY" -screen 0 "${GEOMETRY}x${DEPTH}" -ac +extension GLX +render -noreset &
        sleep 2
    fi

    # 检查 x11vnc 是否还在运行
    if ! pgrep -f "x11vnc.*$VNC_PORT" > /dev/null; then
        echo "[VNC] ERROR: x11vnc process died, restarting..."
        x11vnc -display "$DISPLAY" -forever -nopw -rfbport "$VNC_PORT" -shared -dontdisconnect &
        sleep 2
    fi

    # 检查 websockify 是否还在运行
    if ! pgrep -f "websockify.*$NOVNC_PORT" > /dev/null; then
        echo "[VNC] ERROR: websockify process died, restarting..."
        websockify --web=/usr/share/novnc "$NOVNC_PORT" localhost:"$VNC_PORT" &
        sleep 2
    fi

    sleep 5
done
