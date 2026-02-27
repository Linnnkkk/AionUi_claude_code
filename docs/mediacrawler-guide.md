# MediaCrawler 使用指南

## 简介

MediaCrawler 是一个基于 Playwright 的媒体爬虫工具，支持：
- 小红书
- 抖音
- B站
- 微博
- 快手
- 公众号

本容器已集成 MediaCrawler 所需依赖，可以直接使用。

## 安装 MediaCrawler

```bash
# 进入容器（使用你的容器名称）
docker exec -it <CONTAINER_NAME> bash

# 克隆 MediaCrawler
cd ~
git clone https://github.com/NanmiCoder/MediaCrawler.git
cd MediaCrawler

# 安装依赖（通常已安装）
pip install -r requirements.txt
```

## 配置说明

编辑 `config.yaml` 配置文件：

```yaml
# 小红书配置
xiaohongshu:
  cookie: # 你的小红书 cookie
  web_driver_type: playwright  # 使用 playwright
  headless: true  # 无头模式

# 抖音配置
douyin:
  cookie: # 你的抖音 cookie
  web_driver_type: playwright
  headless: true

# B站配置
bilibili:
  cookie: # 你的 B站 cookie
  web_driver_type: playwright
  headless: true
```

## 获取 Cookie

### 方法一：使用 noVNC 手动登录

```bash
# 启动 VNC 模式
chrome-manager start-vnc

# 浏览器访问 http://localhost:<NOVNC_PORT>
# 在 VNC 中手动登录目标网站
# 使用 F12 开发者工具获取 Cookie
```

### 方法二：使用 Chrome DevTools

```bash
# 启动 headless 模式
chrome-manager start-headless

# 通过 CDP 控制浏览器登录后获取 Cookie
# URL: http://localhost:9222
```

## 运行爬虫

```bash
# 进入 MediaCrawler 目录
cd ~/MediaCrawler

# 运行爬虫
python main.py

# 运行指定平台
python main.py --platform xiaohongshu
```

## 数据存储

爬取的数据默认保存在 `~/MediaCrawler/data` 目录下，可以通过 code-server 直接查看。

## 常见问题

### Q: Playwright 找不到浏览器？

确保 Playwright Chrome 已正确安装：

```bash
# 检查 Chrome 路径
ls -la /opt/ms-playwright/chromium-*/chrome-linux/chrome

# 重新安装 Playwright 浏览器
playwright install chromium
```

### Q: 反爬检测太严格？

1. 使用 `playwright-stealth` 绕过检测（已安装）
2. 降低爬取频率
3. 使用代理 IP

```python
# 在 MediaCrawler 中使用 stealth
from playwright_stealth import stealth_sync

async with async_playwright() as p:
    browser = await p.chromium.launch(headless=True)
    page = await browser.new_page()
    await stealth_sync(page)  # 应用 stealth
```
