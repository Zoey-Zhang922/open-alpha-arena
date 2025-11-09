# 部署检查清单

## ✅ 已完成的配置

1. **Supabase** - 已手动配置
2. **Fly.io 后端** - 已部署到 https://open-alpha-arena.fly.dev/
3. **数据库连接代码** - 已更新支持 PostgreSQL（通过环境变量）
4. **PostgreSQL 驱动** - 已添加到 `pyproject.toml`
5. **Vercel 配置** - 已创建 `vercel.json`

## 🔧 需要手动完成的步骤

### 1. 配置 Fly.io 环境变量

在 Fly.io 上设置 Supabase 数据库连接字符串：

```bash
# 在 Supabase 项目设置中获取连接字符串，格式类似：
# postgresql://postgres:[YOUR-PASSWORD]@db.[PROJECT-REF].supabase.co:5432/postgres

# 设置到 Fly.io
fly secrets set DATABASE_URL="postgresql://postgres:[YOUR-PASSWORD]@db.[PROJECT-REF].supabase.co:5432/postgres"
```

**重要提示：**
- 在 Supabase Dashboard > Settings > Database 中找到连接字符串
- 确保使用连接池模式（Connection Pooling）的连接字符串，格式为：`postgresql://postgres.[PROJECT-REF]:[PASSWORD]@aws-0-[REGION].pooler.supabase.com:6543/postgres`
- 或者使用直接连接：`postgresql://postgres:[PASSWORD]@db.[PROJECT-REF].supabase.co:5432/postgres`

### 2. 重新部署 Fly.io 应用

设置环境变量后，需要重新部署以应用更改：

```bash
fly deploy
```

### 3. 初始化数据库表结构

首次使用 Supabase 时，需要运行数据库迁移。可以通过以下方式之一：

**方式 A：通过 Fly.io SSH 执行**
```bash
fly ssh console
# 然后在容器内运行
cd /app
uv run python -c "from database.connection import Base, engine; Base.metadata.create_all(bind=engine)"
```

**方式 B：在本地连接 Supabase 执行**
```bash
# 设置本地环境变量
export DATABASE_URL="postgresql://postgres:[PASSWORD]@db.[PROJECT-REF].supabase.co:5432/postgres"

# 运行初始化脚本
cd backend
uv run python -c "from database.connection import Base, engine; Base.metadata.create_all(bind=engine)"
```

### 4. 部署前端到 Vercel

#### 4.1 安装 Vercel CLI（如果还没有）
```bash
npm i -g vercel
```

#### 4.2 登录 Vercel
```bash
vercel login
```

#### 4.3 部署前端
```bash
# 在项目根目录
vercel

# 或者指定生产环境
vercel --prod
```

#### 4.4 配置 Vercel 环境变量（如果需要）
通常不需要额外配置，因为 `vercel.json` 已经配置了 API 代理。

### 5. 验证部署

#### 5.1 检查后端健康状态
```bash
curl https://open-alpha-arena.fly.dev/api/health
```
应该返回：`{"status":"healthy","message":"Trading API is running"}`

#### 5.2 检查数据库连接
访问 Fly.io 日志：
```bash
fly logs
```
确认没有数据库连接错误。

#### 5.3 检查前端部署
访问 Vercel 提供的域名，确认前端可以正常加载并连接到后端 API。

## 📝 注意事项

1. **数据库迁移**：如果 Supabase 中已有数据，确保表结构与代码中的模型匹配。
2. **环境变量安全**：不要在代码中硬编码数据库密码，始终使用环境变量。
3. **CORS 配置**：后端已配置允许所有来源（`allow_origins=["*"]`），生产环境建议限制为特定域名。
4. **WebSocket 连接**：前端 WebSocket 会自动根据当前域名连接到正确的后端（通过 `resolveWsUrl()` 函数）。

## 🔍 故障排查

### 数据库连接失败
- 检查 Fly.io 环境变量是否正确设置：`fly secrets list`
- 确认 Supabase 数据库允许来自 Fly.io IP 的连接
- 检查连接字符串格式是否正确

### 前端无法连接后端
- 检查 Vercel 的 rewrites 配置是否正确
- 确认 Fly.io 应用正在运行
- 检查浏览器控制台的网络请求错误

### 表结构未创建
- 确认已运行数据库初始化脚本
- 检查 Fly.io 日志中的错误信息
- 验证数据库连接是否成功

