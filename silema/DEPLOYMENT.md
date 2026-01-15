# "死了吗" 完整部署指南

本文档介绍如何部署"死了吗"应用的后端服务器和前端应用。

## 系统架构

```
┌─────────────┐      API请求      ┌─────────────┐
│             │ ─────────────────> │             │
│  Flutter App│                    │  Node.js    │
│             │ <───────────────── │   Backend   │
└─────────────┘      响应数据      └─────────────┘
                                          │
                                          ▼
                                  ┌─────────────┐
                                  │  SQLite DB  │
                                  └─────────────┘
                                          │
                                          ▼
                                  ┌─────────────┐
                                  │ SMTP Server │
                                  └─────────────┘
```

## 第一部分：后端部署

### 1. 服务器准备

推荐配置：
- **CPU**: 1核
- **内存**: 512MB - 1GB
- **硬盘**: 10GB+
- **操作系统**: Ubuntu 20.04+ / CentOS 7+ / Debian 10+
- **Node.js**: 16.x 或更高版本

### 2. 安装Node.js

**Ubuntu/Debian:**
```bash
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs
```

**CentOS:**
```bash
curl -fsSL https://rpm.nodesource.com/setup_18.x | sudo bash -
sudo yum install -y nodejs
```

验证安装：
```bash
node -v  # 应显示 v18.x.x
npm -v
```

### 3. 部署后端代码

```bash
# 克隆或上传代码
cd /opt
mkdir -p silema
cd silema

# 将backend目录上传到服务器
# 方式1: 使用scp
# scp -r backend/ user@your-server:/opt/silema/

# 方式2: 使用git（如果代码在git仓库）
# git clone your-repo-url .

cd backend
npm install
```

### 4. 配置环境变量

```bash
cp .env.example .env
nano .env
```

修改以下配置：
```env
PORT=3000
JWT_SECRET=your-super-secret-jwt-key-change-in-production-12345
NODE_ENV=production
```

**重要**: JWT_SECRET必须是一个强随机字符串！

### 5. 启动服务

**方式1: 使用PM2（推荐）**

```bash
# 安装PM2
sudo npm install -g pm2

# 启动应用
pm2 start src/server.js --name silema-backend

# 设置开机自启
pm2 startup
# 按照提示执行命令
pm2 save

# 查看状态
pm2 status

# 查看日志
pm2 logs silema-backend

# 重启服务
pm2 restart silema-backend
```

**方式2: 使用systemd**

创建服务文件：
```bash
sudo nano /etc/systemd/system/silema-backend.service
```

内容：
```ini
[Unit]
Description=Silema Backend API
After=network.target

[Service]
Type=simple
User=your-username
WorkingDirectory=/opt/silema/backend
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
sudo systemctl status silema-backend
```

### 6. 配置Nginx反向代理（可选但推荐）

安装Nginx：
```bash
sudo apt install nginx  # Ubuntu/Debian
# 或
sudo yum install nginx  # CentOS
```

创建配置文件：
```bash
sudo nano /etc/nginx/sites-available/silema-api
```

内容：
```nginx
server {
    listen 80;
    server_name your-domain.com;  # 修改为你的域名或服务器IP

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

启用配置：
```bash
sudo ln -s /etc/nginx/sites-available/silema-api /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```

### 7. 配置防火墙

```bash
# Ubuntu/Debian
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable

# CentOS
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https
sudo firewall-cmd --permanent --add-port=22/tcp
sudo firewall-cmd --reload
```

### 8. 配置SSL证书（可选但推荐）

使用Let's Encrypt免费证书：
```bash
sudo apt install certbot python3-certbot-nginx
sudo certbot --nginx -d your-domain.com
```

### 9. 验证部署

访问健康检查接口：
```bash
curl http://your-domain.com/api/health
```

应返回：
```json
{
  "status": "ok",
  "timestamp": "2024-01-13T12:00:00.000Z"
}
```

### 10. 数据库备份

创建定时备份任务：
```bash
crontab -e
```

添加（每天凌晨2点备份）：
```
0 2 * * * cp /opt/silema/backend/data/silema.db /opt/silema/backups/silema_$(date +\%Y\%m\%d).db
```

创建备份目录：
```bash
mkdir -p /opt/silema/backups
```

## 第二部分：Flutter应用配置

### 1. 安装依赖

```bash
cd /path/to/silema
flutter pub get
```

### 2. 配置API服务器地址

编辑 `lib/services/api_service.dart`：

```dart
static String baseUrl = 'http://your-domain.com/api';  // 修改为你的服务器地址
```

或使用HTTPS：
```dart
static String baseUrl = 'https://your-domain.com/api';
```

### 3. 构建Android APK

```bash
# Debug版本
flutter build apk

# Release版本
flutter build apk --release

# App Bundle（用于发布到Google Play）
flutter build appbundle --release
```

生成的文件位置：
- APK: `build/app/outputs/flutter-apk/app-release.apk`
- App Bundle: `build/app/outputs/bundle/release/app-release.aab`

### 4. 安装测试

```bash
# 连接Android设备
flutter devices

# 安装并运行
flutter install
flutter run
```

## 第三部分：使用流程

### 用户注册流程

1. 用户打开App
2. 进入注册页面
3. 填写：
   - 邮箱（用于登录）
   - 密码
   - 紧急联系人邮箱（接收警报）
4. 提交注册

### 配置SMTP（发送邮件必需）

1. 登录App
2. 进入设置页面
3. 配置SMTP服务器信息：
   - SMTP主机（如：smtp.gmail.com）
   - 端口（587或465）
   - 用户名（邮箱地址）
   - 密码（或应用专用密码）

**常用SMTP配置：**

**QQ邮箱:**
- 主机: smtp.qq.com
- 端口: 587
- 需要开启SMTP服务并获取授权码

**Gmail:**
- 主机: smtp.gmail.com
- 端口: 587
- 需要使用应用专用密码

**163邮箱:**
- 主机: smtp.163.com
- 端口: 465
- 需要开启SMTP服务并获取授权码

### 日常签到流程

1. 用户每天打开App
2. 点击中央"签到"按钮
3. 系统记录签到时间到服务器
4. 后端定时任务每小时检查所有用户
5. 发现超过48小时未签到的用户，发送邮件到紧急联系人

## 第四部分：维护和监控

### 查看日志

**PM2:**
```bash
pm2 logs silema-backend
```

**systemd:**
```bash
journalctl -u silema-backend -f
```

### 监控服务状态

创建监控脚本：
```bash
nano /opt/silema/monitor.sh
```

内容：
```bash
#!/bin/bash
curl -f http://localhost:3000/health || echo "Service down!" | mail -s "Alert" admin@example.com
```

添加到crontab（每5分钟检查一次）：
```
*/5 * * * * /opt/silema/monitor.sh
```

### 数据库管理

**查看数据:**
```bash
sqlite3 /opt/silema/backend/data/silema.db
```

常用SQL命令：
```sql
.tables                  -- 查看所有表
.schema users            -- 查看users表结构
SELECT * FROM users;     -- 查看所有用户
SELECT * FROM checkins ORDER BY checkin_time DESC LIMIT 10;  -- 查看最近10次签到
```

## 第五部分：故障排查

### 问题1: 端口被占用
```bash
sudo lsof -i :3000
sudo kill -9 PID
```

### 问题2: 邮件发送失败
- 检查SMTP配置是否正确
- 确认邮箱是否开启了SMTP服务
- 某些邮箱需要使用"应用专用密码"而非登录密码
- 检查服务器防火墙是否允许SMTP端口

### 问题3: API无法访问
- 检查后端服务是否运行：`pm2 status`
- 检查端口是否开放：`sudo netstat -tlnp | grep 3000`
- 检查Nginx配置：`sudo nginx -t`
- 查看错误日志：`pm2 logs silema-backend --err`

### 问题4: 定时任务不执行
- 检查服务器时区：`date`
- 查看服务日志确认定时任务是否触发
- 手动执行检查服务确认逻辑正确

## 安全建议

1. **定期更新系统和Node.js**
   ```bash
   sudo apt update && sudo apt upgrade
   ```

2. **修改默认JWT密钥**
   - 使用强随机字符串
   - 定期更换

3. **启用HTTPS**
   - 使用Let's Encrypt免费证书
   - 强制HTTPS重定向

4. **限制API访问频率**
   - 添加express-rate-limit中间件

5. **定期备份数据库**
   - 每天自动备份
   - 保留最近30天的备份

6. **监控异常活动**
   - 监控登录失败次数
   - 监控API调用频率

## 成本估算

### 服务器成本（推荐配置）

| 供应商 | 配置 | 月费 | 年费 |
|--------|------|------|------|
| 阿里云 | 1核1GB | ¥30-50 | ¥300-500 |
| 腾讯云 | 1核1GB | ¥30-50 | ¥300-500 |
| Vultr | 1核1GB | $5-6 | $60-72 |
| DigitalOcean | 1核1GB | $6 | $72 |

### 免费选项

- **Railway**: 每月$5免费额度
- **Render**: 免费套餐（有休眠限制）
- **Fly.io**: 免费套餐有限额

## 技术支持

如有问题，请检查：
1. 后端README: `backend/README.md`
2. API文档（见下文）
3. GitHub Issues（如果代码在GitHub）

---

## 附录：API接口文档

### 基础信息

- **Base URL**: `http://your-domain.com/api`
- **认证方式**: Bearer Token (JWT)
- **数据格式**: JSON

### 认证接口

#### 1. 注册
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

响应：
```json
{
  "message": "注册成功",
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": 1,
    "email": "user@example.com",
    "emergencyEmail": "emergency@example.com"
  }
}
```

#### 2. 登录
```http
POST /api/auth/login
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "password123"
}
```

#### 3. 获取用户信息
```http
GET /api/auth/me
Authorization: Bearer <token>
```

#### 4. 更新SMTP配置
```http
PUT /api/auth/smtp
Authorization: Bearer <token>
Content-Type: application/json

{
  "host": "smtp.gmail.com",
  "port": 587,
  "username": "your-email@gmail.com",
  "password": "your-password"
}
```

#### 5. 更新紧急联系人
```http
PUT /api/auth/emergency-email
Authorization: Bearer <token>
Content-Type: application/json

{
  "emergencyEmail": "new-emergency@example.com"
}
```

### 签到接口

#### 1. 签到
```http
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

#### 2. 获取最后签到时间
```http
GET /api/checkin/last
Authorization: Bearer <token>
```

#### 3. 获取签到统计
```http
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

#### 4. 获取最近签到记录
```http
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
    }
  ]
}
```

### 健康检查

```http
GET /health
```

响应：
```json
{
  "status": "ok",
  "timestamp": "2024-01-13T12:00:00.000Z"
}
```

---

**部署完成后，您就拥有了一个功能完整的"死了吗"应用！** 🎉
