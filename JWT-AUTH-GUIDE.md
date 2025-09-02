# Pulsar JWT 认证使用指南

## 🔑 JWT Token 信息

你的管理员 JWT Token 已经生成并配置完成：

### 管理员 Token
```
eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJhZG1pbiJ9.MG1ELUllbrhYNwpuLZpEcTeH_SfMJDTorGir7enh5Y4
```

- **用户**: `admin`
- **权限**: 超级用户权限（可执行所有管理操作）

## 🌐 API 访问方式

### 1. HTTP API 调用（使用 curl）

```bash
# 基本健康检查
curl -H "Authorization: Bearer eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJhZG1pbiJ9.MG1ELUllbrhYNwpuLZpEcTeH_SfMJDTorGir7enh5Y4" \
     http://localhost:8081/admin/v2/brokers/health

# 查看集群信息
curl -H "Authorization: Bearer eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJhZG1pbiJ9.MG1ELUllbrhYNwpuLZpEcTeH_SfMJDTorGir7enh5Y4" \
     http://localhost:8081/admin/v2/clusters

# 创建租户
curl -X PUT \
     -H "Authorization: Bearer eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJhZG1pbiJ9.MG1ELUllbrhYNwpuLZpEcTeH_SfMJDTorGir7enh5Y4" \
     -H "Content-Type: application/json" \
     -d '{"allowedClusters":["cluster-a"]}' \
     http://localhost:8081/admin/v2/tenants/my-tenant

# 创建命名空间
curl -X PUT \
     -H "Authorization: Bearer eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJhZG1pbiJ9.MG1ELUllbrhYNwpuLZpEcTeH_SfMJDTorGir7enh5Y4" \
     http://localhost:8081/admin/v2/namespaces/my-tenant/my-namespace

# 创建 Topic
curl -X PUT \
     -H "Authorization: Bearer eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJhZG1pbiJ9.MG1ELUllbrhYNwpuLZpEcTeH_SfMJDTorGir7enh5Y4" \
     http://localhost:8081/admin/v2/persistent/my-tenant/my-namespace/my-topic
```

### 2. Pulsar Admin CLI（容器内）

```bash
# 进入 broker 容器
docker exec -it broker bash

# 使用 JWT token 进行管理操作
export PULSAR_CLIENT_CONF=/tmp/client.conf

# 创建客户端配置文件
echo 'authPlugin=org.apache.pulsar.client.impl.auth.AuthenticationToken
authParams=token:eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJhZG1pbiJ9.MG1ELUllbrhYNwpuLZpEcTeH_SfMJDTorGir7enh5Y4' > /tmp/client.conf

# 使用认证执行管理命令
bin/pulsar-admin --auth-plugin org.apache.pulsar.client.impl.auth.AuthenticationToken \
                 --auth-params token:eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJhZG1pbiJ9.MG1ELUllbrhYNwpuLZpEcTeH_SfMJDTorGir7enh5Y4 \
                 tenants list

# 或者使用配置文件
bin/pulsar-admin --client-conf /tmp/client.conf tenants list
```

### 3. 客户端连接（生产者/消费者）

```bash
# 生产消息
bin/pulsar-client --auth-plugin org.apache.pulsar.client.impl.auth.AuthenticationToken \
                  --auth-params token:eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJhZG1pbiJ9.MG1ELUllbrhYNwpuLZpEcTeH_SfMJDTorGir7enh5Y4 \
                  produce persistent://public/default/test-topic \
                  --messages "Hello with JWT auth"

# 消费消息
bin/pulsar-client --auth-plugin org.apache.pulsar.client.impl.auth.AuthenticationToken \
                  --auth-params token:eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJhZG1pbiJ9.MG1ELUllbrhYNwpuLZpEcTeH_SfMJDTorGir7enh5Y4 \
                  consume persistent://public/default/test-topic \
                  --subscription my-subscription
```

## 🔒 在不同语言中使用 JWT Token

### Java 客户端
```java
PulsarClient client = PulsarClient.builder()
    .serviceUrl("pulsar://localhost:6650")
    .authentication(AuthenticationFactory.token("eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJhZG1pbiJ9.MG1ELUllbrhYNwpuLZpEcTeH_SfMJDTorGir7enh5Y4"))
    .build();
```

### Python 客户端
```python
import pulsar

client = pulsar.Client('pulsar://localhost:6650',
                      authentication=pulsar.AuthenticationToken('eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJhZG1pbiJ9.MG1ELUllbrhYNwpuLZpEcTeH_SfMJDTorGir7enh5Y4'))
```

### Go 客户端
```go
client, err := pulsar.NewClient(pulsar.ClientOptions{
    URL: "pulsar://localhost:6650",
    Authentication: pulsar.NewAuthenticationToken("eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJhZG1pbiJ9.MG1ELUllbrhYNwpuLZpEcTeH_SfMJDTorGir7enh5Y4"),
})
```

## 🔧 生成其他用户的 Token

如果需要为其他用户生成 token：

```bash
# 进入 broker 容器
docker exec -it broker bash

# 为普通用户生成 token
bin/pulsar tokens create --secret-key file:///tmp/secret.key --subject user1

# 为特定角色生成 token
bin/pulsar tokens create --secret-key file:///tmp/secret.key --subject producer-role
bin/pulsar tokens create --secret-key file:///tmp/secret.key --subject consumer-role
```

## 📋 Pulsar Manager 配置

在 Pulsar Manager Web UI (http://localhost:9527) 中添加集群时使用：

- **Cluster Name**: `cluster-a`
- **Service URL**: `http://broker:8080`
- **Bookie URL**: `http://broker:8080`  
- **Broker URL**: `pulsar://broker:6650`

## 🚫 无认证访问

注意：启用 JWT 认证后，所有 API 调用都需要提供有效的 token。无认证的请求将被拒绝：

```bash
# 这个请求会失败
curl http://localhost:8081/admin/v2/brokers/health
# 返回: 401 Unauthorized
```

## 🔐 安全注意事项

1. **保护密钥文件**: `jwt-keys/secret.key` 包含签名密钥，请妥善保管
2. **Token 安全**: 不要在日志或公开代码中暴露 JWT token
3. **生产环境**: 建议使用 RSA 密钥对而不是 HMAC 密钥
4. **Token 过期**: 当前 token 没有设置过期时间，生产环境建议设置合理的过期时间

## 📁 相关文件

- `jwt-keys/secret.key`: JWT 签名密钥
- `jwt-keys/admin-token.txt`: 管理员 token
- `docker-compose.yml`: 包含 JWT 认证配置的服务定义
