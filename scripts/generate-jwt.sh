#!/bin/bash

# JWT密钥和Token生成脚本
# 用于Apache Pulsar集群认证配置 - 使用RSA公私钥对

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
CONF_DIR="$PROJECT_DIR/conf"
JWT_DIR="$CONF_DIR/jwt"

# 创建目录
mkdir -p "$JWT_DIR" "$PROJECT_DIR/scripts"

echo "🔐 正在生成JWT RSA密钥对和Token..."

# 检查依赖
if ! command -v openssl &> /dev/null; then
    echo "❌ 错误: 需要安装 openssl"
    exit 1
fi

if ! command -v python3 &> /dev/null; then
    echo "❌ 错误: 需要安装 python3"
    exit 1
fi

if ! python3 -c "import jwt" 2>/dev/null; then
    echo "📦 安装PyJWT库..."
    pip3 install PyJWT[crypto]
fi

# 生成RSA私钥 (2048位)
echo "🔑 生成RSA私钥..."
openssl genrsa -out "$JWT_DIR/private.pem" 2048

# 生成RSA公钥
echo "🔓 生成RSA公钥..."
openssl rsa -in "$JWT_DIR/private.pem" -pubout -out "$JWT_DIR/public.pem"

# 生成管理员Token (使用RSA私钥签名)
echo "🎫 生成管理员Token..."
ADMIN_TOKEN=$(python3 -c "
import jwt

# 读取RSA私钥
with open('$JWT_DIR/private.pem', 'r') as f:
    private_key = f.read()

# 生成admin用户的token
payload = {'sub': 'admin'}
token = jwt.encode(payload, private_key, algorithm='RS256')
print(token)
")

# 生成客户端Token
echo "🎫 生成客户端Token..."
CLIENT_TOKEN=$(python3 -c "
import jwt

# 读取RSA私钥
with open('$JWT_DIR/private.pem', 'r') as f:
    private_key = f.read()

# 生成client用户的token
payload = {'sub': 'client'}
token = jwt.encode(payload, private_key, algorithm='RS256')
print(token)
")

# 生成Pulsar Manager Token
echo "🎫 生成Pulsar Manager Token..."
MANAGER_TOKEN=$(python3 -c "
import jwt

# 读取RSA私钥
with open('$JWT_DIR/private.pem', 'r') as f:
    private_key = f.read()

# 生成pulsar-manager用户的token
payload = {'sub': 'pulsar-manager'}
token = jwt.encode(payload, private_key, algorithm='RS256')
print(token)
")

# 创建JWT环境变量文件
cat > "$JWT_DIR/jwt.env" << EOF
# JWT认证配置 - RSA公私钥对
ADMIN_JWT_TOKEN=$ADMIN_TOKEN
CLIENT_JWT_TOKEN=$CLIENT_TOKEN
MANAGER_JWT_TOKEN=$MANAGER_TOKEN
BROKER_CLIENT_AUTH_PARAMS=token:$ADMIN_TOKEN
SUPER_USER_ROLES=admin,pulsar-manager
EOF

# 创建用于Docker Compose的JWT配置
cat > "$CONF_DIR/jwt-auth.env" << EOF
# Pulsar JWT认证配置 - RSA公钥验证
authenticationEnabled=true
authenticationProviders=org.apache.pulsar.broker.authentication.AuthenticationProviderToken
brokerClientAuthenticationPlugin=org.apache.pulsar.client.impl.auth.AuthenticationToken
brokerClientAuthenticationParameters=token:$ADMIN_TOKEN
tokenPublicKey=file:///opt/pulsar/conf/public.pem
superUserRoles=admin,pulsar-manager
EOF

# 更新Pulsar Manager配置以包含JWT Token
cat >> "$CONF_DIR/pulsar-manager.env" << EOF

# JWT认证配置
JWT_TOKEN=$MANAGER_TOKEN
EOF

echo "✅ JWT RSA密钥对和Token生成完成！"
echo ""
echo "📁 生成的文件："
echo "   - RSA私钥: $JWT_DIR/private.pem"
echo "   - RSA公钥: $JWT_DIR/public.pem"
echo "   - JWT环境变量: $JWT_DIR/jwt.env"
echo "   - 认证配置: $CONF_DIR/jwt-auth.env"
echo ""
echo "🔑 生成的Token："
echo "   - 管理员Token: $ADMIN_TOKEN"
echo "   - 客户端Token: $CLIENT_TOKEN"
echo "   - Manager Token: $MANAGER_TOKEN"
echo ""
echo "⚠️  重要提示："
echo "   - 这些文件包含敏感信息，请妥善保管"
echo "   - RSA私钥用于签名，公钥用于验证"
echo "   - 已自动添加到.gitignore，不会被提交到版本控制"
echo "   - Pulsar Manager现在可以使用JWT Token连接Broker"
