# OpenClaw v4.3 - AI 智能体容器

> 一站式 AI 智能体开发环境，集成 Code-Server、AionUi、Playwright Chrome、浏览器自动化、文档处理等能力

[![Docker](https://img.shields.io/badge/Docker-Ready-blue)](https://www.docker.com/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

## 特性

- 🖥️ **Code-Server** - 基于 VS Code 的 Web IDE
- 🤖 **AionUi** - AI 智能体 Web 界面
- 🌐 **Playwright Chrome** - 浏览器自动化 + CDP 支持
- 📺 **noVNC** - 可视化浏览器（按需启动）
- 📄 **文档处理** - Pandoc、python-docx、PyPDF2、OCR
- 🎬 **音视频处理** - FFmpeg、ImageMagick
- 🐍 **Python 开发** - 完整的数据处理和分析工具链
- 🎯 **MediaCrawler** - 社交媒体爬虫支持

## 快速开始

### 前置要求

- Docker 20.10+
- Docker Compose 2.0+
- 至少 4GB 内存
- 至少 5GB 可用磁盘空间

### 部署

```bash
# 克隆仓库
git clone https://github.com/yourusername/coder-server-aionui.git
cd coder-server-aionui

# 设置环境变量并部署
CODE_SERVER_HOME=/path/to/workspace \
CODE_SERVER_PASSWORD=your_secure_password \
./docker-setup.sh
```

### 必需环境变量

| 变量 | 说明 | 示例 |
|------|------|------|
| `CODE_SERVER_HOME` | 工作目录路径 | `/home/docker/codeserver` |
| `CODE_SERVER_PASSWORD` | Code-Server 访问密码 | `your_secure_password` |

### 可选环境变量

#### 基础配置

| 变量 | 说明 | 默认值 |
|------|------|--------|
| `CODE_SERVER_PORT` | Code-Server 外部端口 | `8080` |
| `DOCKER_USER` | 容器内用户名 | `coder` |
| `TZ` | 时区 | `Asia/Shanghai` |

#### AionUi 配置

| 变量 | 说明 | 默认值 |
|------|------|--------|
| `AIONUI_PORT` | AionUi 外部端口 | `25808` |
| `AIONUI_PASSWORD` | AionUi 密码 | 首次随机生成 |
| `AIONUI_USERNAME` | AionUi 用户名 | `admin` |
| `AIONUI_VERSION` | AionUi 版本（构建时） | `1.6.18` |

#### VNC 配置

| 变量 | 说明 | 默认值 |
|------|------|--------|
| `NOVNC_PORT` | noVNC Web 界面端口 | `6080` |
| `VNC_PORT` | VNC 服务端口（内部） | `5900` |
| `VNC_GEOMETRY` | VNC 分辨率 | `1280x720` |
| `VNC_DEPTH` | VNC 色深 | `24` |
| `DISPLAY` | X11 显示号 | `:99` |

#### Chrome 配置

| 变量 | 说明 | 默认值 |
|------|------|--------|
| `CDP_PORT` | Chrome DevTools 端口 | `9222` |
| `CHROME_PROFILE_DIR` | Chrome 用户数据目录 | `/home/coder/.chrome` |

#### Docker 配置

| 变量 | 说明 | 默认值 |
|------|------|--------|
| `COMPOSE_PROJECT_NAME` | Docker Compose 项目名 | `openclaw` |
| `CONTAINER_NAME` | 容器名称 | `openclaw` |
| `AIONUI_NETWORKS` | Docker 网络名称 | `openclaw-network` |
| `IMAGE_NAME` | 镜像名称 | `{COMPOSE_PROJECT_NAME}_code-server-aionui` |

## 访问服务

部署完成后，可访问以下服务：

| 服务 | 地址 | 用途 |
|------|------|------|
| Code-Server | `http://localhost:<CODE_SERVER_PORT>` | Web IDE |
| AionUi | `http://localhost:<AIONUI_PORT>` | AI 智能体界面 |
| noVNC | `http://localhost:<NOVNC_PORT>` | 可视化浏览器 |

## 常用命令

```bash
# 进入容器
docker exec -it <CONTAINER_NAME> bash

# 查看服务状态
docker exec <CONTAINER_NAME> supervisorctl status

# 查看日志
docker-compose logs -f

# 停止服务
docker-compose down

# 重启服务
docker-compose restart
```

## Chrome 浏览器管理

```bash
# 启动无头浏览器
chrome-manager start-headless

# 启动可视化浏览器（VNC）
chrome-manager start-vnc

# 查看状态
chrome-manager status

# 停止浏览器
chrome-manager stop
```

## 目录结构

```
coder-server-aionui/
├── Dockerfile              # Docker 镜像构建文件
├── docker-compose.yml      # Docker Compose 配置
├── docker-setup.sh         # 一键部署脚本
├── README.md               # 本文件
├── 部署说明.md              # 详细部署指南
├── docker/                 # 配置脚本目录
│   ├── entrypoint.sh       # 容器入口脚本
│   ├── vnc-entrypoint.sh   # VNC 启动脚本
│   ├── chrome-entrypoint.sh # Chrome 启动脚本
│   ├── chrome-manager.sh   # Chrome 管理脚本
│   ├── supervisord.conf    # Supervisor 配置
│   └── aionui-password-setup.sh # AionUi 密码设置
└── docs/                   # 文档目录
    └── mediacrawler-guide.md # MediaCrawler 使用指南
```

## 更新日志

### v4.3 (2026-02-27)

- ✨ 移除本地 Chrome 依赖，改用在线安装
- ✨ 配置国内镜像源加速 Playwright 下载
- ✨ 固定 Playwright 版本为 1.48.0
- 🐛 修复缺少 chrome-headless-shell 组件问题
- 📝 移除所有硬编码，提升 GitHub 部署友好度

### v4.2

- ✨ 统一使用 Playwright Chrome
- ✨ 集成 MediaCrawler 支持
- 🐛 修复 AionUi 崩溃问题

## 文档

- [详细部署指南](部署说明.md)
- [MediaCrawler 使用指南](docs/mediacrawler-guide.md)

## 技术栈

- **基础镜像**: codercom/code-server:latest
- **Node.js**: 22.x
- **Python**: 3.x
- **Playwright**: 1.48.0
- **AionUi**: 1.7.8+

## 许可证

MIT License

## 贡献

欢迎提交 Issue 和 Pull Request！

## 致谢

- [code-server](https://github.com/coder/code-server)
- [AionUi](https://github.com/iOfficeAI/AionUi)
- [Playwright](https://playwright.dev/)
- [MediaCrawler](https://github.com/NanmiCoder/MediaCrawler)
