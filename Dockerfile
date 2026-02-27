# OpenClaw v4.3 - AI 助手容器
# 版本: 4.3
# 基于: codercom/code-server:latest
# 特性: Playwright Chrome CDP, MediaCrawler, 文档处理, OCR, 多媒体, 数据处理
# 更新: 在线安装 Playwright Chrome，支持镜像加速

FROM codercom/code-server:latest

# 切换到 root 用户以安装系统依赖
USER root

# 设置环境变量
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Shanghai
ENV DISPLAY=:99

# 设置时区
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# === 配置 apt 使用国内镜像（中科大）===
RUN sed -i 's/deb.debian.org/mirrors.ustc.edu.cn/g' /etc/apt/sources.list.d/debian.sources && \
    sed -i 's/security.debian.org/mirrors.ustc.edu.cn/g' /etc/apt/sources.list.d/debian.sources

# === 安装系统依赖 ===
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    # 构建工具
    build-essential make git curl wget ca-certificates jq ripgrep unzip \
    # Playwright/Chrome 依赖
    libnss3 libnspr4 libatk1.0-0 libatk-bridge2.0-0 libcups2 libdrm2 \
    libxkbcommon0 libxcomposite1 libxdamage1 libxfixes3 libxrandr2 \
    libgbm1 libasound2 libpango-1.0-0 libcairo2 libatspi2.0-0 \
    # === AionUi/Electron 完整依赖 ===
    # GTK 和图形库
    libgtk-3-0 libgdk-pixbuf-2.0-0 libcairo-gobject2 \
    # X11 库
    libx11-6 libxext6 libxrender1 libxfixes3 libxi6 libxtst6 libxrandr2 \
    libxinerama1 libxcursor1 libxss1 \
    # GConf 和配置系统
    libgconf-2-4 libdbus-1-3 \
    # 音频库
    libpulse0 libasound2 libasound2-plugins \
    # 其他 Electron 依赖
    libgbm1 libdrm2 libxkbcommon0 libatspi2.0-0 \
    # Secret Service (密码存储)
    libsecret-1-0 \
    # 通知
    libnotify4 \
    # 其他工具
    xdg-utils libglib2.0-0 libglib2.0-dev \
    # === Python 及完整开发支持 ===
    python3 python3-pip python3-venv python3-dev python3-full \
    # === Web VNC 工具 ===
    # 中文字体（中文渲染）
    fonts-noto-cjk fonts-wqy-zenhei fonts-wqy-microhei \
    # Web VNC (noVNC + websockify)
    novnc websockify \
    # X11 服务器和 VNC
    xvfb x11vnc xauth \
    # === 实用工具 ===
    socat net-tools netbase \
    # === 文本编辑器和终端工具 ===
    vim nano htop tmux less tree \
    # === 网络工具 ===
    netcat-openbsd httpie \
    # === 压缩工具 ===
    zip gzip bzip2 xz-utils \
    # === Pandoc 文档转换 ===
    pandoc \
    # === FFmpeg 视频处理 ===
    ffmpeg \
    # === ImageMagick 图像处理 ===
    imagemagick \
    # === Tesseract OCR ===
    tesseract-ocr tesseract-ocr-chi-sim tesseract-ocr-chi-tra \
    # === antiword (旧版 Word) ===
    antiword \
    # === poppler-utils (PDF 工具) ===
    poppler-utils \
    # 清理
    && rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*

# === 重新安装 Node.js 22.x（确保包含 corepack）===
# 使用 npmmirror 镜像加速
RUN curl -fsSL https://registry.npmmirror.com/-/binary/node/v22.11.0/node-v22.11.0-linux-x64.tar.xz -o /tmp/node.tar.xz && \
    tar -xf /tmp/node.tar.xz -C /usr/local --strip-components=1 && \
    rm -f /tmp/node.tar.xz && \
    npm install -g npm@latest

# 启用 corepack（支持 pnpm/yarn）
RUN corepack enable

# === 安装 Bun（可选，某些项目需要）===
ARG BUN_VERSION=1.1.0
RUN mkdir -p /usr/local/bin && \
    curl -fsSL https://registry.npmmirror.com/-/binary/bun/bun-v${BUN_VERSION}/bun-linux-x64.zip -o /tmp/bun.zip && \
    unzip -o /tmp/bun.zip -d /tmp && \
    mv /tmp/bun-linux-x64/bun /usr/local/bin/bun && \
    chmod +x /usr/local/bin/bun && \
    rm -rf /tmp/bun.zip /tmp/bun-linux-x64
ENV PATH="/usr/local/bin:${PATH}"

# === 配置 npm 使用 npmmirror 镜像 ===
RUN npm config set registry https://registry.npmmirror.com

# === 安装 Claude Code CLI ===
RUN npm install -g --unsafe-perm @anthropic-ai/claude-code

# === 配置 pip 使用国内镜像（清华）===
RUN pip config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple

# 升级 pip
RUN pip3 install --upgrade pip setuptools wheel --break-system-packages

# === 安装 Python 工具 ===

# HTTP 和网页处理
# 添加 bcrypt 用于 AionUi 密码哈希
RUN pip3 install --break-system-packages \
    requests \
    httpie \
    beautifulsoup4 \
    lxml \
    pillow \
    bcrypt

# 文档处理（Word、PDF、Excel、PPT）
RUN pip3 install --break-system-packages --no-cache-dir python-docx
RUN pip3 install --break-system-packages --no-cache-dir PyPDF2
RUN pip3 install --break-system-packages --no-cache-dir openpyxl
RUN pip3 install --break-system-packages --no-cache-dir python-pptx

# 数据处理和科学计算
RUN pip3 install --break-system-packages \
    pandas \
    numpy \
    scipy

# 文本处理
RUN pip3 install --break-system-packages \
    markdown2 \
    pyyaml \
    chardet \
    python-dateutil

# 数据可视化
RUN pip3 install --break-system-packages \
    matplotlib

# === 安装 Playwright（固定版本 1.48.0，稳定且镜像完善）===
# 使用较旧但稳定的版本，确保浏览器下载链接可用
ARG PLAYWRIGHT_VERSION=1.48.0
RUN pip3 install --break-system-packages playwright==${PLAYWRIGHT_VERSION}

# === 配置 Playwright 使用国内镜像 ===
# 设置 Playwright 下载镜像（使用淘宝镜像加速）
ENV PLAYWRIGHT_DOWNLOAD_HOST=https://npmmirror.com/mirrors/playwright/

# === 安装 Playwright 浏览器 ===
# 使用 playwright install 命令自动下载 chromium
# 重要: 必须安装到 /opt/ 而不是 /home/coder，因为 /home/coder 会被 docker volume 挂载覆盖
ENV PLAYWRIGHT_BROWSERS_PATH=/opt/ms-playwright
RUN echo "=== Installing Playwright Chromium ===" && \
    # 尝试从多个镜像源下载
    for MIRROR in \
        "https://npmmirror.com/mirrors/playwright" \
        "https://cdn.npmmirror.com/binaries/playwright" \
        "https://playwright.azureedge.net" \
        "https://playwright-akamai.azureedge.net"; do \
        echo "Trying mirror: $MIRROR" && \
        PLAYWRIGHT_DOWNLOAD_HOST="$MIRROR" playwright install chromium --with-deps && \
        echo "✓ Chromium installed successfully from $MIRROR" && \
        exit 0; \
    done && \
    echo "✗ All download sources failed" && exit 1

# === 验证 Playwright 安装 ===
RUN echo "=== Verifying Playwright Installation ===" && \
    playwright install --dry-run chromium && \
    ls -la ${PLAYWRIGHT_BROWSERS_PATH}/

# === 安装 MediaCrawler ===
RUN pip3 install --break-system-packages \
    playwright-stealth \
    aiohttp \
    aiofiles \
    PyExecJS \
    httpx \
    parsel \
    redis \
    aiomysql \
    asyncmy \
    orm \
    pydantic \
    PyPika \
    tenacity \
    caches

# === 安装 AionUi ===
ARG AIONUI_VERSION=${AIONUI_VERSION}
RUN echo "=== Installing AionUi ===" && \
    echo "Downloading AionUi v${AIONUI_VERSION}..." && \
    # 尝试从多个代理源下载，添加重试和验证
    # 使用 --http1.1 避免 HTTP/2 错误
    for url in \
        "https://gh-proxy.org/https://github.com/iOfficeAI/AionUi/releases/download/v${AIONUI_VERSION}/AionUi-${AIONUI_VERSION}-linux-amd64.deb" \
        "https://hk.gh-proxy.org/https://github.com/iOfficeAI/AionUi/releases/download/v${AIONUI_VERSION}/AionUi-${AIONUI_VERSION}-linux-amd64.deb" \
        "https://mirror.ghproxy.com/https://github.com/iOfficeAI/AionUi/releases/download/v${AIONUI_VERSION}/AionUi-${AIONUI_VERSION}-linux-amd64.deb" \
        "https://ghproxy.cn/https://github.com/iOfficeAI/AionUi/releases/download/v${AIONUI_VERSION}/AionUi-${AIONUI_VERSION}-linux-amd64.deb" \
        "https://github.moeyy.xyz/https://github.com/iOfficeAI/AionUi/releases/download/v${AIONUI_VERSION}/AionUi-${AIONUI_VERSION}-linux-amd64.deb"; do \
        echo "Trying: $url" && \
        if curl -fSL --retry 3 --retry-delay 2 --http1.1 "$url" -o /tmp/aionui.deb; then \
            # 验证文件大小（至少 20MB）
            FILE_SIZE=$(stat -c%s /tmp/aionui.deb 2>/dev/null || echo 0) && \
            if [ "$FILE_SIZE" -gt 20000000 ]; then \
                echo "Downloaded $FILE_SIZE bytes, installing..." && \
                dpkg -i /tmp/aionui.deb && \
                rm -f /tmp/aionui.deb && \
                echo "✓ AionUi installed successfully" && \
                exit 0; \
            else \
                echo "File too small ($FILE_SIZE bytes), trying next source..." && \
                rm -f /tmp/aionui.deb; \
            fi; \
        else \
            echo "Download failed, trying next source..."; \
        fi; \
    done && \
    echo "✗ All download sources failed" && exit 1

# 验证 AionUi 安装（不运行 --version 避免崩溃）
RUN which AionUi && ls -la /opt/AionUi/AionUi

# === 安装 Supervisor（多进程管理）===
RUN apt-get update && \
    apt-get install -y supervisor && \
    rm -rf /var/lib/apt/lists/*

# === 创建必要的目录 ===
RUN mkdir -p \
    /home/coder/.local/share/code-server \
    /home/coder/.config/code-server \
    /home/coder/.chrome \
    /home/coder/.aionui-data \
    /home/coder/workspace \
    /var/run/supervisor \
    /var/log/supervisor \
    /docker

# === 复制配置文件 ===
COPY docker/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY docker/entrypoint.sh /entrypoint.sh
COPY docker/vnc-entrypoint.sh /vnc-entrypoint.sh
COPY docker/chrome-entrypoint.sh /chrome-entrypoint.sh
COPY docker/chrome-manager.sh /usr/local/bin/chrome-manager
COPY docker/aionui-password-setup.sh /aionui-password-setup.sh

RUN chmod +x /entrypoint.sh /vnc-entrypoint.sh /chrome-entrypoint.sh /usr/local/bin/chrome-manager /aionui-password-setup.sh

# === 创建 Chrome 用户数据目录说明 ===
RUN echo "# Chrome 用户数据目录" > /home/coder/.chrome/README.md && \
    echo "" >> /home/coder/.chrome/README.md && \
    echo "此目录存储 Chrome 浏览器的用户数据，包括：" >> /home/coder/.chrome/README.md && \
    echo "- Cookies 和登录状态" >> /home/coder/.chrome/README.md && \
    echo "- 浏览历史" >> /home/coder/.chrome/README.md && \
    echo "- 扩展和插件" >> /home/coder/.chrome/README.md && \
    echo "- 下载记录" >> /home/coder/.chrome/README.md && \
    echo "" >> /home/coder/.chrome/README.md && \
    echo "使用 chrome-manager 命令管理 Chrome 服务：" >> /home/coder/.chrome/README.md && \
    echo "  chrome-manager start-headless  # 启动无头浏览器" >> /home/coder/.chrome/README.md && \
    echo "  chrome-manager start-vnc       # 启动 VNC 可视化浏览器" >> /home/coder/.chrome/README.md && \
    echo "  chrome-manager status          # 查看状态" >> /home/coder/.chrome/README.md

# === 设置权限 ===
RUN chown -R coder:coder /home/coder

# === 切换工作目录 ===
WORKDIR /home/coder

# === 暴露端口 ===
EXPOSE 8080 25808 6080 9222

# === 默认启动命令 ===
ENTRYPOINT ["/entrypoint.sh"]
