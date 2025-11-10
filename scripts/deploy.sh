#!/bin/bash

# Open Alpha Arena 部署脚本
# 
# 用途：简化 Fly.io 和 Vercel 的部署流程
# 
# 使用方法：
#   ./scripts/deploy.sh [--backend] [--frontend] [--all]
#
# 选项：
#   --backend   只部署后端到 Fly.io
#   --frontend  只部署前端到 Vercel
#   --all       部署前后端（默认）
#
# 详细部署文档请参考：doc/deployment-guide.md

set -e

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# 默认配置
DEPLOY_BACKEND=false
DEPLOY_FRONTEND=false
FLY_APP_NAME="open-alpha-arena"

# 解析命令行参数
if [ $# -eq 0 ]; then
    DEPLOY_BACKEND=true
    DEPLOY_FRONTEND=true
else
    for arg in "$@"; do
        case $arg in
            --backend)
                DEPLOY_BACKEND=true
                ;;
            --frontend)
                DEPLOY_FRONTEND=true
                ;;
            --all)
                DEPLOY_BACKEND=true
                DEPLOY_FRONTEND=true
                ;;
            --help|-h)
                echo "用法: $0 [--backend] [--frontend] [--all]"
                echo ""
                echo "选项："
                echo "  --backend   只部署后端到 Fly.io"
                echo "  --frontend  只部署前端到 Vercel"
                echo "  --all       部署前后端（默认）"
                echo "  --help      显示此帮助信息"
                echo ""
                echo "详细文档: doc/deployment-guide.md"
                exit 0
                ;;
            *)
                echo -e "${RED}未知选项: $arg${NC}"
                echo "使用 --help 查看帮助"
                exit 1
                ;;
        esac
    done
fi

echo -e "${BLUE}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  🚀 Open Alpha Arena 部署脚本"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${NC}"
echo ""

# 检查必要的工具
check_tools() {
    local missing=false
    
    if [ "$DEPLOY_BACKEND" = true ]; then
        if ! command -v fly &> /dev/null; then
            echo -e "${RED}❌ fly CLI 未安装${NC}"
            echo "   安装: https://fly.io/docs/getting-started/installing-flyctl/"
            missing=true
        fi
    fi
    
    if [ "$DEPLOY_FRONTEND" = true ]; then
        if ! command -v vercel &> /dev/null; then
            echo -e "${RED}❌ vercel CLI 未安装${NC}"
            echo "   安装: npm i -g vercel"
            missing=true
        fi
    fi
    
    if [ "$missing" = true ]; then
        exit 1
    fi
}

# 部署后端
deploy_backend() {
    echo -e "${YELLOW}📦 部署后端到 Fly.io${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    echo "正在部署..."
    fly deploy --app "$FLY_APP_NAME"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ 后端部署成功${NC}"
        echo ""
        
        # 健康检查
        echo "检查后端状态..."
        sleep 5
        
        HEALTH=$(curl -s "https://${FLY_APP_NAME}.fly.dev/api/health" || echo "")
        if echo "$HEALTH" | grep -q "healthy"; then
            echo -e "${GREEN}✅ 后端健康检查通过${NC}"
        else
            echo -e "${YELLOW}⚠️  后端可能未就绪，请检查日志: fly logs --app $FLY_APP_NAME${NC}"
        fi
    else
        echo -e "${RED}❌ 后端部署失败${NC}"
        return 1
    fi
    echo ""
}

# 部署前端
deploy_frontend() {
    echo -e "${YELLOW}🌐 部署前端到 Vercel${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    # 检查是否已登录
    if ! vercel whoami &>/dev/null; then
        echo -e "${YELLOW}⚠️  请先登录 Vercel${NC}"
        echo "运行: vercel login"
        return 1
    fi
    
    echo "正在部署..."
    vercel --prod
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ 前端部署成功${NC}"
    else
        echo -e "${RED}❌ 前端部署失败${NC}"
        return 1
    fi
    echo ""
}

# 主流程
main() {
    check_tools
    
    local failed=false
    
    if [ "$DEPLOY_BACKEND" = true ]; then
        deploy_backend || failed=true
    fi
    
    if [ "$DEPLOY_FRONTEND" = true ]; then
        deploy_frontend || failed=true
    fi
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    if [ "$failed" = false ]; then
        echo -e "${GREEN}🎉 部署完成！${NC}"
    else
        echo -e "${YELLOW}⚠️  部署完成，但有错误${NC}"
    fi
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "📝 有用的命令："
    echo ""
    if [ "$DEPLOY_BACKEND" = true ]; then
        echo "  查看后端日志:    fly logs --app $FLY_APP_NAME"
        echo "  查看后端状态:    fly status --app $FLY_APP_NAME"
        echo "  后端健康检查:    curl https://${FLY_APP_NAME}.fly.dev/api/health"
        echo ""
    fi
    if [ "$DEPLOY_FRONTEND" = true ]; then
        echo "  查看 Vercel 部署: vercel ls"
        echo "  查看 Vercel 日志: vercel logs"
        echo ""
    fi
    echo "  详细文档:        doc/deployment-guide.md"
    echo ""
}

main

