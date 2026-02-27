#!/bin/bash
set -e

# ============================================
# Chrome CDP Service 启动脚本
# 功能: 启动带 CDP 支持的 Playwright Chrome 浏览器
# 版本: 3.0 - 适配 Playwright 标准路径
# ============================================

# === 环境变量 ===
DISPLAY="${DISPLAY:-:99}"
CHROME_PROFILE_DIR="${CHROME_PROFILE_DIR:-/home/coder/.chrome}"
CDP_PORT="${CDP_PORT:-9222}"
VNC_MODE="${VNC_MODE:-false}"

# Playwright 浏览器路径
PLAYWRIGHT_BROWSERS_PATH="${PLAYWRIGHT_BROWSERS_PATH:-/opt/ms-playwright}"

# 自动检测 Chrome 路径（兼容多种 Playwright 版本）
find_chrome_binary() {
    local base_path="$PLAYWRIGHT_BROWSERS_PATH"

    # 尝试 Playwright 标准路径: chromium-<revision>/chrome-linux/chrome
    for dir in "$base_path"/chromium-*; do
        if [ -d "$dir" ]; then
            # 优先使用 chrome-linux（新版本标准）
            if [ -f "$dir/chrome-linux/chrome" ]; then
                echo "$dir/chrome-linux/chrome"
                return 0
            fi
            # 兼容 chrome-linux64（旧版本路径）
            if [ -f "$dir/chrome-linux64/chrome" ]; then
                echo "$dir/chrome-linux64/chrome"
                return 0
            fi
        fi
    done

    # 如果都找不到，返回错误
    return 1
}

CHROME_BIN="${CHROME_BIN:-$(find_chrome_binary)}"

if [ -z "$CHROME_BIN" ]; then
    echo "[Chrome] ERROR: Chrome binary not found in $PLAYWRIGHT_BROWSERS_PATH"
    echo "[Chrome] Available directories:"
    ls -la "$PLAYWRIGHT_BROWSERS_PATH/" 2>/dev/null || echo "  (none)"
    exit 1
fi

echo "=========================================="
echo "Starting Chrome CDP Service..."
echo "=========================================="
echo "Display: $DISPLAY"
echo "CDP Port: $CDP_PORT"
echo "Profile: $CHROME_PROFILE_DIR"
echo "VNC Mode: $VNC_MODE"
echo "Chrome Binary: $CHROME_BIN"
echo "=========================================="

# === 确保用户数据目录存在 ===
mkdir -p "$CHROME_PROFILE_DIR"

# === 检查 Chrome 是否存在 ===
if [ ! -f "$CHROME_BIN" ]; then
    echo "[Chrome] ERROR: Chrome binary not found at $CHROME_BIN"
    exit 1
fi

# 显示 Chrome 版本
echo "[Chrome] Version: $($CHROME_BIN --version 2>/dev/null || echo 'unknown')"

# === 启动 Chrome (带 CDP) ===
# 如果是 VNC 模式，使用可视化窗口
# 如果是 headless 模式，使用虚拟显示
if [ "$VNC_MODE" = "true" ]; then
    echo "[Chrome] Starting in VNC mode (visible)..."
    "$CHROME_BIN" \
        --user-data-dir="$CHROME_PROFILE_DIR" \
        --remote-debugging-port="$CDP_PORT" \
        --no-first-run \
        --no-default-browser-check \
        --disable-sync \
        --disable-features=Translate \
        --display="$DISPLAY" \
        --no-sandbox \
        --disable-blink-features=AutomationControlled \
        &
else
    echo "[Chrome] Starting in headless mode..."
    "$CHROME_BIN" \
        --user-data-dir="$CHROME_PROFILE_DIR" \
        --remote-debugging-port="$CDP_PORT" \
        --headless=new \
        --no-first-run \
        --no-default-browser-check \
        --disable-sync \
        --disable-features=Translate \
        --no-sandbox \
        --disable-blink-features=AutomationControlled \
        &
fi

CHROME_PID=$!
echo "[Chrome] Started (PID: $CHROME_PID)"

# === 等待 CDP 端口就绪 ===
echo "[Chrome] Waiting for CDP port $CDP_PORT..."
while ! nc -z localhost "$CDP_PORT" 2>/dev/null; do
    sleep 0.5
done
echo "[Chrome] CDP is ready on http://localhost:$CDP_PORT"

echo ""
echo "=========================================="
echo "Chrome CDP Service is ready!"
echo "=========================================="
echo "CDP Endpoint: http://localhost:$CDP_PORT"
echo "Profile: $CHROME_PROFILE_DIR"
echo "=========================================="

# === 保持脚本运行 ===
trap 'echo "[Chrome] Stopping Chrome..."; kill $CHROME_PID 2>/dev/null; exit 0' SIGTERM SIGINT

# === 监控进程 ===
while true; do
    if ! pgrep -f "chrome.*--remote-debugging-port=$CDP_PORT" > /dev/null; then
        echo "[Chrome] ERROR: Chrome process died, restarting..."
        if [ "$VNC_MODE" = "true" ]; then
            "$CHROME_BIN" \
                --user-data-dir="$CHROME_PROFILE_DIR" \
                --remote-debugging-port="$CDP_PORT" \
                --no-first-run \
                --no-default-browser-check \
                --disable-sync \
                --disable-features=Translate \
                --display="$DISPLAY" \
                --no-sandbox \
                --disable-blink-features=AutomationControlled \
                &
        else
            "$CHROME_BIN" \
                --user-data-dir="$CHROME_PROFILE_DIR" \
                --remote-debugging-port="$CDP_PORT" \
                --headless=new \
                --no-first-run \
                --no-default-browser-check \
                --disable-sync \
                --disable-features=Translate \
                --no-sandbox \
                --disable-blink-features=AutomationControlled \
                &
        fi
        CHROME_PID=$!
        sleep 2
    fi
    sleep 5
done
