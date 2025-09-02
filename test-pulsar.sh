#!/bin/bash

echo "=== Testing Pulsar Messaging ==="
echo

# 测试 Pulsar Broker API 健康状况
echo "1. Testing Broker Health..."
curl -s http://localhost:8081/admin/v2/brokers/health
echo
echo

# 创建一个测试 Topic
echo "2. Creating test topic..."
docker exec -it broker bin/pulsar-admin topics create persistent://public/default/test-topic

echo

# 查看 Topic 列表
echo "3. Listing topics..."
docker exec -it broker bin/pulsar-admin topics list public/default

echo

echo "4. Testing message production and consumption..."
echo "This will run producer and consumer in the background."
echo

# 在后台运行消费者
echo "Starting consumer..."
docker exec -d broker bin/pulsar-client consume persistent://public/default/test-topic \
    --subscription my-subscription \
    --num-messages 0

sleep 2

# 发送测试消息
echo "Sending test messages..."
docker exec -it broker bin/pulsar-client produce persistent://public/default/test-topic \
    --messages "Hello from Pulsar Docker Compose setup! Message 1" \
    --messages "Hello from Pulsar Docker Compose setup! Message 2" \
    --messages "Hello from Pulsar Docker Compose setup! Message 3"

echo
echo "=== Test Complete ==="
echo "If you see messages above, Pulsar is working correctly!"
echo
echo "Access points:"
echo "- Pulsar Broker: http://localhost:8081"
echo "- Pulsar Manager: http://localhost:9527 (admin/apachepulsar)"
echo "- Broker Service: pulsar://localhost:6650"
