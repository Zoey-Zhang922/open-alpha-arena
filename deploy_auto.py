#!/usr/bin/env python3
"""
自动部署脚本 - Open Alpha Arena
执行所有部署步骤直到验证完成
"""

import subprocess
import sys
import getpass
import time
import json

def run_cmd(cmd, check=True, capture_output=False):
    """执行命令并返回结果"""
    print(f"🔧 执行: {cmd}")
    try:
        result = subprocess.run(
            cmd,
            shell=True,
            check=check,
            capture_output=capture_output,
            text=True
        )
        if capture_output:
            return result.stdout.strip()
        return True
    except subprocess.CalledProcessError as e:
        print(f"❌ 命令执行失败: {e}")
        if capture_output and e.stdout:
            print(f"输出: {e.stdout}")
        if capture_output and e.stderr:
            print(f"错误: {e.stderr}")
        return False

def check_backend_health(max_retries=10, delay=5):
    """检查后端健康状态"""
    url = "https://open-alpha-arena.fly.dev/api/health"
    print(f"🏥 检查后端健康状态: {url}")
    
    for i in range(max_retries):
        try:
            result = run_cmd(f'curl -s -f "{url}"', check=False, capture_output=True)
            if result:
                try:
                    data = json.loads(result)
                    if data.get("status") == "healthy":
                        print(f"✅ 后端健康检查通过: {data}")
                        return True
                    else:
                        print(f"⚠️  后端状态: {data}")
                except json.JSONDecodeError:
                    print(f"⚠️  响应不是有效的 JSON: {result}")
            else:
                print(f"⚠️  连接失败 (尝试 {i+1}/{max_retries})")
        except Exception as e:
            print(f"⚠️  检查失败 (尝试 {i+1}/{max_retries}): {e}")
        
        if i < max_retries - 1:
            print(f"等待 {delay} 秒后重试...")
            time.sleep(delay)
    
    print("❌ 后端健康检查失败")
    return False

def main():
    print("=" * 60)
    print("🚀 Open Alpha Arena 自动部署脚本")
    print("=" * 60)
    print()
    
    # 步骤 1: 获取 Supabase 密码
    print("📝 步骤 1: 配置 Fly.io 环境变量")
    print("-" * 60)
    print("从 Supabase Dashboard 获取数据库连接字符串")
    print("项目 ID: swizelkwjawvnvekxoff")
    print("连接字符串格式: postgresql://postgres:[PASSWORD]@db.swizelkwjawvnvekxoff.supabase.co:5432/postgres")
    print()
    
    password = getpass.getpass("请输入 Supabase 数据库密码: ")
    if not password:
        print("❌ 密码不能为空")
        sys.exit(1)
    
    database_url = f"postgresql://postgres:{password}@db.swizelkwjawvnvekxoff.supabase.co:5432/postgres"
    
    print("设置 DATABASE_URL 环境变量到 Fly.io...")
    if not run_cmd(f'fly secrets set DATABASE_URL="{database_url}" --app open-alpha-arena'):
        print("❌ 环境变量设置失败")
        sys.exit(1)
    
    print("✅ 环境变量设置成功")
    print()
    
    # 步骤 2: 重新部署 Fly.io
    print("📦 步骤 2: 重新部署 Fly.io 应用")
    print("-" * 60)
    print("正在部署到 Fly.io（这可能需要几分钟）...")
    if not run_cmd("fly deploy --app open-alpha-arena"):
        print("❌ Fly.io 部署失败")
        sys.exit(1)
    
    print("✅ Fly.io 部署成功")
    print()
    
    # 等待应用启动
    print("⏳ 等待应用启动...")
    time.sleep(10)
    
    # 步骤 3: 初始化数据库
    print("🗄️  步骤 3: 初始化 Supabase 数据库表结构")
    print("-" * 60)
    print("正在通过 Fly.io SSH 初始化数据库...")
    
    init_cmd = '''fly ssh console --app open-alpha-arena -C "cd /app && uv run python -c \\"from database.connection import Base, engine; Base.metadata.create_all(bind=engine); print('✅ 数据库表创建成功')\\""
'''
    if not run_cmd(init_cmd):
        print("⚠️  数据库初始化可能失败，请检查 Fly.io 日志")
        print("您可以稍后手动运行:")
        print("  fly ssh console --app open-alpha-arena -C \"cd /app && uv run python -c 'from database.connection import Base, engine; Base.metadata.create_all(bind=engine)'\"")
    else:
        print("✅ 数据库初始化成功")
    print()
    
    # 步骤 4: 验证后端
    print("✅ 步骤 4: 验证后端部署")
    print("-" * 60)
    if check_backend_health():
        print("✅ 后端验证通过")
    else:
        print("⚠️  后端验证失败，请检查: fly logs")
    print()
    
    # 步骤 5: 部署 Vercel
    print("🌐 步骤 5: 部署前端到 Vercel")
    print("-" * 60)
    print("正在部署到 Vercel...")
    print("（如果未登录，请先运行: vercel login）")
    
    # 检查是否已登录 Vercel
    vercel_check = run_cmd("vercel whoami", check=False, capture_output=True)
    if not vercel_check:
        print("⚠️  未检测到 Vercel 登录，请先运行: vercel login")
        print("然后运行: vercel --prod")
    else:
        print(f"✅ 已登录 Vercel: {vercel_check}")
        if not run_cmd("vercel --prod", check=False):
            print("⚠️  Vercel 部署可能需要手动确认，请检查输出")
        else:
            print("✅ Vercel 部署成功")
    print()
    
    # 最终验证
    print("=" * 60)
    print("🎉 部署流程完成！")
    print("=" * 60)
    print()
    print("📝 后续检查：")
    print("  1. 检查 Fly.io 日志: fly logs")
    print("  2. 访问后端 API: https://open-alpha-arena.fly.dev/api/health")
    print("  3. 检查 Vercel 部署状态: vercel ls")
    print()

if __name__ == "__main__":
    main()

