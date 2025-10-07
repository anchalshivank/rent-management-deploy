#!/bin/bash
set -e

echo "🚀 Starting Rent Management System Deployment..."

sudo chmod -R 777 logs/


# Check if repos exist, if not clone them
if [ ! -d "../frontend" ]; then
    echo "📦 Cloning frontend..."
    cd .. && git clone https://github.com/anchalshivank/frontend.git
    cd rent-management-deploy
fi

if [ ! -d "../backend" ]; then
    mkdir -p ../backend
fi

if [ ! -d "../backend/auth-service" ]; then
    echo "📦 Cloning auth-service..."
    cd ../backend && git clone https://github.com/anchalshivank/auth-service.git
    cd ../rent-management-deploy
fi

if [ ! -d "../backend/user-service" ]; then
    echo "📦 Cloning user-service..."
    cd ../backend && git clone https://github.com/anchalshivank/user-service.git
    cd ../rent-management-deploy
fi

if [ ! -d "../backend/notification-service" ]; then
    echo "📦 Cloning notification-service..."
    cd ../backend && git clone https://github.com/anchalshivank/notification-service.git
    cd ../rent-management-deploy
fi

# Create .env if not exists
if [ ! -f ".env" ]; then
    echo "📝 Creating .env file..."
    cat > .env << 'EOF'
# Database Passwords
AUTH_DB_PASSWORD=auth123
USER_DB_PASSWORD=user123
NOTIFICATION_DB_PASSWORD=notification123
KEYCLOAK_DB_PASSWORD=keycloak123

# Keycloak Configuration
KEYCLOAK_ADMIN_USER=anchalshivank
KEYCLOAK_AUTH_SERVER_URL=http://keycloak:8080
KEYCLOAK_ADMIN_PASSWORD=admin123
KEYCLOAK_REALM=rent-management
KEYCLOAK_CLIENT_SECRET=your-secret
KEYCLOAK_CLIENT_ID=rent-auth-service
AUTH_SERVER_URL=http://localhost:8081
NODE_ENV=development

# Application Configuration
ENVIRONMENT=local
EOF
fi

# Build and start
echo "🐳 Building and starting containers..."
docker-compose up --build -d

echo "✅ Deployment complete!"
echo "📊 Grafana: http://localhost:3000 (admin/admin)"
echo "🔐 Keycloak: http://localhost:8080"
echo "🌐 Frontend: http://localhost:3031"
echo "🔑 Auth Service: http://localhost:8081"