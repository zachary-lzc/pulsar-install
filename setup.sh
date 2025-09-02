#!/bin/bash

# Apache Pulsar 完整部署脚本
# 包含JWT认证、Pulsar Manager集成和密码持久化

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$SCRIPT_DIR"

echo "🚀 Apache Pulsar 完整部署开始..."
echo "📍 项目目录: $PROJECT_DIR"
echo ""

# 创建必要的目录
echo "📁 创建数据和配置目录..."
mkdir -p "$PROJECT_DIR/data/zookeeper" \
         "$PROJECT_DIR/data/bookkeeper" \
         "$PROJECT_DIR/data/postgres" \
         "$PROJECT_DIR/data/pulsar-manager" \
         "$PROJECT_DIR/conf/zookeeper" \
         "$PROJECT_DIR/conf/bookkeeper" \
         "$PROJECT_DIR/conf/broker" \
         "$PROJECT_DIR/conf/postgres" \
         "$PROJECT_DIR/logs"

# 步骤1: 生成JWT密钥和Token
echo "🔐 步骤1: 生成JWT认证密钥和Token..."
if [ ! -f "$PROJECT_DIR/conf/jwt-auth.env" ]; then
    bash "$PROJECT_DIR/scripts/generate-jwt.sh"
else
    echo "✅ JWT配置已存在，跳过生成"
fi
echo ""

# 步骤2: 启动服务
echo "🐳 步骤2: 启动Pulsar集群服务..."
cd "$PROJECT_DIR"
docker-compose up -d zookeeper
echo "⏳ 等待ZooKeeper启动..."
sleep 30

docker-compose up -d pulsar-init
echo "⏳ 等待集群元数据初始化..."
sleep 15

docker-compose up -d bookie
echo "⏳ 等待BookKeeper启动..."
sleep 30

docker-compose up -d broker
echo "⏳ 等待Broker启动..."
sleep 30

docker-compose up -d postgres
echo "⏳ 等待PostgreSQL启动..."
sleep 15

docker-compose up -d pulsar-manager
echo "⏳ 等待Pulsar Manager启动..."
sleep 45

echo ""

# 步骤3: 验证服务状态
echo "🔍 步骤3: 验证服务状态..."
docker-compose ps

echo ""

# 步骤4: 初始化Pulsar Manager
echo "👤 步骤4: 初始化Pulsar Manager管理员用户..."
bash "$PROJECT_DIR/scripts/init-pulsar-manager.sh"

echo ""

# 步骤5: 验证部署
echo "✅ 步骤5: 验证部署状态..."

echo "🔗 服务访问地址："
echo "   - Pulsar Broker HTTP API: http://localhost:8081"
echo "   - Pulsar Manager Web UI: http://localhost:9527"
echo "   - PostgreSQL Database: localhost:5432"
echo ""

echo "🔑 默认凭据："
echo "   - Pulsar Manager用户名: admin"
echo "   - Pulsar Manager密码: pulsar@123"
echo "   - PostgreSQL用户名: pulsar"
echo "   - PostgreSQL密码: pulsar123"
echo ""

# 检查服务健康状态
echo "🏥 检查服务健康状态..."
sleep 5

# 检查Pulsar Manager
if curl -s http://localhost:9527 > /dev/null; then
    echo "✅ Pulsar Manager: 运行正常"
else
    echo "❌ Pulsar Manager: 连接失败"
fi

# 检查Broker
if curl -s http://localhost:8081/admin/v2/clusters > /dev/null; then
    echo "✅ Pulsar Broker: 运行正常"
else
    echo "❌ Pulsar Broker: 连接失败"
fi

# 检查PostgreSQL
if docker exec pulsar-postgres pg_isready -U pulsar > /dev/null 2>&1; then
    echo "✅ PostgreSQL: 运行正常"
else
    echo "❌ PostgreSQL: 连接失败"
fi

echo ""
echo "🎉 Apache Pulsar 部署完成！"
echo ""
echo "📖 下一步操作："
echo "   1. 访问 http://localhost:9527 登录Pulsar Manager"
echo "   2. 使用 admin/pulsar@123 登录"
echo "   3. 添加集群配置："
echo "      - Cluster Name: cluster-a"
echo "      - Service URL: http://broker:8080"
echo "      - Broker URL: pulsar://broker:6650"
echo ""
echo "🛠️  常用命令："
echo "   - 查看日志: docker-compose logs [service-name]"
echo "   - 重启服务: docker-compose restart [service-name]"
echo "   - 停止所有服务: docker-compose down"
echo "   - 完全清理: docker-compose down -v && rm -rf data/"
