# 死了吗

一款极简主义的每日签到应用，带有云端后端支持。如果超过48小时未签到，系统会自动发送邮件通知你的紧急联系人。

## ✨ 功能特点

- 🎨 **精美设计** - 极简界面，渐变色彩，流畅动画
- ☁️ **云端服务** - 独立后端服务器，无需应用打开即可检查
- 🔔 **智能警报** - 48小时未签到自动发送邮件通知
- 📊 **数据统计** - 签到天数统计，可视化展示
- 🔐 **安全可靠** - JWT认证，数据加密存储
- 📧 **SMTP支持** - 支持自定义邮件服务器

## 系统架构

```
┌─────────────┐      API请求      ┌─────────────┐
│  Flutter    │ ─────────────────> │  Node.js    │
│     App     │                    │   Backend   │
└─────────────┘ <───────────────── └─────────────┘
                                          │
                                          ▼
                                  ┌─────────────┐
                                  │  SQLite DB  │
                                  └─────────────┘
                                          │
                                          ▼
                                  ┌─────────────┐
                                  │   邮件服务   │
                                  └─────────────┘
```

## 🚀 快速开始

### 方式1: 本地开发

**后端服务：**
```bash
cd backend
npm install
npm run dev
```

**Flutter应用：**
```bash
flutter pub get
flutter run
```

详细说明请查看 [快速开始指南](QUICKSTART.md)

### 方式2: 生产部署

查看完整部署指南：[DEPLOYMENT.md](DEPLOYMENT.md)

## 📁 项目结构

```
silema/
├── backend/                 # 后端API服务
│   ├── src/
│   │   ├── routes/         # API路由
│   │   ├── models/         # 数据库模型
│   │   ├── middleware/     # 中间件
│   │   ├── utils/          # 工具函数
│   │   └── server.js       # 主服务器
│   ├── data/               # SQLite数据库（自动创建）
│   └── package.json
├── lib/                    # Flutter应用
│   ├── pages/              # 页面
│   ├── services/           # 服务层
│   └── main.dart
├── android/                # Android配置
├── DEPLOYMENT.md           # 部署指南
├── QUICKSTART.md           # 快速开始
└── README.md
```

## 📱 功能截图

### 主页面
- 签到按钮
- 最后签到时间
- 状态指示器
- 励志名言

### 统计页面
- 累计签到天数
- 本周/本月签到
- 签到趋势

### 设置页面
- SMTP邮件配置
- 紧急联系人设置
- 测试邮件功能

## 🔧 技术栈

**前端：**
- Flutter 3.10.7+
- Dart
- Material Design 3

**后端：**
- Node.js 16+
- Express.js
- SQLite (better-sqlite3)
- JWT认证
- Nodemailer
- node-cron (定时任务)

## 📖 API文档

### 认证接口

**注册：**
```http
POST /api/auth/register
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "password123",
  "deviceId": "unique-device-id",
  "emergencyEmail": "emergency@example.com"
}
```

**登录：**
```http
POST /api/auth/login
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "password123"
}
```

### 签到接口

**签到：**
```http
POST /api/checkin
Authorization: Bearer <token>
```

**获取统计：**
```http
GET /api/checkin/stats
Authorization: Bearer <token>
```

更多API详情请查看 [backend/README.md](backend/README.md)

## ⚙️ 配置说明

### 后端配置

编辑 `backend/.env`：
```env
PORT=3000
JWT_SECRET=your-super-secret-jwt-key
NODE_ENV=production
```

### 前端配置

编辑 `lib/services/api_service.dart`：
```dart
static String baseUrl = 'http://your-server.com/api';
```

### SMTP邮件配置

在应用设置中配置：
- **主机**: smtp.gmail.com
- **端口**: 587 或 465
- **用户名**: 你的邮箱
- **密码**: 邮箱密码或应用专用密码

**常见邮箱SMTP配置：**

| 邮箱 | 主机 | 端口 | 备注 |
|------|------|------|------|
| Gmail | smtp.gmail.com | 587 | 需应用专用密码 |
| QQ邮箱 | smtp.qq.com | 465 | 需授权码 |
| 163邮箱 | smtp.163.com | 465 | 需授权码 |
| Outlook | smtp.office365.com | 587 | 需应用密码 |

## 🔄 工作流程

1. **用户注册**
   - 填写邮箱、密码
   - 设置紧急联系人

2. **配置SMTP**
   - 在设置页面配置邮件服务器
   - 发送测试邮件验证

3. **每日签到**
   - 打开App点击签到按钮
   - 数据保存到服务器

4. **自动检查**
   - 后端每小时检查所有用户
   - 发现超时用户自动发送警报

## 🛠️ 开发指南

### 添加新功能

**后端：**
```bash
cd backend
# 添加路由
vim src/routes/your-route.js
# 在server.js中引入路由
```

**前端：**
```bash
# 添加新页面
flutter create lib/pages/your_page.dart
# 在api_service.dart中添加API方法
```

### 运行测试

```bash
# 后端测试
cd backend
npm test

# 前端测试
flutter test
```

## 📦 部署

### 云服务器部署

推荐配置：
- CPU: 1核
- 内存: 512MB - 1GB
- 系统: Ubuntu 20.04+

详细步骤：[DEPLOYMENT.md](DEPLOYMENT.md)

### Docker部署（可选）

```dockerfile
FROM node:18-alpine
WORKDIR /app
COPY backend/package*.json ./
RUN npm install --production
COPY backend/src ./src
EXPOSE 3000
CMD ["node", "src/server.js"]
```

## 🔒 安全建议

1. **生产环境必须修改JWT密钥**
2. **使用HTTPS加密传输**
3. **定期备份数据库**
4. **限制API访问频率**
5. **使用强密码策略**

## 📊 性能优化

- 使用PM2管理Node进程
- 启用Nginx反向代理
- 配置CDN加速静态资源
- 定期清理旧签到记录

## 🐛 故障排查

### 常见问题

**Q: 后端启动失败？**
```bash
# 检查端口占用
lsof -i :3000
# 检查Node版本
node -v  # 需要16+
```

**Q: 邮件发送失败？**
- 检查SMTP配置
- 确认邮箱开启了SMTP服务
- 使用应用专用密码

**Q: API连接失败？**
- 检查服务器地址配置
- 确认防火墙开放端口
- 查看后端日志

## 📝 更新日志

### v2.0.0 (最新)
- ✅ 新增云端后端服务
- ✅ 支持用户注册登录
- ✅ 服务器端定时检查
- ✅ 完整的API接口
- ✅ 优化UI动画效果

### v1.0.0
- ✅ 基础签到功能
- ✅ 本地存储
- ✅ SMTP邮件发送

## 🤝 贡献

欢迎提交Issue和Pull Request！

## 📄 许可证

MIT License


⭐ 如果这个项目对你有帮助，请给个Star！
