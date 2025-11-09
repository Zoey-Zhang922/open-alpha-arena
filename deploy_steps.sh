#!/bin/bash

# 部署步骤脚本
# 使用方法: SUPABASE_PASSWORD="your_password" ./deploy_steps.sh
# 或者: ./deploy_steps.sh (会提示输入密码)

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo "============================================================"
echo "🚀 Open Alpha Arena 部署脚本"
echo "============================================================"
echo ""

# 步骤 1: 获取密码并设置环境变量
echo "📝 步骤 1: 配置 Fly.io 环境变量"
echo "------------------------------------------------------------"

if [ -z "$SUPABASE_PASSWORD" ]; then
    echo "从 Supabase Dashboard 获取数据库连接字符串"
    echo "项目 ID: swizelkwjawvnvekxoff"
    echo ""
    read -sp "请输入 Supabase 数据库密码: " SUPABASE_PASSWORD
    echo ""
    echo ""
fi

if [ -z "$SUPABASE_PASSWORD" ]; then
    echo -e "${RED}❌ 密码不能为空${NC}"
    exit 1
fi

DATABASE_URL="postgresql://postgres:${SUPABASE_PASSWORD}@db.swizelkwjawvnvekxoff.supabase.co:5432/postgres"

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

fly ssh console --app open-alpha-arena -C "cd /app && uv run python -c \"from database.connection import Base, engine; Base.metadata.create_all(bind=engine); print('✅ 数据库表创建成功')\""

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

# 检查是否已登录 Vercel
if vercel whoami &>/dev/null; then
    echo "正在部署到 Vercel..."
    vercel --prod
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Vercel 部署成功${NC}"
    else
        echo -e "${YELLOW}⚠️  Vercel 部署可能需要手动确认${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  未检测到 Vercel 登录${NC}"
    echo "请先运行: vercel login"
    echo "然后运行: vercel --prod"
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

