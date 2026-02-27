#!/bin/bash
set -e

# ============================================
# AionUi 密码设置脚本
# 功能: 通过环境变量 AIONUI_PASSWORD 设置 AionUi 管理员密码
# 版本: 1.1
# ============================================

DB_PATH="/home/coder/.config/AionUi/aionui/aionui.db"
USERNAME="${AIONUI_USERNAME:-admin}"
NEW_PASSWORD="${AIONUI_PASSWORD:-}"

# 如果没有设置密码，跳过
if [ -z "$NEW_PASSWORD" ]; then
    echo "[AionUi] 未设置 AIONUI_PASSWORD，使用默认随机密码"
    exit 0
fi

echo "=========================================="
echo "AionUi 密码设置工具"
echo "=========================================="
echo "数据库路径: $DB_PATH"
echo "用户名: $USERNAME"
echo "新密码: $NEW_PASSWORD"
echo ""

# 等待数据库创建
echo "[AionUi] 等待数据库初始化..."
MAX_WAIT=30
WAIT_COUNT=0
while [ ! -f "$DB_PATH" ]; do
    if [ $WAIT_COUNT -ge $MAX_WAIT ]; then
        echo "[AionUi] 超时：数据库未创建，跳过密码设置"
        exit 0
    fi
    sleep 1
    WAIT_COUNT=$((WAIT_COUNT + 1))
done

echo "[AionUi] 数据库已创建，开始设置密码..."

# 生成密码哈希
echo "[AionUi] 正在生成密码哈希..."
PASSWORD_HASH=$(python3 -c "
import bcrypt
password = b'${NEW_PASSWORD}'
salt = bcrypt.gensalt()
hashed = bcrypt.hashpw(password, salt)
print(hashed.decode())
")

echo "[AionUi] 正在更新数据库..."
python3 -c "
import sqlite3

# 将 Shell 变量传入 Python
username = '${USERNAME}'
password_hash = '${PASSWORD_HASH}'
db_path = '${DB_PATH}'

conn = sqlite3.connect(db_path)
cursor = conn.cursor()
cursor.execute('UPDATE users SET password_hash = ? WHERE username = ?', (password_hash, username))
conn.commit()
if cursor.rowcount > 0:
    print('密码更新成功！')
else:
    # 使用已定义的 Python 变量 username
    print(f'未找到用户: {username}，可能需要首次登录后手动设置')
"

echo ""
echo "=========================================="
echo "AionUi 密码设置完成！"
echo "=========================================="
echo "用户名: $USERNAME"
echo "密码: $NEW_PASSWORD"
echo "=========================================="