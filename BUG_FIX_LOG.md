# BUG 修复日志

每次 Bug 修复后，请记录以下信息：

| Bug ID | 描述 | 复现步骤 | 根因分析 | 修复方案 | 修改代码位置 | 测试结果 | 修改日期 | 责任人 | 需求完成进度 |
|--------|------|----------|----------|----------|--------------|----------|----------|--------|---------------|
| BUG-WS-426-20251109 | 生产环境 WebSocket 连接返回 426（Upgrade Required） | 客户端连接 `wss://<app>.fly.dev/ws` → 预期 101 → 实际 426 | Fly 默认 `force_https` 重定向影响 WebSocket 升级头；同时 Vercel rewrites `/ws` 到 Fly 时可能不保留 Upgrade 头 | 后端：切换 `[[services]]`，为 443/80 设置 `handlers` 并关闭 `force_https`；前端：生产环境 WebSocket 直连 `wss://open-alpha-arena.fly.dev/ws` | `fly.toml`，`frontend/app/main.tsx` | curl 健康检查 200；`wscat` 已成功握手；前端待 Vercel 部署后验证 | 2025-11-09 | AI-assistant | 100% |