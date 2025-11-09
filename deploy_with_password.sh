#!/bin/bash

# 使用密码直接部署
# 使用方法: ./deploy_with_password.sh "your_supabase_password"

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

if [ -z "$1" ]; then
    echo -e "${RED}❌ 请提供 Supabase 数据库密码作为参数${NC}"
    echo "使用方法: ./deploy_with_password.sh \"your_password\""
    exit 1
fi

SUPABASE_PASSWORD="$1"
DATABASE_URL="postgresql://postgres:${SUPABASE_PASSWORD}@db.swizelkwjawvnvekxoff.supabase.co:5432/postgres"

echo "============================================================"
echo "🚀 Open Alpha Arena 部署脚本"
echo "============================================================"
echo ""

# 步骤 1: 设置环境变量
echo "📝 步骤 1: 配置 Fly.io 环境变量"
echo "------------------------------------------------------------"
echo "设置 DATABASE_URL 环境变量到 Fly.io..."
fly secrets set DATABASE_URL="$DATABASE_URL" --app open-alpha-arena

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ 环境变量设置成功${NC}"
else
    echo -e "${RED}❌ 环境变量设置失败${NC}"
    exit 1
fi
echo ""

# 步骤 2: 重新部署 Fly.io
echo "📦 步骤 2: 重新部署 Fly.io 应用"
echo "------------------------------------------------------------"
echo "正在部署到 Fly.io（这可能需要几分钟）..."
fly deploy --app open-alpha-arena

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Fly.io 部署成功${NC}"
else
    echo -e "${RED}❌ Fly.io 部署失败${NC}"
    exit 1
fi
echo ""

# 等待应用启动
echo "⏳ 等待应用启动（30秒）..."
sleep 30
echo ""

# 步骤 3: 初始化数据库
echo "🗄️  步骤 3: 初始化 Supabase 数据库表结构"
echo "------------------------------------------------------------"
echo "正在通过 Fly.io SSH 初始化数据库..."

# 说明：fly ssh 的 -C 选项不执行 shell 内建命令（如 cd），需通过 /bin/sh -lc 包裹
# 使用 /bin/sh -lc 进入 /app 目录后执行 uv 的 Python 片段
fly ssh console --app open-alpha-arena -C "/bin/sh -lc 'cd /app && uv run python -c \"from database.connection import Base, engine; Base.metadata.create_all(bind=engine); print(\\\"✅ 数据库表创建成功\\\")\"'"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ 数据库初始化成功${NC}"
else
    echo -e "${YELLOW}⚠️  数据库初始化可能失败，请检查 Fly.io 日志: fly logs${NC}"
fi
echo ""

# 步骤 4: 验证后端
echo "✅ 步骤 4: 验证后端部署"
echo "------------------------------------------------------------"
echo "检查后端健康状态..."

for i in {1..10}; do
    HEALTH_RESPONSE=$(curl -s https://open-alpha-arena.fly.dev/api/health 2>/dev/null || echo "")
    if [ ! -z "$HEALTH_RESPONSE" ] && echo "$HEALTH_RESPONSE" | grep -q "healthy"; then
        echo -e "${GREEN}✅ 后端健康检查通过${NC}"
        echo "   响应: $HEALTH_RESPONSE"
        break
    else
        if [ $i -lt 10 ]; then
            echo "等待后端启动... (尝试 $i/10)"
            sleep 5
        else
            echo -e "${YELLOW}⚠️  后端健康检查失败，请检查: fly logs${NC}"
        fi
    fi
done
echo ""

# 步骤 5: 部署 Vercel
echo "🌐 步骤 5: 部署前端到 Vercel"
echo "------------------------------------------------------------"
echo "正在部署到 Vercel..."
vercel --prod

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Vercel 部署成功${NC}"
else
    echo -e "${YELLOW}⚠️  Vercel 部署可能需要手动确认${NC}"
fi
echo ""

# 完成
echo "============================================================"
echo -e "${GREEN}🎉 部署流程完成！${NC}"
echo "============================================================"
echo ""
echo "📝 后续检查："
echo "  1. 检查 Fly.io 日志: fly logs"
echo "  2. 访问后端 API: https://open-alpha-arena.fly.dev/api/health"
echo "  3. 检查 Vercel 部署: vercel ls"
echo ""

