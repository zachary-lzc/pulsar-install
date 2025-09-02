#!/bin/bash

echo "=== Pulsar Manager 配置验证 ==="
echo

echo "正在验证 Pulsar Manager 应该使用的 URL 配置..."
echo

echo "1. Service URL 测试: http://broker:8080"
docker exec pulsar-manager wget -qO- http://broker:8080/admin/v2/brokers/health && echo " ✓ 可访问" || echo " ✗ 失败"
echo

echo "2. Bookie URL 测试: http://broker:8080"
docker exec pulsar-manager wget -qO- http://broker:8080/admin/v2/bookies 2>/dev/null | head -100 && echo " ✓ 可访问" || echo " ✗ 失败"
echo

echo "3. 集群信息测试:"
docker exec pulsar-manager wget -qO- http://broker:8080/admin/v2/clusters 2>/dev/null || echo "需要先在 Manager 中添加集群"
echo

echo "=== 配置说明 ==="
echo "在 Pulsar Manager Web UI (http://localhost:9527) 中添加集群时，请使用："
echo
echo "📋 集群配置参数："
echo "  Cluster Name: cluster-a"
echo "  Service URL:  http://broker:8080"
echo "  Bookie URL:   http://broker:8080"
echo "  Broker URL:   pulsar://broker:6650"
echo
echo "🔑 登录凭据："
echo "  用户名: admin"
echo "  密码: apachepulsar"
echo
echo "⚠️  注意: 使用容器名 'broker' 而不是 'localhost'，"
echo "    因为 Pulsar Manager 运行在 Docker 容器内。"
