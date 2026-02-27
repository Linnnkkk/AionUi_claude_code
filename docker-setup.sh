#!/bin/bash
set -e

# ============================================
# OpenClaw v4.3 部署脚本
# 版本: 4.3
# 支持: 多用户部署、环境变量配置
# 更新: 移除本地 Chrome 依赖，使用在线安装
# ============================================

# === 颜色输出 ===
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# === 默认环境变量 ===
export COMPOSE_PROJECT_NAME="${COMPOSE_PROJECT_NAME:-openclaw}"
export CONTAINER_NAME="${CONTAINER_NAME:-openclaw}"
export AIONUI_NETWORKS="${AIONUI_NETWORKS:-openclaw-network}"

# Code-Server 配置
export CODE_SERVER_HOME="${CODE_SERVER_HOME:-}"
export CODE_SERVER_PORT="${CODE_SERVER_PORT:-8080}"

# === 构建参数 ===
export AIONUI_VERSION="${AIONUI_VERSION:-1.7.8}"

# AionUi 配置 (数据存储在 CODE_SERVER_HOME/.config/AionUi 下)
export AIONUI_PORT="${AIONUI_PORT:-25808}"
export AIONUI_USERNAME="${AIONUI_USERNAME:-admin}"
export AIONUI_PASSWORD="${AIONUI_PASSWORD:-}"

# VNC 配置
export NOVNC_PORT="${NOVNC_PORT:-6080}"
export VNC_GEOMETRY="${VNC_GEOMETRY:-1280x720}"

# Chrome CDP 配置 (数据存储在 CODE_SERVER_HOME/.chrome 下)
export CDP_PORT="${CDP_PORT:-9222}"

# Docker 用户
export DOCKER_USER="${DOCKER_USER:-coder}"

# 时区
export TZ="${TZ:-Asia/Shanghai}"

# 定义镜像名称（优先使用环境变量，否则默认）
export IMAGE_NAME="${IMAGE_NAME:-${COMPOSE_PROJECT_NAME}_code-server-aionui}"

# === 显示配置 ===
echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}OpenClaw v4.3 部署脚本${NC}"
echo -e "${GREEN}============================================${NC}"
echo ""
echo "项目名称: ${COMPOSE_PROJECT_NAME}"
echo "容器名称: ${CONTAINER_NAME}"
echo "网络名称: ${AIONUI_NETWORKS}"
echo "镜像名称: ${IMAGE_NAME}"
echo ""
echo "Code-Server:"
echo "  工作目录: ${CODE_SERVER_HOME:-<未设置>}"
echo "  端口: ${CODE_SERVER_PORT}"
echo ""
echo "构建参数:"
echo "  AionUi 版本: ${AIONUI_VERSION}"
echo ""
echo "AionUi:"
echo "  端口: ${AIONUI_PORT}"
echo "  用户名: ${AIONUI_USERNAME}"
if [ -n "$AIONUI_PASSWORD" ]; then
    echo "  密码: ****** (已设置)"
else
    echo "  密码: (首次登录随机生成)"
fi
echo ""
echo "VNC:"
echo "  noVNC 端口: ${NOVNC_PORT}"
echo "  分辨率: ${VNC_GEOMETRY}"
echo ""
echo "Chrome CDP:"
echo "  CDP 端口: ${CDP_PORT}"
echo "  用户数据目录: \${CODE_SERVER_HOME}/.chrome"
echo ""
echo -e "${GREEN}============================================${NC}"

# === 检查必需的环境变量 ===
if [ -z "$CODE_SERVER_HOME" ]; then
    echo -e "${RED}错误: CODE_SERVER_HOME 必须设置${NC}"
    echo ""
    echo "使用方式:"
    echo "  CODE_SERVER_HOME=/path/to/workspace \\"
    echo "  CODE_SERVER_PASSWORD=your_password \\"
    echo "  ./docker-setup.sh"
    echo ""
    echo "示例:"
    echo "  CODE_SERVER_HOME=/home/docker/codeserver \\"
    echo "  CODE_SERVER_PASSWORD=my_secure_password \\"
    echo "  ./docker-setup.sh"
    exit 1
fi

if [ -z "$CODE_SERVER_PASSWORD" ]; then
    echo -e "${YELLOW}警告: CODE_SERVER_PASSWORD 未设置${NC}"
    echo -n "请输入 Code-Server 密码: "
    read -s CODE_SERVER_PASSWORD
    echo
    export CODE_SERVER_PASSWORD
fi

# === 创建必要的目录 ===
echo -e "${YELLOW}创建目录...${NC}"
mkdir -p "$CODE_SERVER_HOME"

# === 设置权限 ===
echo -e "${YELLOW}设置权限...${NC}"
setup_permissions() {
    local dir="$CODE_SERVER_HOME"
    if stat -c "%U:%G" "$dir" 2>/dev/null | grep -q "1000:1000"; then
        echo "  ✓ $dir (已是正确权限)"
        return 0
    fi
    if chown -R 1000:1000 "$dir" 2>/dev/null; then
        echo "  ✓ $dir"
        return 0
    else
        return 1
    fi
}

if setup_permissions; then
    echo "  ✓ 权限设置完成"
else
    if command -v sudo >/dev/null 2>&1; then
        echo "  需要管理员权限来设置目录权限"
        if sudo -n true 2>/dev/null; then
            sudo chown -R 1000:1000 "$CODE_SERVER_HOME" 2>/dev/null
            echo "  ✓ 权限设置完成（使用 sudo）"
        else
            echo -n "  请输入 sudo 密码: "
            read -s PASSWORD
            echo
            echo "$PASSWORD" | sudo -S chown -R 1000:1000 "$CODE_SERVER_HOME" 2>/dev/null
            unset PASSWORD
            if setup_permissions; then
                echo "  ✓ 权限设置完成"
            else
                echo -e "${RED}  ✗ 权限设置失败，请手动运行以下命令：${NC}"
                echo "  sudo chown -R 1000:1000 $CODE_SERVER_HOME"
                echo ""
                read -p "是否继续部署？(y/N) " -n 1 -r
                echo
                if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                    echo -e "${RED}部署已取消${NC}"
                    exit 1
                fi
            fi
        fi
    else
        echo -e "${YELLOW}  ⚠️  无法设置目录权限，可能需要手动设置${NC}"
    fi
fi

# === 检查 Docker Compose 版本 ===
echo -e "${YELLOW}检查 Docker Compose...${NC}"
if docker compose version >/dev/null 2>&1; then
    DOCKER_COMPOSE="docker compose"
else
    DOCKER_COMPOSE="docker-compose"
fi
echo "使用: $DOCKER_COMPOSE"

# === 检查是否需要 sudo ===
if ! docker info >/dev/null 2>&1; then
    echo "检测到需要 sudo 权限运行 Docker 命令"
    DOCKER_COMPOSE="sudo $DOCKER_COMPOSE"
fi

# === 检查镜像是否已存在 ===
echo -e "${YELLOW}检查 Docker 镜像...${NC}"
if docker images -q "$IMAGE_NAME" 2>/dev/null | grep -q .; then
    echo -e "${GREEN}✓ Docker 镜像已存在: $IMAGE_NAME (跳过构建)${NC}"
    echo "  如需重新构建，请删除镜像后重新运行:"
    echo "    docker rmi $IMAGE_NAME"
    echo "    $DOCKER_COMPOSE build --no-cache"
else
    echo -e "${YELLOW}构建 Docker 镜像: $IMAGE_NAME${NC}"
    echo "AionUi 版本: ${AIONUI_VERSION}"
    echo ""
    $DOCKER_COMPOSE build --build-arg AIONUI_VERSION="${AIONUI_VERSION}" 2>&1 | tee /tmp/docker-build.log
    if [ ${PIPESTATUS[0]} -ne 0 ]; then
        echo ""
        echo -e "${RED}============================================${NC}"
        echo -e "${RED}构建失败！${NC}"
        echo -e "${RED}============================================${NC}"
        echo ""
        echo "详细日志已保存到: /tmp/docker-build.log"
        echo ""
        echo "请运行以下命令查看完整错误："
        echo "  cat /tmp/docker-build.log"
        echo ""
        echo "或重新构建："
        echo "  $DOCKER_COMPOSE build --no-cache"
        exit 1
    fi
fi

# === 启动服务 ===
echo -e "${YELLOW}启动服务...${NC}"
$DOCKER_COMPOSE up -d

# === 显示服务状态 ===
echo ""
echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}部署完成！${NC}"
echo -e "${GREEN}============================================${NC}"
echo ""
$DOCKER_COMPOSE ps

# === 显示访问信息 ===
echo ""
echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}访问地址${NC}"
echo -e "${GREEN}============================================${NC}"
echo ""
echo "Code-Server:  http://localhost:${CODE_SERVER_PORT}"
echo "  密码: <您设置的密码>"
echo ""
echo "AionUi:       http://localhost:${AIONUI_PORT}"
if [ -n "$AIONUI_PASSWORD" ]; then
    echo "  用户名: ${AIONUI_USERNAME}"
    echo "  密码: <您设置的密码>"
else
    echo "  首次登录会显示随机密码"
fi
echo ""
echo "noVNC:        http://localhost:${NOVNC_PORT}"
echo ""
echo "Chrome CDP:   http://localhost:${CDP_PORT}"
echo "  使用 chrome-manager 命令管理 Chrome 服务"
echo ""
echo -e "${YELLOW}提示:${NC}"
echo "1. 首次访问 AionUi 会创建默认管理员账号"
echo "2. 通过 chrome-manager start-vnc 可启动可视化浏览器"
echo "3. AI 使用 CDP 自动化，人工可通过 noVNC 辅助登录"
echo ""
echo "常用命令:"
echo "  进入容器: docker exec -it ${CONTAINER_NAME} bash"
echo "  查看日志: $DOCKER_COMPOSE logs -f"
echo "  停止服务: $DOCKER_COMPOSE down"
echo "  重启服务: $DOCKER_COMPOSE restart"
echo ""
echo -e "${GREEN}============================================${NC}"
