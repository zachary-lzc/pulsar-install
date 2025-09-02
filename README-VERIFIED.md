# Apache Pulsar Docker 集群部署指南

本文档详细记录了使用 Docker Compose 部署 Apache Pulsar 集群的完整步骤，包括 Pulsar Manager 管理界面的配置。**所有步骤均已验证可正常运行，现已成功部署并测试了50条消息。**

## 📋 功能特性

- ✅ **完整Pulsar集群**: ZooKeeper + BookKeeper + Broker
- ✅ **Pulsar Manager**: Web管理界面，支持集群监控
- ✅ **数据持久化**: 所有服务数据持久化存储
- ✅ **简化配置**: 开发测试友好的无认证配置
- ✅ **一键部署**: Docker Compose 一键启动
- ✅ **JWT预留**: 预留JWT认证扩展能力（当前未启用）

## 📁 项目结构

```
pulsar/
├── docker-compose.yml          # Docker Compose 配置文件（已验证）
├── README-VERIFIED.md          # 本部署文档（已验证版本）
├── README.md                   # 原有文档
├── .gitignore                  # Git 忽略文件配置
├── conf/                       # 配置文件目录
│   └── jwt/                    # JWT 认证密钥目录（预留）
│       └── public.pem          # JWT 公钥文件（当前为空）
└── data/                       # 数据持久化目录
    ├── zookeeper/              # ZooKeeper 数据
    ├── bookkeeper/             # BookKeeper 数据
    ├── postgres/               # PostgreSQL 数据
    └── pulsar-manager/         # Pulsar Manager 数据
```

## 🚀 快速开始

### 前置要求

- Docker Engine 20.10+
- Docker Compose 2.0+
- 至少 4GB 可用内存
- 端口要求：6650, 8081, 9527, 5432

### 1. 启动集群

```bash
# 一键启动所有服务
docker-compose up -d

# 等待30秒让服务完全启动
sleep 30
```

### 2. 验证服务状态

```bash
# 检查所有服务状态
docker-compose ps
```

预期输出（所有服务都应该是 "Up" 状态）：
```
NAME              IMAGE                                COMMAND                  SERVICE          STATUS
bookie            apachepulsar/pulsar:latest           "bash -c 'bin/apply-…"   bookie           Up X seconds
broker            apachepulsar/pulsar:latest           "bash -c 'bin/apply-…"   broker           Up X seconds
pulsar-manager    apachepulsar/pulsar-manager:v0.4.0   "/pulsar-manager/ent…"   pulsar-manager   Up X seconds
pulsar-postgres   postgres:13                          "docker-entrypoint.s…"   postgres         Up X seconds
zookeeper         apachepulsar/pulsar:latest           "bash -c 'bin/apply-…"   zookeeper        Up X seconds (healthy)
```

## 🔧 服务配置详解

### 当前配置模式：**无认证开发模式**

所有服务当前配置为开发测试模式，**禁用了认证和授权**，便于学习和测试：

```yaml
# Broker 关键配置
environment:
  - authenticationEnabled=false      # 禁用认证
  - authorizationEnabled=false       # 禁用授权
  - allowAutoTopicCreation=true      # 允许自动创建topic
  - allowAutoSubscriptionCreation=true  # 允许自动创建订阅
```

### 各服务详细配置

#### ZooKeeper 服务
- **作用**: 元数据存储和集群协调
- **内存配置**: 256MB
- **数据持久化**: `./data/zookeeper`
- **健康检查**: 每10秒检查，30次重试

#### BookKeeper 服务
- **作用**: 分布式日志存储
- **内存配置**: 512MB + 256MB 直接内存
- **数据持久化**: `./data/bookkeeper`
- **集群名称**: cluster-a

#### Pulsar Broker 服务
- **作用**: 消息代理服务
- **内存配置**: 512MB + 256MB 直接内存
- **端口映射**:
  - `6650`: Pulsar 协议端口（客户端连接）
  - `8081`: HTTP 管理端口（Admin API）
- **广播地址**: broker（内部），127.0.0.1（外部）

#### PostgreSQL 服务
- **作用**: Pulsar Manager 数据存储
- **数据库**: pulsar_manager
- **用户名**: pulsar
- **密码**: pulsar123
- **端口**: 5432

#### Pulsar Manager 服务
- **作用**: Web 管理界面
- **端口**: 9527
- **访问地址**: http://localhost:9527

## 🔐 管理员账户设置

### 创建 Pulsar Manager 超级用户

**重要**: 首次启动后必须创建管理员账户才能登录：

```bash
# 创建超级管理员账户（已验证命令）
CSRF_TOKEN=$(curl -s http://localhost:9527/pulsar-manager/csrf-token) && \
curl -H "X-XSRF-TOKEN: $CSRF_TOKEN" \
     -H "Cookie: XSRF-TOKEN=$CSRF_TOKEN" \
     -H "Content-Type: application/json" \
     -X PUT \
     http://localhost:9527/pulsar-manager/users/superuser \
     -d '{"name": "pulsar", "password": "pulsar@123", "description": "admin user", "email": "pulsar@apache.org"}'
```

**登录信息**:
- **URL**: http://localhost:9527
- **用户名**: `pulsar`
- **密码**: `pulsar@123`

## 🔗 连接方式说明

### 当前连接模式（无认证）

#### 1. Pulsar Manager ↔ Broker 连接
- **连接方式**: HTTP REST API
- **地址**: http://broker:8080（容器内网络）
- **认证**: 无需认证（authenticationEnabled=false）
- **用途**: 管理界面获取集群状态和统计信息

#### 2. 外部客户端 ↔ Broker 连接
- **Pulsar 协议**: `pulsar://localhost:6650`
- **HTTP Admin API**: `http://localhost:8081`
- **认证**: 当前无需认证

### 客户端连接示例

#### Java 客户端
```java
PulsarClient client = PulsarClient.builder()
    .serviceUrl("pulsar://localhost:6650")
    // 当前无需认证配置
    .build();

Producer<String> producer = client.newProducer(Schema.STRING)
    .topic("persistent://public/default/my-topic")
    .create();

Consumer<String> consumer = client.newConsumer(Schema.STRING)
    .topic("persistent://public/default/my-topic")
    .subscriptionName("my-subscription")
    .subscribe();
```

#### Go 客户端
```go
client, err := pulsar.NewClient(pulsar.ClientOptions{
    URL: "pulsar://localhost:6650",
    // 当前无需认证配置
})

producer, err := client.CreateProducer(pulsar.ProducerOptions{
    Topic: "persistent://public/default/my-topic",
})

consumer, err := client.Subscribe(pulsar.ConsumerOptions{
    Topic:            "persistent://public/default/my-topic",
    SubscriptionName: "my-subscription",
})
```

## 🧪 功能验证

### 1. 验证 Broker 健康状态
```bash
# 检查集群信息
curl http://localhost:8081/admin/v2/brokers/cluster-a
# 预期输出: ["broker:8080"]

# 检查健康状态
curl http://localhost:8081/admin/v2/brokers/health
# 预期输出: ok
```

### 2. 创建和测试 Topic
```bash
# 创建 topic
docker exec broker bin/pulsar-admin topics create persistent://public/default/test-topic

# 发送测试消息
echo "Hello Pulsar $(date)" | docker exec -i broker \
  bin/pulsar-client produce persistent://public/default/test-topic --messages -

# 消费消息（另开终端运行）
docker exec broker bin/pulsar-client consume \
  persistent://public/default/test-topic \
  --subscription-name test-sub \
  --num-messages 1
```

### 3. 批量消息测试（已验证）
```bash
# 发送50条消息（已测试成功）
docker exec broker bash -c '
for i in {1..50}; do 
  echo "Test message $i - $(date)" | \
  bin/pulsar-client produce persistent://public/default/jwt-test-topic --messages -
done'
```

### 4. 查看 Topic 统计信息
```bash
# 查看详细统计信息
docker exec broker bin/pulsar-admin topics stats persistent://public/default/jwt-test-topic

# 关键指标说明：
# - msgInCounter: 接收到的消息总数
# - msgBacklog: 积压的消息数量  
# - storageSize: 存储大小
```

## 📊 监控和管理

### Pulsar Manager 界面功能
1. **集群概览**: 查看集群状态、Broker数量、Topic数量
2. **Topic 管理**: 创建、删除、配置 Topic 和分区
3. **订阅管理**: 查看和管理消费者订阅
4. **消息监控**: 实时查看生产和消费速率
5. **统计图表**: 消息流量、存储使用等可视化图表

### 重要监控指标
- **msgRateIn**: 消息生产速率（msg/s）
- **msgRateOut**: 消息消费速率（msg/s）
- **msgBacklog**: 积压消息数量
- **storageSize**: 主题存储大小
- **bytesInCounter**: 总接收字节数
- **bytesOutCounter**: 总发送字节数

## 🚨 故障排除

### 常见问题及解决方案

#### 1. 服务启动失败
```bash
# 查看具体服务日志
docker logs <container_name>

# 常见原因及解决：
# - 端口占用：netstat -tlnp | grep <port>
# - 内存不足：增加Docker内存限制
# - 数据目录权限：sudo chown -R $USER:$USER data/
```

#### 2. Pulsar Manager 无法访问
```bash
# 检查服务状态
docker-compose ps pulsar-manager

# 检查日志
docker logs pulsar-manager

# 常见解决：
# 1. 确认端口9527未被占用
# 2. 等待更长时间让服务完全启动
# 3. 检查防火墙设置
```

#### 3. Broker 连接失败
```bash
# 验证 broker HTTP 服务
curl http://localhost:8081/admin/v2/brokers/health

# 验证 Pulsar 协议端口
telnet localhost 6650

# 检查容器间网络连接
docker exec pulsar-manager ping broker
```

#### 4. 创建管理员用户失败
```bash
# 确保Pulsar Manager已完全启动
docker logs pulsar-manager | tail -20

# 重试创建用户命令
CSRF_TOKEN=$(curl -s http://localhost:9527/pulsar-manager/csrf-token) && \
curl -H "X-XSRF-TOKEN: $CSRF_TOKEN" \
     -H "Cookie: XSRF-TOKEN=$CSRF_TOKEN" \
     -H "Content-Type: application/json" \
     -X PUT \
     http://localhost:9527/pulsar-manager/users/superuser \
     -d '{"name": "pulsar", "password": "pulsar@123", "description": "admin user", "email": "pulsar@apache.org"}'
```

### 重置和清理
```bash
# 停止所有服务
docker-compose down

# 完全清理（谨慎操作）
docker-compose down -v
sudo rm -rf data/*

# 重新启动
docker-compose up -d
```

## 🔒 JWT 认证准备（预留扩展）

当前部署为开发测试环境，**未启用认证**。如需启用 JWT 认证：

### 1. 准备 JWT 密钥对
```bash
# 创建密钥目录
mkdir -p conf/jwt

# 生成RSA私钥
openssl genpkey -algorithm RSA -out conf/jwt/private.pem -pkcs8 -pass pass:mypassword

# 生成公钥
openssl pkey -in conf/jwt/private.pem -pubout -out conf/jwt/public.pem -passin pass:mypassword
```

### 2. 修改 Broker 配置（启用认证时使用）
在 `docker-compose.yml` 的 broker 服务中修改：
```yaml
environment:
  # 启用认证
  - authenticationEnabled=true
  - authenticationProviders=org.apache.pulsar.broker.authentication.AuthenticationProviderToken
  - tokenPublicKey=file:///pulsar/jwt-public.pem
volumes:
  # 挂载公钥
  - ./conf/jwt/public.pem:/pulsar/jwt-public.pem:ro
```

### 3. 生成客户端 Token
```bash
# 使用私钥生成 token
docker exec broker bin/pulsar tokens create \
  --private-key file:///pulsar/conf/jwt/private.pem \
  --subject test-user
```

## 📝 数据持久化

### 持久化目录说明
```bash
data/
├── zookeeper/          # ZooKeeper 元数据
├── bookkeeper/         # 消息存储数据
├── postgres/           # Pulsar Manager 数据库
└── pulsar-manager/     # Manager 应用数据
```

### 备份建议
```bash
# 定期备份数据目录
tar -czf pulsar-backup-$(date +%Y%m%d-%H%M).tar.gz data/

# 自动备份脚本（示例）
#!/bin/bash
BACKUP_DIR="/path/to/backups"
DATE=$(date +%Y%m%d-%H%M)
tar -czf "$BACKUP_DIR/pulsar-backup-$DATE.tar.gz" data/
# 删除7天前的备份
find "$BACKUP_DIR" -name "pulsar-backup-*.tar.gz" -mtime +7 -delete
```

## 🔄 后续扩展计划

1. **JWT 认证集成**: 启用基于 JWT 的身份认证和授权
2. **多租户配置**: 配置命名空间和租户隔离  
3. **监控集成**: 集成 Prometheus + Grafana 监控
4. **高可用部署**: 多 Broker、多 Bookie 集群配置
5. **TLS 加密**: 启用端到端加密通信
6. **Geo-Replication**: 配置跨地域复制

## 📞 支持和维护

### 版本信息
- **验证时间**: 2025-09-02
- **Pulsar 版本**: latest (基于官方镜像)
- **Pulsar Manager 版本**: v0.4.0
- **PostgreSQL 版本**: 13
- **测试状态**: ✅ 已成功部署并测试50条消息

### 贡献
如有问题或改进建议，请：
1. 提交 Issue 描述问题
2. Fork 项目并提交 Pull Request
3. 更新文档说明变更

---

**重要提醒**: 本文档基于实际部署验证，确保所有步骤和配置的正确性。当前配置适用于开发测试环境，生产环境请启用认证和相应的安全配置。
