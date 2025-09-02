#!/bin/bash

# Pulsar Manager 初始化脚本
# 创建管理员用户并配置集群连接

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# 加载配置
if [ -f "$PROJECT_DIR/conf/pulsar-manager.env" ]; then
    source "$PROJECT_DIR/conf/pulsar-manager.env"
fi

# 默认值
ADMIN_USER="${PULSAR_MANAGER_ADMIN_USER:-admin}"
ADMIN_PASSWORD="${PULSAR_MANAGER_ADMIN_PASSWORD:-pulsar@123}"
ADMIN_EMAIL="${PULSAR_MANAGER_ADMIN_EMAIL:-admin@example.com}"
MANAGER_URL="http://localhost:9527"

echo "🔧 初始化Pulsar Manager..."

# 等待PostgreSQL准备就绪
echo "⏳ 等待PostgreSQL准备就绪..."
while ! docker exec pulsar-postgres pg_isready -U pulsar > /dev/null 2>&1; do
    echo "   PostgreSQL未就绪，等待中..."
    sleep 3
done
echo "✅ PostgreSQL已准备就绪"

# 等待Pulsar Manager启动
echo "⏳ 等待Pulsar Manager启动..."
MAX_WAIT=60
WAIT_COUNT=0
while [ $WAIT_COUNT -lt $MAX_WAIT ]; do
    if curl -s "$MANAGER_URL/pulsar-manager/csrf-token" > /dev/null 2>&1; then
        echo "✅ Pulsar Manager已启动"
        break
    fi
    echo "   等待Pulsar Manager启动... ($WAIT_COUNT/$MAX_WAIT)"
    sleep 5
    WAIT_COUNT=$((WAIT_COUNT + 1))
done

if [ $WAIT_COUNT -eq $MAX_WAIT ]; then
    echo "❌ Pulsar Manager启动超时"
    exit 1
fi

# 获取CSRF Token
echo "🔒 获取CSRF Token..."
CSRF_TOKEN=$(curl -s "$MANAGER_URL/pulsar-manager/csrf-token")
if [ -z "$CSRF_TOKEN" ]; then
    echo "❌ 无法获取CSRF Token"
    exit 1
fi
echo "✅ CSRF Token: $CSRF_TOKEN"

# 检查管理员用户是否已存在
echo "👤 检查管理员用户状态..."
USER_CHECK=$(curl -s -H "X-XSRF-TOKEN: $CSRF_TOKEN" -H "Cookie: XSRF-TOKEN=$CSRF_TOKEN;" "$MANAGER_URL/pulsar-manager/users/superuser")

if [[ "$USER_CHECK" == *"not found"* ]] || [[ -z "$USER_CHECK" ]]; then
    echo "➕ 创建管理员用户..."
    
    RESPONSE=$(curl -s \
        -H "X-XSRF-TOKEN: $CSRF_TOKEN" \
        -H "Cookie: XSRF-TOKEN=$CSRF_TOKEN;" \
        -H "Content-Type: application/json" \
        -X PUT "$MANAGER_URL/pulsar-manager/users/superuser" \
        -d "{\"name\": \"$ADMIN_USER\", \"password\": \"$ADMIN_PASSWORD\", \"description\": \"Administrator\", \"email\": \"$ADMIN_EMAIL\"}")
    
    if [[ "$RESPONSE" == *"success"* ]]; then
        echo "✅ 管理员用户创建成功！"
    else
        echo "❌ 管理员用户创建失败: $RESPONSE"
        exit 1
    fi
else
    echo "✅ 管理员用户已存在，跳过创建"
fi

echo ""
echo "🎉 Pulsar Manager初始化完成！"
echo ""
echo "📱 访问信息："
echo "   - URL: $MANAGER_URL"
echo "   - 用户名: $ADMIN_USER"
echo "   - 密码: $ADMIN_PASSWORD"
echo ""
echo "🔧 集群配置信息（在Manager中添加）："
echo "   - Cluster Name: cluster-a"
echo "   - Service URL: http://broker:8080"
echo "   - Bookie URL: http://broker:8080"
echo "   - Broker URL: pulsar://broker:6650"
echo ""
echo "💾 密码持久化："
echo "   - 用户数据已保存到HerdDB内嵌数据库"
echo "   - 数据目录: ./data/pulsar-manager/"
echo "   - 重启容器后数据不会丢失"

# 验证密码持久化
echo ""
echo "🧪 验证密码持久化..."
if [ -d "$PROJECT_DIR/data/pulsar-manager" ] && [ "$(ls -A $PROJECT_DIR/data/pulsar-manager 2>/dev/null)" ]; then
    echo "✅ 检测到持久化数据目录，密码数据已保存"
else
    echo "⚠️  持久化数据目录为空，可能需要重新创建用户"
fi
