# 快速开始指南

本指南帮助您在5分钟内启动"死了吗"后端服务。

## 前提条件

- 已安装 Node.js 16+ 和 npm
- 有一个云服务器或本地开发环境

## 步骤1: 安装依赖（2分钟）

```bash
cd backend
npm install
```

## 步骤2: 配置环境变量（1分钟）

```bash
cp .env.example .env
```

编辑 `.env` 文件，修改JWT密钥：
```env
PORT=3000
JWT_SECRET=change-this-to-a-strong-random-string
NODE_ENV=development
```

## 步骤3: 启动服务（10秒）

**开发模式（自动重载）：**
```bash
npm run dev
```

**生产模式：**
```bash
npm start
```

看到以下输出表示成功：
```
🚀 Server running on port 3000
📊 Health check: http://localhost:3000/health
✅ Database connected
✅ Tables created
```

## 步骤4: 验证服务（30秒）

打开新终端，执行：
```bash
curl http://localhost:3000/health
```

应返回：
```json
{"status":"ok","timestamp":"2024-01-13T12:00:00.000Z"}
```

## 步骤5: 配置Flutter应用（1分钟）

编辑 `lib/services/api_service.dart`：
```dart
static String baseUrl = 'http://localhost:3000/api';  // 本地开发
// 或
static String baseUrl = 'http://your-server-ip:3000/api';  // 远程服务器
```

安装Flutter依赖：
```bash
flutter pub get
```

运行应用：
```bash
flutter run
```

## 完成！

现在您可以：
1. 在App中注册账户
2. 配置SMTP邮件设置
3. 每天签到
4. 后端会自动检查并发送超时警报

## 测试API

使用以下命令测试API：

**注册用户：**
```bash
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "password123",
    "deviceId": "test-device-123",
    "emergencyEmail": "emergency@example.com"
  }'
```

**登录：**
```bash
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "password123"
  }'
```

**签到（需要替换YOUR_TOKEN）：**
```bash
curl -X POST http://localhost:3000/api/checkin \
  -H "Authorization: Bearer YOUR_TOKEN"
```

## 常见问题

**Q: 端口3000被占用怎么办？**
```bash
# 修改.env中的PORT
PORT=3001
```

**Q: 如何查看日志？**
```bash
# 开发模式下日志直接输出在终端
# PM2管理查看日志
pm2 logs silema-backend
```

**Q: 数据库文件在哪里？**
```
backend/data/silema.db
```

## 下一步

- 阅读 [完整部署指南](DEPLOYMENT.md) 部署到生产环境
- 阅读 [后端README](backend/README.md) 了解更多API细节
- 配置SMTP以启用邮件警报功能

## 技术支持

如遇问题，请检查：
1. Node.js版本：`node -v`（需要16+）
2. 端口是否被占用：`lsof -i :3000`
3. 防火墙是否开放端口

---

**需要帮助？** 查看 [DEPLOYMENT.md](DEPLOYMENT.md) 获取详细文档
