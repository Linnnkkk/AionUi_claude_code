#!/bin/bash
# ============================================
# Chrome Manager Utility
# 功能: 管理 Chrome CDP 服务
# 版本: 1.0
# ============================================

CDP_PORT="${CDP_PORT:-9222}"
CHROME_PROFILE_DIR="${CHROME_PROFILE_DIR:-/home/coder/.chrome}"
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

    # 如果都找不到，返回空
    return 1
}

CHROME_BIN="${CHROME_BIN:-$(find_chrome_binary)}"

show_help() {
    cat << HELP
Chrome Manager - 控制 Chrome CDP 服务

用法:
    chrome-manager <command> [options]

命令:
    start-headless    启动无头浏览器（推荐，资源占用低）
    start-vnc         启动带 noVNC 界面的浏览器（可手动操作）
    stop              停止 Chrome 服务
    restart           重启 Chrome 服务
    status            查看 Chrome 服务状态
    url               获取 CDP 连接 URL
    clean             清理 Chrome 用户数据（慎用）
    help              显示此帮助信息

环境变量:
    CDP_PORT          CDP 端口（默认: 9222）
    CHROME_PROFILE_DIR 用户数据目录（默认: /home/coder/.chrome）

示例:
    chrome-manager start-headless    # 启动无头浏览器
    chrome-manager start-vnc         # 启动 VNC 可视化浏览器
    chrome-manager status            # 查看状态
    chrome-manager url               # 获取 CDP URL

HELP
}

start_headless() {
    echo "启动无头 Chrome 浏览器..."
    supervisorctl start chrome-cdp:chrome-cdp-headless
    echo "等待 CDP 端口就绪..."
    while ! nc -z localhost "$CDP_PORT" 2>/dev/null; do
        sleep 0.5
    done
    echo "Chrome 已启动！"
    echo "CDP 端点: http://localhost:$CDP_PORT"
}

start_vnc() {
    echo "启动带 VNC 的 Chrome 浏览器..."
    supervisorctl start vnc-server
    supervisorctl start chrome-cdp:chrome-cdp-vnc
    echo "等待 CDP 端口就绪..."
    while ! nc -z localhost "$CDP_PORT" 2>/dev/null; do
        sleep 0.5
    done
    echo "Chrome 已启动！"
    echo "CDP 端点: http://localhost:$CDP_PORT"
    echo "noVNC 界面: http://localhost:${NOVNC_PORT:-6080}"
}

stop() {
    echo "停止 Chrome 服务..."
    supervisorctl stop chrome-cdp:chrome-cdp-headless 2>/dev/null || true
    supervisorctl stop chrome-cdp:chrome-cdp-vnc 2>/dev/null || true
    echo "Chrome 已停止"
}

restart() {
    stop
    sleep 1
    # 检查当前运行的模式
    if supervisorctl status vnc-server | grep -q RUNNING; then
        start_vnc
    else
        start_headless
    fi
}

status() {
    echo "Chrome 服务状态:"
    echo "=================="
    echo "Chrome Binary: $CHROME_BIN"
    supervisorctl status chrome-cdp:chrome-cdp-headless 2>/dev/null || echo "  headless: NOT CONFIGURED"
    supervisorctl status chrome-cdp:chrome-cdp-vnc 2>/dev/null || echo "  vnc: NOT CONFIGURED"
    echo ""
    echo "CDP 连接测试:"
    if nc -z localhost "$CDP_PORT" 2>/dev/null; then
        echo "  ✓ CDP 端口 $CDP_PORT 可访问"
        echo "  URL: http://localhost:$CDP_PORT"
        echo ""
        echo "  可用版本信息:"
        curl -s http://localhost:$CDP_PORT/json/version 2>/dev/null | jq -r '  \(. // "无法获取")' 2>/dev/null || echo "    无法获取版本信息"
    else
        echo "  ✗ CDP 端口 $CDP_PORT 不可访问"
    fi
}

get_url() {
    if nc -z localhost "$CDP_PORT" 2>/dev/null; then
        echo "http://localhost:$CDP_PORT"
    else
        echo "Chrome CDP 服务未运行" >&2
        exit 1
    fi
}

clean() {
    echo "警告: 此操作将删除所有 Chrome 用户数据（cookies、登录状态等）"
    read -p "确认继续？(y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        stop
        rm -rf "$CHROME_PROFILE_DIR"
        mkdir -p "$CHROME_PROFILE_DIR"
        echo "Chrome 用户数据已清理"
    else
        echo "操作已取消"
    fi
}

# === 主程序 ===
case "${1:-help}" in
    start-headless)
        start_headless
        ;;
    start-vnc)
        start_vnc
        ;;
    stop)
        stop
        ;;
    restart)
        restart
        ;;
    status)
        status
        ;;
    url)
        get_url
        ;;
    clean)
        clean
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        echo "未知命令: $1"
        echo ""
        show_help
        exit 1
        ;;
esac
