#!/bin/bash

# JWT Token
JWT_TOKEN="eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJhZG1pbiJ9.MG1ELUllbrhYNwpuLZpEcTeH_SfMJDTorGir7enh5Y4"

echo "🔑 测试 JWT 认证和 pulsarctl 功能"
echo "JWT Token: $JWT_TOKEN"
echo

# 公共参数
PULSARCTL_CMD="pulsarctl --admin-service-url http://localhost:8081 --auth-plugin org.apache.pulsar.client.impl.auth.AuthenticationToken --auth-params token:$JWT_TOKEN"

echo "1. 📋 列出集群："
$PULSARCTL_CMD clusters list
echo

echo "2. 🏢 列出租户："
$PULSARCTL_CMD tenants list
echo

echo "3. 📂 列出命名空间："
$PULSARCTL_CMD namespaces list public
echo

echo "4. 📝 列出 topics："
$PULSARCTL_CMD topics list public/default
echo

echo "5. 🆕 创建新的测试租户："
$PULSARCTL_CMD tenants create jwt-test-tenant --allowed-clusters cluster-a
echo

echo "6. 🆕 创建命名空间："
$PULSARCTL_CMD namespaces create jwt-test-tenant/jwt-namespace
echo

echo "7. 🆕 创建 topic："
$PULSARCTL_CMD topics create persistent://jwt-test-tenant/jwt-namespace/jwt-messages 0
echo

echo "8. 📋 查看新创建的 topics："
$PULSARCTL_CMD topics list jwt-test-tenant/jwt-namespace
echo

echo "9. 📊 查看 topic 统计信息："
$PULSARCTL_CMD topics stats persistent://jwt-test-tenant/jwt-namespace/jwt-messages
echo

echo "🎉 JWT 认证测试完成！"
echo "现在你可以使用以下 JWT token 进行所有管理操作："
echo "Token: $JWT_TOKEN"
echo
echo "💡 使用 pulsarctl 的完整命令格式："
echo "pulsarctl --admin-service-url http://localhost:8081 \\"
echo "          --auth-plugin org.apache.pulsar.client.impl.auth.AuthenticationToken \\"
echo "          --auth-params token:$JWT_TOKEN \\"
echo "          [命令]"
