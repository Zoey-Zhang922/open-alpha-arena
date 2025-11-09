#!/bin/bash

# 部署脚本 - Open Alpha Arena
# 此脚本帮助完成 Fly.io 和 Vercel 的部署

set -e

echo "🚀 Open Alpha Arena 部署脚本"
echo "================================"
echo ""

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# 检查必要的工具
echo "📋 检查必要的工具..."
if ! command -v fly &> /dev/null; then
    echo -e "${RED}❌ fly CLI 未安装。请先安装: https://fly.io/docs/getting-started/installing-flyctl/${NC}"
    exit 1
fi

if ! command -v vercel &> /dev/null; then
    echo -e "${RED}❌ vercel CLI 未安装。请先安装: npm i -g vercel${NC}"
    exit 1
fi

echo -e "${GREEN}✅ 所有工具已安装${NC}"
echo ""

# 步骤 1: 设置 Fly.io 环境变量
echo "📝 步骤 1: 设置 Fly.io 环境变量"
echo "--------------------------------"
echo ""
echo "从 Supabase Dashboard 获取数据库连接字符串："
echo "  - 项目 ID: swizelkwjawvnvekxoff"
echo "  - 连接字符串格式: postgresql://postgres:[PASSWORD]@db.swizelkwjawvnvekxoff.supabase.co:5432/postgres"
echo ""
read -sp "请输入 Supabase 数据库密码: " SUPABASE_PASSWORD
echo ""
echo ""

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
echo "--------------------------------"
echo ""
read -p "是否现在部署到 Fly.io? (y/n): " DEPLOY_FLY
if [ "$DEPLOY_FLY" = "y" ] || [ "$DEPLOY_FLY" = "Y" ]; then
    echo "正在部署..."
    fly deploy --app open-alpha-arena
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Fly.io 部署成功${NC}"
    else
        echo -e "${RED}❌ Fly.io 部署失败${NC}"
        exit 1
    fi
else
    echo "跳过 Fly.io 部署，您可以稍后运行: fly deploy"
fi
echo ""

# 步骤 3: 初始化数据库
echo "🗄️  步骤 3: 初始化 Supabase 数据库表结构"
echo "--------------------------------"
echo ""
read -p "是否现在初始化数据库表? (y/n): " INIT_DB
if [ "$INIT_DB" = "y" ] || [ "$INIT_DB" = "Y" ]; then
    echo "正在通过 Fly.io SSH 初始化数据库..."
    
    # 通过 Fly.io SSH 执行数据库初始化
    fly ssh console --app open-alpha-arena -C "cd /app && uv run python -c \"from database.connection import Base, engine; Base.metadata.create_all(bind=engine); print('数据库表创建成功')\""
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ 数据库初始化成功${NC}"
    else
        echo -e "${YELLOW}⚠️  数据库初始化可能失败，请检查 Fly.io 日志: fly logs${NC}"
    fi
else
    echo "跳过数据库初始化，您可以稍后运行:"
    echo "  fly ssh console --app open-alpha-arena -C \"cd /app && uv run python -c 'from database.connection import Base, engine; Base.metadata.create_all(bind=engine)'\""
fi
echo ""

# 步骤 4: 部署 Vercel
echo "🌐 步骤 4: 部署前端到 Vercel"
echo "--------------------------------"
echo ""
read -p "是否现在部署到 Vercel? (y/n): " DEPLOY_VERCEL
if [ "$DEPLOY_VERCEL" = "y" ] || [ "$DEPLOY_VERCEL" = "Y" ]; then
    echo "正在部署到 Vercel..."
    vercel --prod
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Vercel 部署成功${NC}"
    else
        echo -e "${YELLOW}⚠️  Vercel 部署可能需要登录，请运行: vercel login${NC}"
    fi
else
    echo "跳过 Vercel 部署，您可以稍后运行: vercel --prod"
fi
echo ""

# 步骤 5: 验证部署
echo "✅ 步骤 5: 验证部署"
echo "--------------------------------"
echo ""
echo "检查后端健康状态..."
HEALTH_CHECK=$(curl -s https://open-alpha-arena.fly.dev/api/health || echo "failed")

if echo "$HEALTH_CHECK" | grep -q "healthy"; then
    echo -e "${GREEN}✅ 后端健康检查通过${NC}"
    echo "   响应: $HEALTH_CHECK"
else
    echo -e "${YELLOW}⚠️  后端健康检查失败，请检查: fly logs${NC}"
fi
echo ""

echo -e "${GREEN}🎉 部署流程完成！${NC}"
echo ""
echo "📝 后续步骤："
echo "  1. 检查 Fly.io 日志: fly logs"
echo "  2. 访问后端 API: https://open-alpha-arena.fly.dev/api/health"
echo "  3. 访问 Vercel 前端（部署后会显示 URL）"
echo ""

