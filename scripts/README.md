# 脚本目录

这个目录包含项目的实用脚本。

## 📁 脚本列表

### `deploy.sh`

简化的部署脚本，用于自动化 Fly.io 和 Vercel 的部署流程。

**使用方法**：

```bash
# 部署前后端
./scripts/deploy.sh

# 只部署后端
./scripts/deploy.sh --backend

# 只部署前端
./scripts/deploy.sh --frontend

# 查看帮助
./scripts/deploy.sh --help
```

**详细部署文档**：请参考 [doc/deployment-guide.md](../doc/deployment-guide.md)

## 📝 脚本管理规范

1. **持久脚本**：有长期价值的脚本放在此目录
2. **临时脚本**：一次性使用的脚本应在使用后删除
3. **文档化**：每个脚本应包含清晰的注释和使用说明
4. **索引**：新增脚本应更新本 README

## 🔧 添加新脚本

添加新脚本时，请确保：

1. ✅ 添加 shebang (`#!/bin/bash`)
2. ✅ 添加脚本说明注释
3. ✅ 添加使用示例
4. ✅ 设置执行权限：`chmod +x scripts/your-script.sh`
5. ✅ 更新本 README

