# Pulsar 配置文件说明

这个目录包含了所有Pulsar集群组件的配置文件。通过修改这些文件，你可以自定义Pulsar的行为而无需修改docker-compose.yml。

## 📁 配置文件结构

```
conf/
├── README.md              # 本说明文档
├── zookeeper.env         # ZooKeeper配置
├── bookkeeper.env        # BookKeeper配置  
├── broker.env            # Broker基础配置
├── postgres.env          # PostgreSQL配置
├── pulsar-manager.env    # Pulsar Manager配置
├── cluster-init.env      # 集群初始化配置
├── jwt-auth.env          # JWT认证配置（自动生成）
└── jwt/                  # JWT密钥目录（自动生成）
    ├── secret.key        # JWT密钥文件
    └── jwt.env           # JWT环境变量
```

## 🔧 配置文件详解

### ZooKeeper 配置 (`zookeeper.env`)

ZooKeeper作为Pulsar的元数据存储和协调服务：

```bash
# 元数据存储URL
metadataStoreUrl=zk:zookeeper:2181

# JVM内存配置
PULSAR_MEM=-Xms256m -Xmx256m -XX:MaxDirectMemorySize=256m
```

**常用调优参数：**
- 增加内存：`PULSAR_MEM=-Xms512m -Xmx512m`
- 数据目录：通过docker-compose.yml中的volumes配置

### BookKeeper 配置 (`bookkeeper.env`)

BookKeeper提供持久化存储层：

```bash
# 集群名称
clusterName=cluster-a

# ZooKeeper连接
zkServers=zookeeper:2181

# 元数据服务URI
metadataServiceUri=metadata-store:zk:zookeeper:2181

# 节点地址
advertisedAddress=bookie

# JVM内存配置
BOOKIE_MEM=-Xms512m -Xmx512m -XX:MaxDirectMemorySize=256m
```

**常用调优参数：**
- 增加写入缓存：`dbStorage_writeCacheMaxSizeMb=512`
- 增加读取缓存：`dbStorage_readAheadCacheMaxSizeMb=256`

### Broker 配置 (`broker.env`)

Broker是Pulsar的核心消息代理：

```bash
# 基础配置
metadataStoreUrl=zk:zookeeper:2181
zookeeperServers=zookeeper:2181
clusterName=cluster-a

# 集群配置
managedLedgerDefaultEnsembleSize=1
managedLedgerDefaultWriteQuorum=1
managedLedgerDefaultAckQuorum=1

# 网络配置
advertisedAddress=broker
advertisedListeners=external:pulsar://127.0.0.1:6650

# JVM内存配置
PULSAR_MEM=-Xms512m -Xmx512m -XX:MaxDirectMemorySize=256m
```

**生产环境调优：**
- 增加并发：`numWorkerThreadsForNonPersistentTopic=8`
- 消息批处理：`maxMessageSize=5242880`
- 压缩：`compressionType=LZ4`

### PostgreSQL 配置 (`postgres.env`)

PostgreSQL作为Pulsar Manager的后端数据库：

```bash
# 数据库配置
POSTGRES_DB=pulsar_manager
POSTGRES_USER=pulsar
POSTGRES_PASSWORD=pulsar123

# 可选配置
# POSTGRES_INITDB_ARGS=--encoding=UTF-8 --lc-collate=C --lc-ctype=C
```

**生产环境建议：**
- 使用强密码
- 配置SSL连接
- 设置连接池限制

### Pulsar Manager 配置 (`pulsar-manager.env`)

Pulsar Manager Web管理界面配置：

```bash
# 应用配置
SPRING_CONFIGURATION_FILE=/pulsar-manager/pulsar-manager/application.properties

# 网络配置
ENV_REDIRECT_HOST=localhost
ENV_REDIRECT_PORT=9527

# 数据库配置（可选，默认使用HerdDB）
ENV_DRIVER_CLASS_NAME=org.postgresql.Driver
ENV_URL=jdbc:postgresql://postgres:5432/pulsar_manager
ENV_USERNAME=pulsar
ENV_PASSWORD=pulsar123

# 日志级别
ENV_LOG_LEVEL=INFO

# 管理员默认凭据
PULSAR_MANAGER_ADMIN_USER=admin
PULSAR_MANAGER_ADMIN_PASSWORD=pulsar@123
PULSAR_MANAGER_ADMIN_EMAIL=admin@example.com
```

### JWT认证配置 (`jwt-auth.env`) - 自动生成

这个文件由 `scripts/generate-jwt.sh` 脚本自动生成：

```bash
# Pulsar JWT认证配置
authenticationEnabled=true
authenticationProviders=org.apache.pulsar.broker.authentication.AuthenticationProviderToken
brokerClientAuthenticationPlugin=org.apache.pulsar.client.impl.auth.AuthenticationToken
brokerClientAuthenticationParameters=token:YOUR_ADMIN_TOKEN
tokenSecretKey=data:;base64,YOUR_SECRET_KEY
superUserRoles=admin
```

## 🔄 配置修改流程

### 1. 修改配置文件

```bash
# 例如：修改Broker内存配置
vim conf/broker.env

# 修改内容
PULSAR_MEM=-Xms1g -Xmx1g -XX:MaxDirectMemorySize=1g
```

### 2. 重启相关服务

```bash
# 重启受影响的服务
docker-compose restart broker

# 或重新部署所有服务
docker-compose down
docker-compose up -d
```

### 3. 验证配置生效

```bash
# 检查服务状态
docker-compose ps

# 查看服务日志
docker-compose logs broker
```

## 🔐 安全配置最佳实践

### 1. 密码安全

```bash
# 生产环境密码配置示例
# conf/postgres.env
POSTGRES_PASSWORD=your_very_strong_password_here

# conf/pulsar-manager.env  
PULSAR_MANAGER_ADMIN_PASSWORD=your_manager_admin_password
```

### 2. JWT密钥安全

```bash
# 定期轮换JWT密钥
./scripts/generate-jwt.sh

# 重启相关服务
docker-compose restart broker pulsar-manager
```

### 3. 网络安全

```bash
# 生产环境网络配置
# 修改 broker.env
advertisedListeners=external:pulsar://your-domain.com:6650

# 修改 pulsar-manager.env
ENV_REDIRECT_HOST=your-domain.com
```

## 📈 性能调优配置

### 高吞吐量配置

```bash
# broker.env - 高吞吐量配置
maxConcurrentLookupRequest=50000
maxConcurrentTopicLoadRequest=5000
maxUnackedMessagesPerConsumer=50000
maxUnackedMessagesPerSubscription=200000

# bookkeeper.env - 高性能配置
BOOKIE_MEM=-Xms2g -Xmx2g -XX:MaxDirectMemorySize=2g
journalSyncData=false
flushInterval=100
```

### 低延迟配置

```bash
# broker.env - 低延迟配置
dispatcherMaxRoundRobinBatchSize=1
maxPublishRatePerTopicInMessages=0
maxPublishRatePerTopicInBytes=0
```

## 🛡️ 备份和恢复

### 配置备份

```bash
# 备份所有配置
tar -czf pulsar-config-backup-$(date +%Y%m%d).tar.gz conf/

# 恢复配置
tar -xzf pulsar-config-backup-YYYYMMDD.tar.gz
```

### 配置版本控制

建议将配置文件（除敏感信息外）纳入版本控制：

```bash
# 添加配置到git（排除敏感文件）
git add conf/*.env
git add conf/README.md
git commit -m "Add Pulsar configuration files"

# 注意：jwt/ 目录已在.gitignore中排除
```

---

**提示**: 修改任何配置后，请重启相应的服务以使配置生效。
