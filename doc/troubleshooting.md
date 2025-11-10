# 问题排查与解决经验

本文档汇总了开发和部署过程中遇到的常见问题及解决方案，以及重要的 Bug 修复经验。

## 目录

- [常见开发问题](#常见开发问题)
- [部署相关问题](#部署相关问题)
- [数据库问题](#数据库问题)
- [历史 Bug 修复经验](#历史-bug-修复经验)
- [最佳实践](#最佳实践)

---

## 常见开发问题

### 数据库连接失败

#### 问题表现
```
sqlalchemy.exc.OperationalError: could not connect to server
```

#### 解决方案

1. **检查环境变量**
   ```bash
   cd backend
   cat .env
   # 确认 DATABASE_URL 存在且格式正确
   ```

2. **验证数据库连接**
   ```bash
   psql "postgresql://postgres:PASSWORD@db.PROJECT-ID.supabase.co:5432/postgres" -c "SELECT version();"
   ```

3. **检查 Supabase 项目状态**
   - 免费版项目可能会自动暂停
   - 访问 Supabase Dashboard 唤醒项目

4. **网络问题**
   - 检查防火墙设置
   - 尝试使用代理或 VPN

### 前端无法连接后端

#### 问题表现
- 浏览器控制台显示 `ERR_CONNECTION_REFUSED`
- API 请求失败

#### 解决方案

1. **确认后端已启动**
   ```bash
   # 检查后端进程
   lsof -i :5611
   ```

2. **检查端口配置**
   - 确认 `frontend/app/lib/api.ts` 中的 API_BASE 地址正确
   - 本地开发: `http://127.0.0.1:5611`

3. **检查 CORS 配置**
   - 后端 `main.py` 中应配置允许的源

### Python 包安装失败

#### 问题表现
```
uv: command not found
```

#### 解决方案

安装 uv 包管理器：

```bash
# macOS/Linux
curl -LsSf https://astral.sh/uv/install.sh | sh

# Windows
powershell -c "irm https://astral.sh/uv/install.ps1 | iex"

# 刷新环境变量
source ~/.bashrc  # 或 ~/.zshrc
```

---

## 部署相关问题

### WebSocket 连接 426 错误（已解决）

#### 问题描述
生产环境 WebSocket 连接返回 426 Upgrade Required 状态码。

#### 根因分析
- Fly.io 默认的 `force_https` 重定向影响 WebSocket 升级头
- Vercel rewrites `/ws` 到 Fly.io 时可能不保留 Upgrade 头

#### 解决方案

修改 `fly.toml` 配置：

```toml
[[services]]
  internal_port = 5611
  protocol = "tcp"

  [[services.ports]]
    port = 80
    handlers = ["http"]
    force_https = false  # 关键：关闭强制 HTTPS

  [[services.ports]]
    port = 443
    handlers = ["http", "tls"]
```

前端直连后端 WebSocket：

```typescript
// frontend/app/main.tsx
const wsUrl = process.env.NODE_ENV === 'production' 
  ? 'wss://open-alpha-arena.fly.dev/ws'  // 直连 Fly.io
  : 'ws://localhost:5611/ws';
```

#### 验证
```bash
wscat -c wss://open-alpha-arena.fly.dev/ws
# 应成功建立连接
```

### Fly.io 部署超时

#### 问题表现
```
Error: deployment failed: health checks are failing
```

#### 解决方案

1. **检查健康检查配置**
   ```toml
   # fly.toml
   [[services.http_checks]]
     interval = "30s"
     timeout = "10s"
     grace_period = "30s"  # 增加宽限期
   ```

2. **查看应用日志**
   ```bash
   fly logs --app open-alpha-arena
   ```

3. **增加资源配置**
   ```bash
   fly scale vm shared-cpu-2x --app open-alpha-arena
   ```

### Vercel 构建失败

#### 问题表现
```
Error: Build exceeded maximum duration
```

#### 解决方案

1. **优化构建配置**
   ```json
   // vercel.json
   {
     "buildCommand": "cd frontend && pnpm build",
     "outputDirectory": "frontend/dist"
   }
   ```

2. **清理缓存**
   - 在 Vercel Dashboard 中清除构建缓存
   - 或在代码中添加 `.vercelignore`

---

## 数据库问题

### 数据类型不匹配（is_active 字段）

#### 问题描述
从 SQLite 迁移到 PostgreSQL 后，`is_active` 字段从字符串类型变成了布尔类型，导致应用层代码无法正确判断。

#### 根因分析
1. **SQLite**: `is_active` 定义为 `String(10)`，存储 `'true'` 或 `'false'` 字符串
2. **PostgreSQL**: 自动推断为 `BOOLEAN` 类型
3. **应用代码**: 期望字符串类型，但数据库返回布尔值

#### 解决方案

使用 SQL 修改列类型：

```sql
ALTER TABLE accounts 
ALTER COLUMN is_active TYPE VARCHAR(10) 
USING CASE 
    WHEN is_active = true THEN 'true'::VARCHAR 
    WHEN is_active = false THEN 'false'::VARCHAR 
    ELSE is_active::VARCHAR 
END;
```

对 `users` 表执行相同操作：

```sql
ALTER TABLE users 
ALTER COLUMN is_active TYPE VARCHAR(10) 
USING CASE 
    WHEN is_active = true THEN 'true'::VARCHAR 
    WHEN is_active = false THEN 'false'::VARCHAR 
    ELSE is_active::VARCHAR 
END;
```

#### 验证
```bash
fly ssh console --app open-alpha-arena

# 在容器内
cd /app
uv run python -c "
from database.connection import SessionLocal
from database.models import Account
db = SessionLocal()
for acc in db.query(Account).all():
    print(f'{acc.name}: {acc.is_active} ({type(acc.is_active).__name__})')
db.close()
"
# 应显示所有 is_active 都是 str 类型
```

#### 经验教训
1. **类型一致性**: 确保 SQLAlchemy 模型定义和数据库实际类型一致
2. **数据迁移验证**: 迁移后应验证数据类型，不仅仅是数据值
3. **PostgreSQL 类型推断**: PostgreSQL 会自动推断列类型，需要明确指定

### 数据库迁移最佳实践

#### 场景：SQLite → PostgreSQL 迁移

**方法 1: 通过 Fly.io SSH（推荐）**

当本地无法直连 Supabase 时，可通过 Fly.io 容器执行迁移：

```bash
# 1. 导出本地数据为 JSON
cd backend
uv run python export_data.py
# 生成 data_export.json

# 2. 上传到 Fly.io
fly ssh sftp shell --app open-alpha-arena
> cd /app
> put backend/data_export.json data_export.json
> put backend/import_data.py import_data.py
> bye

# 3. 在 Fly.io 执行导入
fly ssh console --app open-alpha-arena
> cd /app
> uv run python import_data.py data_export.json
> exit
```

**方法 2: 直接迁移（本地可连接 Supabase）**

```bash
cd backend

# 设置环境变量
export SUPABASE_DATABASE_URL="postgresql://postgres:PASSWORD@db.PROJECT-ID.supabase.co:5432/postgres"

# 运行迁移脚本
uv run python migrate_to_supabase.py
```

#### 迁移注意事项

1. **备份现有数据**
   ```bash
   # 导出 SQLite
   sqlite3 backend/data.db .dump > sqlite_backup.sql
   
   # 导出 PostgreSQL
   pg_dump "postgresql://..." > postgres_backup.sql
   ```

2. **测试迁移脚本**
   - 先在测试数据库上运行
   - 验证数据完整性

3. **迁移顺序**
   按依赖关系迁移表：
   - users → accounts → positions → orders → trades

4. **外键约束**
   - 确保父表数据先迁移
   - 检查外键引用完整性

---

## 历史 Bug 修复经验

### Bug #1: WebSocket 426 Upgrade Required

**日期**: 2024-11-09

**复现步骤**:
1. 客户端连接 `wss://open-alpha-arena.fly.dev/ws`
2. 预期返回 101 Switching Protocols
3. 实际返回 426 Upgrade Required

**根因**: Fly.io 的 `force_https` 配置影响 WebSocket 协议升级

**修复**:
- 修改 `fly.toml`，关闭 `force_https`
- 前端直连后端 WebSocket，不通过 Vercel 代理

**测试结果**: ✅ 已验证 WebSocket 正常连接

**责任人**: AI-assistant

**需求完成进度**: 100%

---

### Bug #2: 数据库 is_active 类型不匹配

**日期**: 2024-11-09

**问题**: 从 SQLite 迁移到 PostgreSQL 后，`is_active` 字段类型自动转换为 boolean，导致应用层判断错误

**影响**:
- ❌ 前端无法正确显示账户激活状态
- ❌ 后端代码判断激活状态可能出错

**修复**: 使用 `ALTER TABLE` 将列类型从 `BOOLEAN` 改为 `VARCHAR(10)`

**验证**: ✅ 生产环境 2 个账户正确显示激活状态

---

## 最佳实践

### 开发环境

1. **统一数据库**: 本地和生产使用同一 Supabase 实例
   - ✅ 数据实时同步
   - ✅ 无需手动迁移
   - ✅ 生产环境测试更准确

2. **环境变量管理**
   - 使用 `.env` 文件（不提交到 Git）
   - 添加 `.env.example` 作为模板

3. **代码提交前检查**
   ```bash
   # 后端代码检查
   cd backend
   uv run ruff check .
   
   # 前端代码检查
   cd frontend
   pnpm run lint
   ```

### 部署流程

1. **本地测试** → **提交代码** → **部署预览** → **生产部署**

2. **监控部署状态**
   ```bash
   # Fly.io
   fly logs --app open-alpha-arena
   
   # Vercel
   vercel logs
   ```

3. **回滚准备**
   - 保留最近 3 个稳定版本的标签
   - 记录每次部署的重要变更

### 数据库操作

1. **定期备份**
   ```bash
   # 每周备份
   pg_dump "postgresql://..." > backup_$(date +%Y%m%d).sql
   ```

2. **迁移脚本测试**
   - 在测试数据库上先运行
   - 验证数据完整性和类型

3. **避免直接修改生产数据**
   - 使用脚本和迁移工具
   - 保留操作日志

### 调试技巧

1. **后端调试**
   ```bash
   # 查看详细日志
   fly logs --app open-alpha-arena -n 200
   
   # SSH 进入容器调试
   fly ssh console --app open-alpha-arena
   ```

2. **数据库调试**
   ```bash
   # 连接生产数据库（谨慎操作）
   psql "postgresql://..."
   
   # 查看表结构
   \d+ accounts
   
   # 查看数据
   SELECT * FROM accounts LIMIT 10;
   ```

3. **前端调试**
   - 使用浏览器开发者工具 Network 标签
   - 检查 API 请求和响应
   - 查看 WebSocket 连接状态

---

## 获取帮助

### 内部资源
- [开发指南](./development-guide.md)
- [部署指南](./deployment-guide.md)

### 外部资源
- [Fly.io 文档](https://fly.io/docs/)
- [Vercel 文档](https://vercel.com/docs)
- [Supabase 文档](https://supabase.com/docs)
- [FastAPI 文档](https://fastapi.tiangolo.com/)
- [React 文档](https://react.dev/)

### 问题反馈

遇到新问题时：
1. 检查本文档是否已有解决方案
2. 查看相关服务的日志
3. 记录问题详情和解决方案
4. 更新本文档，帮助未来的开发者

