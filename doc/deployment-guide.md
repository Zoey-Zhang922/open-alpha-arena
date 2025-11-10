# 部署指南

本文档介绍如何将 Open Alpha Arena 部署到生产环境。

## 目录

- [架构概览](#架构概览)
- [环境配置](#环境配置)
- [后端部署 (Fly.io)](#后端部署-flyio)
- [前端部署 (Vercel)](#前端部署-vercel)
- [数据库配置 (Supabase)](#数据库配置-supabase)
- [部署验证](#部署验证)
- [更新部署](#更新部署)

## 架构概览

```
用户浏览器
    │
    ├──────────────┐
    │              │
┌───▼────┐    ┌───▼────────┐
│ Vercel │    │ Fly.io     │
│ 前端   │───▶│ 后端       │
└────────┘    │ (FastAPI)  │
              └──────┬─────┘
                     │
              ┌──────▼─────────┐
              │ Supabase       │
              │ PostgreSQL     │
              └────────────────┘
```

- **前端**: Vercel (静态部署)
- **后端**: Fly.io (容器部署)
- **数据库**: Supabase (托管 PostgreSQL)

## 环境配置

### 前置要求

1. **Fly.io 账号**
   - 注册: https://fly.io/
   - 安装 CLI: `curl -L https://fly.io/install.sh | sh`
   - 登录: `fly auth login`

2. **Vercel 账号**
   - 注册: https://vercel.com/
   - 安装 CLI: `npm i -g vercel`
   - 登录: `vercel login`

3. **Supabase 账号**
   - 注册: https://supabase.com/
   - 创建项目并获取数据库连接字符串

## 后端部署 (Fly.io)

### 1. 初始化 Fly.io 应用（仅首次）

项目已包含 `fly.toml` 配置文件，如需创建新应用：

```bash
# 在项目根目录
fly launch --name open-alpha-arena --no-deploy
```

### 2. 配置环境变量

设置数据库连接字符串（包含密码）：

```bash
fly secrets set DATABASE_URL="postgresql://postgres:YOUR_PASSWORD@db.swizelkwjawvnvekxoff.supabase.co:5432/postgres" --app open-alpha-arena
```

查看已配置的密钥：

```bash
fly secrets list --app open-alpha-arena
```

### 3. 部署后端

```bash
fly deploy --app open-alpha-arena
```

部署过程：
1. 构建 Docker 镜像
2. 推送到 Fly.io
3. 启动容器
4. 健康检查

### 4. 验证部署

```bash
# 检查应用状态
fly status --app open-alpha-arena

# 查看日志
fly logs --app open-alpha-arena

# 健康检查
curl https://open-alpha-arena.fly.dev/api/health
```

### 5. SSH 访问（调试用）

```bash
# 进入容器
fly ssh console --app open-alpha-arena

# 在容器内执行命令
cd /app
uv run python -c "from database.connection import engine; print('✅ 数据库连接成功')"
```

## 前端部署 (Vercel)

### 1. 配置 Vercel 项目（仅首次）

在项目根目录：

```bash
vercel
```

按提示操作：
- 选择或创建项目
- 设置项目名称
- 确认配置

项目已包含 `vercel.json` 配置，会自动：
- 将 `/api/*` 请求代理到 Fly.io 后端
- 将 `/ws` WebSocket 请求代理到后端

### 2. 部署到生产环境

```bash
vercel --prod
```

或通过 Git 自动部署：
- 推送到 GitHub
- Vercel 自动检测并部署

### 3. 配置自定义域名（可选）

在 Vercel Dashboard:
1. 进入项目设置
2. Domains → Add Domain
3. 按提示配置 DNS

## 数据库配置 (Supabase)

### 1. 创建 Supabase 项目

1. 访问 https://supabase.com/dashboard
2. 创建新项目
3. 记录项目 ID 和数据库密码

### 2. 获取连接字符串

在 Supabase Dashboard:
1. **Settings → Database**
2. 找到 **Connection String**
3. 选择 **Transaction** 模式
4. 复制连接字符串（包含密码）

格式：
```
postgresql://postgres:[PASSWORD]@db.[PROJECT-ID].supabase.co:5432/postgres
```

### 3. 初始化数据库表（仅首次）

数据库表会在后端首次启动时自动创建（通过 SQLAlchemy）。

如需手动初始化：

```bash
fly ssh console --app open-alpha-arena -C "cd /app && uv run python -c \"from database.connection import Base, engine; Base.metadata.create_all(bind=engine); print('✅ 表创建成功')\""
```

### 4. 数据备份

定期备份 Supabase 数据：

```bash
# 使用 pg_dump
pg_dump "postgresql://postgres:PASSWORD@db.PROJECT-ID.supabase.co:5432/postgres" > backup_$(date +%Y%m%d).sql

# 恢复备份
psql "postgresql://..." < backup_20241110.sql
```

## 部署验证

### 后端验证

```bash
# 1. 健康检查
curl https://open-alpha-arena.fly.dev/api/health
# 应返回: {"status":"healthy","message":"Trading API is running"}

# 2. 查看账户列表
curl https://open-alpha-arena.fly.dev/api/accounts

# 3. 查看市场数据
curl https://open-alpha-arena.fly.dev/api/market-data/crypto-list
```

### 前端验证

访问 Vercel 提供的域名，检查：
- ✅ 页面正常加载
- ✅ 可以看到账户列表
- ✅ 可以查看持仓和订单
- ✅ WebSocket 连接正常（实时更新）

### WebSocket 验证

```bash
# 使用 wscat 测试
npm install -g wscat
wscat -c wss://open-alpha-arena.fly.dev/ws

# 应成功建立连接并接收消息
```

## 更新部署

### 更新后端

```bash
# 1. 提交代码
git add .
git commit -m "feat: 你的更新"
git push

# 2. 部署到 Fly.io
fly deploy --app open-alpha-arena

# 3. 验证部署
fly logs --app open-alpha-arena
```

### 更新前端

```bash
# 方式 1: 通过 Vercel CLI
vercel --prod

# 方式 2: 通过 Git（推荐）
git push origin main
# Vercel 自动检测并部署
```

### 回滚部署

#### Fly.io 回滚

```bash
# 查看部署历史
fly releases --app open-alpha-arena

# 回滚到上一个版本
fly releases rollback --app open-alpha-arena
```

#### Vercel 回滚

在 Vercel Dashboard:
1. 进入项目
2. Deployments 页面
3. 选择历史部署
4. 点击 "Promote to Production"

## 环境变量管理

### Fly.io 环境变量

```bash
# 设置变量
fly secrets set KEY=value --app open-alpha-arena

# 查看变量（不显示值）
fly secrets list --app open-alpha-arena

# 删除变量
fly secrets unset KEY --app open-alpha-arena
```

### Vercel 环境变量

在 Vercel Dashboard:
1. 进入项目设置
2. Environment Variables
3. 添加变量并选择环境（Production/Preview/Development）

或使用 CLI：

```bash
vercel env add VARIABLE_NAME
```

## 监控和日志

### Fly.io 监控

```bash
# 实时日志
fly logs --app open-alpha-arena

# 查看最近的日志
fly logs --app open-alpha-arena -n 100

# 应用状态
fly status --app open-alpha-arena

# 资源使用
fly vm status --app open-alpha-arena
```

### Vercel 监控

在 Vercel Dashboard:
- **Analytics**: 查看访问统计
- **Logs**: 查看构建和运行日志
- **Deployments**: 查看部署历史

## 常见部署问题

### Q: Fly.io 部署失败，提示端口绑定错误

**A**: 检查 `fly.toml` 中的端口配置，确保内部端口与应用监听端口一致（5611）。

### Q: Vercel 部署后 API 请求失败

**A**: 检查 `vercel.json` 中的代理配置，确保指向正确的 Fly.io 域名。

### Q: WebSocket 连接 426 错误

**A**: 确保 `fly.toml` 中关闭了 `force_https` 并正确配置了 handlers。详见 [问题排查文档](./troubleshooting.md)。

### Q: 数据库连接失败

**A**: 
1. 检查 Fly.io 环境变量是否正确设置
2. 验证 Supabase 连接字符串是否有效
3. 检查 Supabase 项目是否暂停（免费版可能自动暂停）

## 成本估算

### Fly.io（后端）

- **免费额度**: 3 个共享 CPU 虚拟机
- **推荐配置**: 
  - 1 个 shared-cpu-1x 实例: ~$2/月
  - 256MB RAM: 免费
  - 持久化存储: 免费

### Vercel（前端）

- **Hobby 免费版**: 足够个人使用
- **Pro 版**: $20/月（如需更多带宽和功能）

### Supabase（数据库）

- **免费版**: 500MB 数据库，足够开发使用
- **Pro 版**: $25/月（8GB 数据库，无暂停）

## 最佳实践

1. **环境分离**: 使用不同的 Supabase 项目区分开发和生产环境
2. **定期备份**: 每周备份生产数据库
3. **监控告警**: 配置 Fly.io 和 Vercel 的告警通知
4. **版本控制**: 使用 Git tags 标记重要版本
5. **渐进部署**: 先部署到预览环境测试，再推送到生产环境

## 下一步

- 查看 [开发指南](./development-guide.md) 了解本地开发流程
- 阅读 [问题排查](./troubleshooting.md) 解决部署问题

