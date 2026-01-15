# "死了吗" 后端API

基于 Node.js + Express + SQLite 的后端服务，提供用户认证、签到记录和定时邮件警报功能。

## 功能特性

- ✅ 用户注册/登录（支持邮箱+密码和设备ID登录）
- ✅ JWT令牌认证
- ✅ 签到记录和统计
- ✅ SMTP邮件配置
- ✅ 定时检查任务（每小时执行）
- ✅ 自动发送超时警报（48小时未签到）
- ✅ SQLite数据库存储

## 快速开始

### 1. 安装依赖

```bash
cd backend
npm install
```

### 2. 配置环境变量

```bash
cp .env.example .env
```

编辑 `.env` 文件，修改JWT密钥：

```env
PORT=3000
JWT_SECRET=your-super-secret-jwt-key-change-in-production
NODE_ENV=production
```

### 3. 启动服务

**开发模式（自动重载）：**
```bash
npm run dev
```

**生产模式：**
```bash
npm start
```

服务将在 `http://localhost:3000` 启动。

### 4. 验证运行

访问健康检查接口：
```bash
curl http://localhost:3000/health
```

应返回：
```json
{
  "status": "ok",
  "timestamp": "2024-01-13T12:00:00.000Z"
}
```

## API文档

### 认证接口

#### 注册
```
POST /api/auth/register
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "password123",
  "deviceId": "unique-device-id",
  "emergencyEmail": "emergency@example.com"
}
```

响应：
```json
{
  "message": "注册成功",
  "token": "jwt-token-here",
  "user": {
    "id": 1,
    "email": "user@example.com",
    "emergencyEmail": "emergency@example.com"
  }
}
```

#### 登录（邮箱+密码）
```
POST /api/auth/login
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "password123"
}
```

#### 登录（设备ID）
```
POST /api/auth/login-device
Content-Type: application/json

{
  "deviceId": "unique-device-id"
}
```

#### 获取用户信息
```
GET /api/auth/me
Authorization: Bearer <token>
```

#### 更新SMTP配置
```
PUT /api/auth/smtp
Authorization: Bearer <token>
Content-Type: application/json

{
  "host": "smtp.gmail.com",
  "port": 587,
  "username": "your-email@gmail.com",
  "password": "your-app-password"
}
```

#### 更新紧急联系人邮箱
```
PUT /api/auth/emergency-email
Authorization: Bearer <token>
Content-Type: application/json

{
  "emergencyEmail": "new-emergency@example.com"
}
```

### 签到接口

#### 签到
```
POST /api/checkin
Authorization: Bearer <token>
```

响应：
```json
{
  "message": "签到成功",
  "timestamp": "2024-01-13T12:00:00.000Z"
}
```

#### 获取最后签到时间
```
GET /api/checkin/last
Authorization: Bearer <token>
```

响应：
```json
{
  "lastCheckin": "2024-01-13T10:30:00.000Z"
}
```

#### 获取签到统计
```
GET /api/checkin/stats
Authorization: Bearer <token>
```

响应：
```json
{
  "totalDays": 30,
  "weekDays": 5,
  "monthDays": 15,
  "lastCheckin": "2024-01-13T10:30:00.000Z"
}
```

#### 获取最近签到记录
```
GET /api/checkin/recent
Authorization: Bearer <token>
```

响应：
```json
{
  "checkins": [
    {
      "id": 30,
      "timestamp": "2024-01-13T10:30:00.000Z"
    },
    {
      "id": 29,
      "timestamp": "2024-01-12T10:25:00.000Z"
    }
  ]
}
```

## 定时任务

系统每小时（第5分钟）自动检查所有用户的签到状态：

- **检查频率**：每小时一次
- **警报阈值**：48小时未签到
- **警报冷却**：避免重复发送（24小时内不重复发送）

如需修改阈值，编辑 `src/utils/checkService.js`：

```javascript
const ALERT_THRESHOLD_HOURS = 48; // 警报阈值（小时）
const ALERT_COOLDOWN_HOURS = 24; // 警报冷却时间（小时）
```

## 数据库结构

### users 表
```sql
CREATE TABLE users (
  id INTEGER PRIMARY KEY,
  email TEXT UNIQUE NOT NULL,
  password TEXT NOT NULL,
  device_id TEXT UNIQUE NOT NULL,
  emergency_email TEXT NOT NULL,
  smtp_host TEXT,
  smtp_port INTEGER,
  smtp_username TEXT,
  smtp_password TEXT,
  created_at DATETIME,
  updated_at DATETIME
);
```

### checkins 表
```sql
CREATE TABLE checkins (
  id INTEGER PRIMARY KEY,
  user_id INTEGER NOT NULL,
  checkin_time DATETIME,
  FOREIGN KEY (user_id) REFERENCES users(id)
);
```

### alerts 表
```sql
CREATE TABLE alerts (
  id INTEGER PRIMARY KEY,
  user_id INTEGER NOT NULL,
  sent_time DATETIME,
  status TEXT,
  FOREIGN KEY (user_id) REFERENCES users(id)
);
```

## 部署到云服务器

### 使用 PM2（推荐）

1. 安装 PM2：
```bash
npm install -g pm2
```

2. 启动服务：
```bash
cd backend
pm2 start src/server.js --name silema-backend
```

3. 设置开机自启：
```bash
pm2 startup
pm2 save
```

4. 查看日志：
```bash
pm2 logs silema-backend
```

5. 重启服务：
```bash
pm2 restart silema-backend
```

### 使用 systemd

创建服务文件 `/etc/systemd/system/silema-backend.service`：

```ini
[Unit]
Description=Silema Backend API
After=network.target

[Service]
Type=simple
User=your-user
WorkingDirectory=/path/to/backend
ExecStart=/usr/bin/node src/server.js
Restart=always
RestartSec=10
Environment=NODE_ENV=production
Environment=PORT=3000

[Install]
WantedBy=multi-user.target
```

启动服务：
```bash
sudo systemctl daemon-reload
sudo systemctl enable silema-backend
sudo systemctl start silema-backend
```

## 配置Nginx反向代理

```nginx
server {
    listen 80;
    server_name your-domain.com;

    location /api/ {
        proxy_pass http://localhost:3000/api/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_cache_bypass $http_upgrade;
    }
}
```

## 安全建议

1. **生产环境必须修改JWT密钥**
2. **使用HTTPS**（配置SSL证书）
3. **限制API访问频率**（添加rate limiting）
4. **定期备份数据库文件**（`data/silema.db`）
5. **使用强密码策略**
6. **配置防火墙**，仅开放必要端口

## 常见问题

### 1. 邮件发送失败
- 检查SMTP配置是否正确
- 某些邮箱服务需要使用"应用专用密码"而非账号密码
- 确认SMTP端口和加密设置

### 2. 数据库文件不存在
数据库会自动创建在 `backend/data/silema.db`

### 3. 定时任务不执行
检查服务器时区设置，确保系统时间正确

## 目录结构

```
backend/
├── src/
│   ├── routes/
│   │   ├── auth.js          # 认证路由
│   │   └── checkin.js       # 签到路由
│   ├── models/
│   │   └── database.js      # 数据库模型
│   ├── middleware/
│   │   └── auth.js          # JWT中间件
│   ├── utils/
│   │   ├── emailService.js  # 邮件服务
│   │   └── checkService.js  # 检查服务
│   └── server.js            # 主服务器
├── data/                    # 数据库文件（自动创建）
├── .env                     # 环境变量
├── package.json
└── README.md
```

## 技术栈

- **Node.js** - JavaScript运行时
- **Express** - Web框架
- **SQLite** - 数据库（better-sqlite3）
- **JWT** - 认证
- **bcryptjs** - 密码加密
- **nodemailer** - 邮件发送
- **node-cron** - 定时任务

## 许可证

MIT
