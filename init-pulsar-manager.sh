#!/bin/bash

# Wait for PostgreSQL to be ready
echo "Waiting for PostgreSQL to be ready..."
while ! docker exec pulsar-postgres pg_isready -U pulsar > /dev/null 2>&1; do
    echo "PostgreSQL is unavailable - sleeping"
    sleep 3
done
echo "PostgreSQL is ready!"

# Wait for Pulsar Manager to be ready
echo "Waiting for Pulsar Manager to start..."
sleep 45

# Check if admin user already exists
echo "Checking if admin user already exists..."
CSRF_TOKEN=$(curl -s http://localhost:9527/pulsar-manager/csrf-token)
USER_EXISTS=$(curl -s -H "X-XSRF-TOKEN: $CSRF_TOKEN" -H "Cookie: XSRF-TOKEN=$CSRF_TOKEN;" http://localhost:9527/pulsar-manager/users/superuser)

if [[ "$USER_EXISTS" == *"not found"* ]] || [[ "$USER_EXISTS" == ""* ]]; then
    echo "Creating initial superuser for Pulsar Manager..."
    curl -s \
        -H "X-XSRF-TOKEN: $CSRF_TOKEN" \
        -H "Cookie: XSRF-TOKEN=$CSRF_TOKEN;" \
        -H "Content-Type: application/json" \
        -X PUT http://localhost:9527/pulsar-manager/users/superuser \
        -d '{"name": "admin", "password": "pulsar@123", "description": "Administrator", "email": "admin@pulsar.local"}'
    echo ""
    echo "✅ Pulsar Manager superuser created successfully!"
else
    echo "✅ Admin user already exists, skipping creation."
fi

echo ""
echo "🎉 Pulsar Manager initialization completed!"
echo "📱 Access: http://localhost:9527"
echo "🔑 Credentials: admin / pulsar@123"
echo "💾 User data is now persistent in PostgreSQL database"
