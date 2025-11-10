# Open Alpha Arena

<img width="3840" height="1498" alt="image" src="https://github.com/user-attachments/assets/dac4b5d1-3da7-4b54-97e5-cef226d99547" />

<img width="2882" height="1792" alt="image" src="https://github.com/user-attachments/assets/66a5283b-3761-4992-82d1-8cd01f4d518d" />

一个受 [nof1 Alpha Arena](https://nof1.ai) 启发的项目，让你可以在加密货币市场上设置 AI 交易机器人。

## ✨ 特性

- ✅ 模拟交易（Paper Trading）
- ✅ OpenAI 兼容 API
- ✅ 杠杆交易支持
- ✅ ccxt 行情数据
- 🚧 实盘交易（可通过 ccxt 轻松实现）

## 🚀 快速开始

### 环境要求

- Node.js 18+ 和 pnpm
- Python 3.10+ 和 uv

### 安装依赖

```bash
# 安装 JavaScript 依赖和 Python 环境
pnpm run install:all
```

### 本地开发

启动前后端开发服务器：

```bash
pnpm run dev
```

访问：
- **前端**: http://localhost:5173
- **后端**: http://localhost:5611
- **API 文档**: http://localhost:5611/docs

### 构建

```bash
pnpm run build
```

## 📚 文档

完整文档请查看 [doc/](./doc/) 目录：

- **[开发指南](./doc/development-guide.md)** - 环境配置、本地开发、数据库设置
- **[部署指南](./doc/deployment-guide.md)** - Fly.io、Vercel 部署流程
- **[问题排查](./doc/troubleshooting.md)** - 常见问题、Bug 修复经验

## 🏗️ 技术栈

**后端**:
- FastAPI (Python)
- SQLAlchemy + PostgreSQL (Supabase)
- WebSocket 实时通信

**前端**:
- React + TypeScript
- Vite
- Tailwind CSS

**部署**:
- 后端: Fly.io
- 前端: Vercel
- 数据库: Supabase

## 📊 Star History

<a href="https://www.star-history.com/#etrobot/open-alpha-arena&type=date&legend=top-left">
 <picture>
   <source media="(prefers-color-scheme: dark)" srcset="https://api.star-history.com/svg?repos=etrobot/open-alpha-arena&type=date&theme=dark&legend=top-left" />
   <source media="(prefers-color-scheme: light)" srcset="https://api.star-history.com/svg?repos=etrobot/open-alpha-arena&type=date&legend=top-left" />
   <img alt="Star History Chart" src="https://api.star-history.com/svg?repos=etrobot/open-alpha-arena&type=date&legend=top-left" />
 </picture>
</a>

## 📄 License

MIT
