# 快速部署指南

## 步骤 1: 设置 Fly.io 环境变量

从 Supabase Dashboard 复制完整的连接字符串（包含密码），然后执行：

```bash
fly secrets set DATABASE_URL="postgresql://postgres:[YOUR_PASSWORD]@db.swizelkwjawvnvekxoff.supabase.co:5432/postgres" --app open-alpha-arena
```

**注意**: 将 `[YOUR_PASSWORD]` 替换为实际的 Supabase 数据库密码。

## 步骤 2-5: 自动执行

设置环境变量后，运行以下命令自动完成剩余步骤：

```bash
./deploy_steps.sh
```

或者，如果您已经设置了 `SUPABASE_PASSWORD` 环境变量：

```bash
SUPABASE_PASSWORD="your_password" ./deploy_steps.sh
```

## 手动执行步骤（如果自动脚本失败）

### 2. 重新部署 Fly.io
```bash
fly deploy --app open-alpha-arena
```

### 3. 初始化数据库
```bash
fly ssh console --app open-alpha-arena -C "cd /app && uv run python -c \"from database.connection import Base, engine; Base.metadata.create_all(bind=engine); print('✅ 数据库表创建成功')\""
```

### 4. 验证后端
```bash
curl https://open-alpha-arena.fly.dev/api/health
```

### 5. 部署 Vercel
```bash
vercel --prod
```

