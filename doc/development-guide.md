# 开发指南

本文档介绍如何在本地环境搭建和开发 Open Alpha Arena 项目。

## 目录

- [环境要求](#环境要求)
- [项目安装](#项目安装)
- [本地开发](#本地开发)
- [数据库配置](#数据库配置)
- [项目结构](#项目结构)
- [常用命令](#常用命令)

## 环境要求

- **Node.js** 18+ 
- **pnpm** 8+
- **Python** 3.10+
- **uv** (Python 包管理器)
- **PostgreSQL** (通过 Supabase 托管)

## 项目安装

### 1. 克隆项目

```bash
git clone <repository-url>
cd open-alpha-arena
```

### 2. 安装依赖

```bash
# 安装 JavaScript 依赖和 Python 环境
pnpm run install:all
```

这个命令会：
- 安装根目录和 frontend 的 npm 包
- 同步 backend 的 Python 环境（使用 uv）

## 本地开发

### 快速启动

使用一条命令同时启动前后端：

```bash
pnpm run dev
```

这会启动：
- **后端**: http://localhost:5611 (FastAPI)
- **前端**: http://localhost:5173 (Vite + React)

### 单独启动

如需分别启动前后端：

```bash
# 终端 1: 启动后端
pnpm run dev:backend

# 终端 2: 启动前端
pnpm run dev:frontend
```

### 端口配置

- 后端默认端口: **5611**
- 前端默认端口: **5173** (Vite 默认)
- WebSocket: `ws://localhost:5611/ws`

## 数据库配置

项目使用 **Supabase PostgreSQL** 作为数据库（本地开发和生产环境共享）。

### 配置环境变量

在 `backend/` 目录创建 `.env` 文件：

```bash
DATABASE_URL=postgresql://postgres:YOUR_PASSWORD@db.swizelkwjawvnvekxoff.supabase.co:5432/postgres
DB_TIMEZONE=Asia/Shanghai
```

### 获取数据库连接信息

1. 访问 [Supabase Dashboard](https://supabase.com/dashboard/projects)
2. 选择项目 ID: `swizelkwjawvnvekxoff`
3. 进入 **Settings → Database**
4. 复制 Connection String 中的密码

### 数据库时区

- 默认时区: `Asia/Shanghai` (UTC+8)
- PostgreSQL 会话在连接时自动设置时区
- 所有时间戳使用北京时间

### 验证数据库连接

```bash
cd backend
uv run python -c "from database.connection import engine; print('✅ 数据库连接成功')"
```

## 项目结构

```
open-alpha-arena/
├── backend/                # FastAPI 后端
│   ├── api/               # API 路由
│   ├── database/          # 数据库模型和连接
│   ├── services/          # 业务逻辑服务
│   ├── schemas/           # Pydantic 数据模型
│   ├── repositories/      # 数据访问层
│   ├── config/            # 配置文件
│   ├── factors/           # 交易因子
│   └── main.py           # 应用入口
├── frontend/              # React 前端
│   ├── app/
│   │   ├── components/   # React 组件
│   │   ├── lib/          # 工具函数和 API 客户端
│   │   └── main.tsx      # 前端入口
│   └── dist/             # 构建输出
├── doc/                   # 项目文档
├── package.json          # 根项目配置
└── README.md             # 项目概述
```

## 常用命令

### 开发相关

```bash
# 安装所有依赖
pnpm run install:all

# 启动开发服务器（前后端）
pnpm run dev

# 只启动前端
pnpm run dev:frontend

# 只启动后端
pnpm run dev:backend
```

### 构建相关

```bash
# 构建前端和后端
pnpm run build

# 只构建前端
pnpm run build:frontend
```

### 后端开发

```bash
cd backend

# 同步 Python 依赖
uv sync

# 手动启动后端（带热重载）
uv run uvicorn main:app --reload --host 0.0.0.0 --port 5611

# 检查代码风格
uv run ruff check .

# 格式化代码
uv run ruff format .
```

### 前端开发

```bash
cd frontend

# 安装依赖
pnpm install

# 启动开发服务器
pnpm dev

# 构建生产版本
pnpm build

# 预览构建结果
pnpm preview
```

## API 文档

后端启动后，可访问：

- **Swagger UI**: http://localhost:5611/docs
- **ReDoc**: http://localhost:5611/redoc
- **OpenAPI JSON**: http://localhost:5611/openapi.json

## 开发工作流

### 典型的开发流程

1. **启动开发环境**
   ```bash
   pnpm run dev
   ```

2. **修改代码**
   - 后端代码修改会自动热重载
   - 前端代码修改会自动刷新浏览器

3. **测试功能**
   - 访问 http://localhost:5173 测试前端
   - 使用 http://localhost:5611/docs 测试 API

4. **提交代码**
   ```bash
   git add .
   git commit -m "feat: 你的功能描述"
   git push
   ```

### 调试技巧

#### 后端调试

在代码中添加调试输出：

```python
import logging
logger = logging.getLogger(__name__)

logger.info(f"调试信息: {variable}")
```

后端日志会在终端显示。

#### 前端调试

使用浏览器开发者工具：
- **Console**: 查看 console.log 输出
- **Network**: 查看 API 请求和响应
- **Components**: 查看 React 组件状态

## 环境变量说明

### 后端环境变量 (`backend/.env`)

```bash
# 数据库连接（必需）
DATABASE_URL=postgresql://...

# 时区配置（可选，默认 Asia/Shanghai）
DB_TIMEZONE=Asia/Shanghai

# API 密钥（如需要）
# OPENAI_API_KEY=sk-...
```

### 前端环境变量

前端使用代理配置，无需额外的环境变量。API 请求通过 Vite 代理转发到后端。

## 常见问题

### Q: 后端启动失败，提示数据库连接错误

**A**: 检查 `backend/.env` 文件是否存在且配置正确。

### Q: 前端无法连接到后端 API

**A**: 确保后端已启动在 5611 端口，检查浏览器控制台的网络请求。

### Q: Python 包安装失败

**A**: 确保已安装 uv：
```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
```

### Q: pnpm 命令不存在

**A**: 安装 pnpm：
```bash
npm install -g pnpm
```

## 下一步

- 阅读 [部署指南](./deployment-guide.md) 了解如何部署到生产环境
- 查看 [问题排查](./troubleshooting.md) 解决常见问题

