# Apache Pulsar 完整部署指南

这是一个基于Docker Compose的Apache Pulsar完整集群部署方案，包含JWT认证、Pulsar Manager管理界面和密码持久化。

## 📋 功能特性

- ✅ **完整Pulsar集群**: ZooKeeper + BookKeeper + Broker
- ✅ **JWT认证**: 安全的Token认证机制
- ✅ **Pulsar Manager**: Web管理界面
- ✅ **密码持久化**: 用户数据持久化存储
- ✅ **配置外置**: 所有配置参数可独立修改
- ✅ **一键部署**: 自动化安装和初始化脚本

## 📁 项目结构

```
pulsar/
├── docker-compose.yml          # Docker编排配置
├── setup.sh                    # 一键部署脚本
├── README.md                   # 本文档
├── conf/                       # 配置文件目录
│   ├── zookeeper.env          # ZooKeeper配置
│   ├── bookkeeper.env         # BookKeeper配置
│   ├── broker.env             # Broker基础配置
│   ├── postgres.env           # PostgreSQL配置
│   ├── pulsar-manager.env     # Pulsar Manager配置
│   ├── cluster-init.env       # 集群初始化配置
│   ├── jwt-auth.env           # JWT认证配置（自动生成）
│   └── jwt/                   # JWT密钥目录（自动生成）
│       ├── secret.key         # JWT密钥文件
│       └── jwt.env            # JWT环境变量
├── scripts/                    # 脚本目录
│   ├── generate-jwt.sh        # JWT生成脚本
│   └── init-pulsar-manager.sh # Manager初始化脚本
├── data/                       # 数据持久化目录
│   ├── zookeeper/             # ZooKeeper数据
│   ├── bookkeeper/            # BookKeeper数据
│   ├── postgres/              # PostgreSQL数据
│   └── pulsar-manager/        # Manager数据（HerdDB）
└── logs/                       # 日志目录
```

## 🚀 快速开始

### 前提条件

- Docker >= 20.10
- Docker Compose >= 2.0
- Python 3.x（用于JWT生成）
- curl（用于API测试）

### 一键部署

```bash
# 克隆或下载项目到本地
cd pulsar

# 运行一键部署脚本
./setup.sh
```

### 手动分步部署

如果需要手动控制部署过程：

#### 1. 生成JWT认证密钥

```bash
# 生成JWT密钥和Token
./scripts/generate-jwt.sh
```

#### 2. 启动服务

```bash
# 按顺序启动服务
docker-compose up -d zookeeper
sleep 30

docker-compose up -d pulsar-init  
sleep 15

docker-compose up -d bookie
sleep 30

docker-compose up -d broker
sleep 30

docker-compose up -d postgres
sleep 15

docker-compose up -d pulsar-manager
sleep 45
```

#### 3. 初始化Pulsar Manager

```bash
# 创建管理员用户
./scripts/init-pulsar-manager.sh
```

## 🔐 JWT认证配置

### JWT密钥生成

JWT认证使用自动生成的密钥，确保安全性：

```bash
# 手动重新生成JWT密钥（可选）
./scripts/generate-jwt.sh
```

生成的文件：
- `conf/jwt/secret.key`: JWT密钥文件
- `conf/jwt/jwt.env`: JWT环境变量
- `conf/jwt-auth.env`: Broker认证配置

### Token使用

生成的Token可用于客户端连接：

```bash
# 查看生成的Token
cat conf/jwt/jwt.env

# 使用Token连接示例
pulsar-client --url pulsar://localhost:6650 --auth-plugin org.apache.pulsar.client.impl.auth.AuthenticationToken --auth-params token:YOUR_TOKEN_HERE
```

## 🎛️ 服务配置

所有服务配置都已外置到`conf/`目录，便于修改：

### ZooKeeper 配置 (`conf/zookeeper.env`)
```bash
metadataStoreUrl=zk:zookeeper:2181
PULSAR_MEM=-Xms256m -Xmx256m -XX:MaxDirectMemorySize=256m
```

### BookKeeper 配置 (`conf/bookkeeper.env`)
```bash
clusterName=cluster-a
zkServers=zookeeper:2181
advertisedAddress=bookie
BOOKIE_MEM=-Xms512m -Xmx512m -XX:MaxDirectMemorySize=256m
```

### Broker 配置 (`conf/broker.env`)
```bash
metadataStoreUrl=zk:zookeeper:2181
clusterName=cluster-a
advertisedAddress=broker
PULSAR_MEM=-Xms512m -Xmx512m -XX:MaxDirectMemorySize=256m
```

### PostgreSQL 配置 (`conf/postgres.env`)
```bash
POSTGRES_DB=pulsar_manager
POSTGRES_USER=pulsar
POSTGRES_PASSWORD=pulsar123
```

### Pulsar Manager 配置 (`conf/pulsar-manager.env`)
```bash
ENV_REDIRECT_HOST=localhost
ENV_REDIRECT_PORT=9527
PULSAR_MANAGER_ADMIN_USER=admin
PULSAR_MANAGER_ADMIN_PASSWORD=pulsar@123
```

## 💾 密码持久化说明

### Pulsar Manager 数据持久化

- **存储方式**: HerdDB内嵌数据库
- **数据目录**: `./data/pulsar-manager/`
- **持久化内容**: 用户账户、密码、集群配置
- **重启保持**: 容器重启后数据不会丢失

### PostgreSQL 数据持久化（备选方案）

虽然当前版本的Pulsar Manager默认使用HerdDB，但PostgreSQL配置已准备就绪：

- **数据库**: pulsar_manager
- **用户**: pulsar
- **密码**: pulsar123
- **端口**: 5432

## 🌐 服务访问

### 端口映射

| 服务 | 端口 | 协议 | 说明 |
|------|------|------|------|
| Pulsar Broker | 6650 | pulsar:// | 客户端连接端口 |
| Pulsar Broker HTTP | 8081 | HTTP | Admin API端口 |
| Pulsar Manager | 9527 | HTTP | Web管理界面 |
| PostgreSQL | 5432 | TCP | 数据库连接端口 |

### 默认凭据

| 服务 | 用户名 | 密码 |
|------|--------|---------|
| Pulsar Manager | admin | pulsar@123 |
| PostgreSQL | pulsar | pulsar123 |

## 🔧 Pulsar Manager 配置

### 首次登录配置

1. 访问 http://localhost:9527
2. 使用 `admin` / `pulsar@123` 登录
3. 添加集群配置：
   - **Cluster Name**: cluster-a
   - **Service URL**: http://broker:8080
   - **Bookie URL**: http://broker:8080  
   - **Broker URL**: pulsar://broker:6650

### 密码持久化验证

```bash
# 检查持久化数据
ls -la data/pulsar-manager/

# 重启服务测试持久化
docker-compose restart pulsar-manager
sleep 30

# 验证用户仍然存在
curl -s http://localhost:9527
```

## 🛠️ 常用运维命令

### 服务管理

```bash
# 查看服务状态
docker-compose ps

# 查看所有日志
docker-compose logs

# 查看特定服务日志
docker-compose logs broker
docker-compose logs pulsar-manager

# 重启特定服务
docker-compose restart broker

# 停止所有服务
docker-compose down

# 停止并删除数据卷
docker-compose down -v
```

### 配置修改

```bash
# 修改Broker配置
vim conf/broker.env

# 修改JWT认证配置
vim conf/jwt-auth.env

# 重启相关服务使配置生效
docker-compose restart broker
```

### 数据管理

```bash
# 备份数据目录
tar -czf pulsar-backup-$(date +%Y%m%d).tar.gz data/

# 清理所有数据（谨慎操作）
docker-compose down -v
rm -rf data/
```

## 🧪 测试连接

### 测试Pulsar功能

```bash
# 进入broker容器
docker exec -it broker bash

# 创建topic
bin/pulsar-admin topics create persistent://public/default/test-topic

# 发送消息
bin/pulsar-client produce persistent://public/default/test-topic --messages "Hello Pulsar"

# 消费消息
bin/pulsar-client consume persistent://public/default/test-topic --subscription my-subscription
```

### 测试JWT认证

```bash
# 获取管理员Token
ADMIN_TOKEN=$(grep ADMIN_JWT_TOKEN conf/jwt/jwt.env | cut -d'=' -f2)

# 使用Token访问Admin API
curl -H "Authorization: Bearer $ADMIN_TOKEN" http://localhost:8081/admin/v2/clusters
```

## 🔍 故障排除

### 常见问题

#### 1. Pulsar Manager无法启动
```bash
# 检查日志
docker-compose logs pulsar-manager

# 常见原因：环境变量配置错误
# 解决：检查conf/pulsar-manager.env配置
```

#### 2. JWT认证失败
```bash
# 重新生成JWT密钥
./scripts/generate-jwt.sh

# 重启broker服务
docker-compose restart broker
```

#### 3. 密码丢失问题
```bash
# 检查持久化数据
ls -la data/pulsar-manager/

# 重新初始化管理员用户
./scripts/init-pulsar-manager.sh
```

#### 4. 服务启动失败
```bash
# 检查端口占用
netstat -tlnp | grep -E '(6650|8081|9527|5432)'

# 检查Docker资源
docker system df
docker system prune  # 清理无用资源
```

### 日志位置

```bash
# Pulsar Manager应用日志
docker exec pulsar-manager tail -f /pulsar-manager/pulsar-manager/pulsar-manager.log

# PostgreSQL日志
docker-compose logs postgres

# Broker日志
docker-compose logs broker
```

## 📊 性能优化

### 内存配置

根据服务器资源调整`conf/`目录下各组件的内存配置：

```bash
# broker.env
PULSAR_MEM=-Xms1g -Xmx1g -XX:MaxDirectMemorySize=1g

# bookkeeper.env  
BOOKIE_MEM=-Xms1g -Xmx1g -XX:MaxDirectMemorySize=1g

# zookeeper.env
PULSAR_MEM=-Xms512m -Xmx512m -XX:MaxDirectMemorySize=512m
```

### 数据目录优化

```bash
# 将数据目录挂载到SSD
# 修改docker-compose.yml中的volume映射
- /fast/ssd/path:/pulsar/data/bookkeeper
```

## 🔒 安全建议

### 生产环境安全配置

1. **更改默认密码**：
   ```bash
   # 修改conf/pulsar-manager.env
   PULSAR_MANAGER_ADMIN_PASSWORD=your_strong_password
   
   # 修改conf/postgres.env
   POSTGRES_PASSWORD=your_db_password
   ```

2. **限制网络访问**：
   ```bash
   # 移除不必要的端口映射
   # 使用防火墙限制访问
   ```

3. **定期轮换JWT密钥**：
   ```bash
   # 重新生成JWT密钥
   ./scripts/generate-jwt.sh
   docker-compose restart broker
   ```

## 🆙 升级指南

### 升级Pulsar版本

```bash
# 1. 停止服务
docker-compose down

# 2. 备份数据
tar -czf backup-$(date +%Y%m%d).tar.gz data/

# 3. 修改docker-compose.yml中的镜像版本
# 4. 重新启动
./setup.sh
```

### 升级Pulsar Manager

```bash
# 修改docker-compose.yml中的pulsar-manager镜像版本
docker-compose up -d pulsar-manager
```

## 📚 参考资料

- [Apache Pulsar官方文档](https://pulsar.apache.org/docs/)
- [Pulsar Manager文档](https://github.com/apache/pulsar-manager)
- [Docker Compose文档](https://docs.docker.com/compose/)
- [JWT认证配置](https://pulsar.apache.org/docs/security-jwt/)

## 💡 最佳实践

1. **定期备份数据目录**
2. **监控服务健康状态** 
3. **定期查看日志文件**
4. **在生产环境中使用外部存储**
5. **配置适当的资源限制**

---

**创建时间**: 2025-09-02  
**版本**: v1.0  
**支持**: Apache Pulsar 2.x + Pulsar Manager v0.4.0
