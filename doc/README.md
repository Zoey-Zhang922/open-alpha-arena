# 文档目录

本目录包含 Open Alpha Arena 项目的所有技术文档。

## 文档组织规范

### 规则
1. **所有技术文档必须放在 `doc/` 文件夹中**
2. 根目录只保留项目概述的 `README.md`
3. 临时脚本应放在 `scripts/` 文件夹，使用后及时清理
4. 迁移、修复等一次性操作的脚本和文档在完成后应删除，核心经验提炼到此目录

### 文档列表

- **[development-guide.md](./development-guide.md)** - 开发指南
  - 环境配置
  - 本地开发
  - 数据库配置

- **[deployment-guide.md](./deployment-guide.md)** - 部署指南
  - Fly.io 后端部署
  - Vercel 前端部署
  - 环境变量配置

- **[troubleshooting.md](./troubleshooting.md)** - 问题排查与解决经验
  - 常见问题
  - 历史 Bug 修复经验
  - 最佳实践

## 贡献文档

添加新文档时，请：
1. 使用清晰的文件命名（小写，连字符分隔）
2. 在本 README 中添加链接和简短描述
3. 使用 Markdown 格式
4. 包含目录和代码示例

