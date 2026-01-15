# 🚀 完整部署指南 - 从本地到云端

## 目标
- ✅ 后端运行在云服务器上
- ✅ 手机应用连接到云端后端
- ✅ 24/7自动运行，随时可以签到

---

## 第一部分：购买和准备云服务器

### 步骤1: 购买云服务器

推荐以下任意一个（都很便宜）：

#### 选项A: 阿里云（推荐国内用户）
1. 访问：https://www.aliyun.com
2. 注册账号
3. 购买 ECS 云服务器
4. 配置选择：
   - CPU：1核
   - 内存：1GB 或 2GB
   - 系统：Ubuntu 20.04 或 22.04
   - 带宽：1Mbps（按流量计费更省钱）
   - 价格：约 ¥30-50/月

#### 选项B: 腾讯云
1. 访问：https://cloud.tencent.com
2. 购买 CVM 云服务器
3. 配置同上

#### 选项C: Vultr（国外，简单快速）
1. 访问：https://www.vultr.com
2. 注册账号
3. 部署服务器，选择：
   - Server Type：Regular Performance
   - Server Location：Tokyo（距离近）或 Singapore
   - Server Size：$5/month（1GB RAM）
   - Server Image：Ubuntu 22.04 x64
   - 价格：$5/月（约¥35）

#### 选项D: DigitalOcean
1. 访问：https://www.digitalocean.com
2. 注册账号
3. 创建 Droplet：
   - Basic Plan：$6/月
   - Region：Singapore
   - Image：Ubuntu 22.04 LTS

---

## 第二部分：连接和配置服务器

### 步骤2: 获取服务器信息

购买成功后，您会得到：
- **公网IP地址**：例如 `123.45.67.89`
- **root密码**：临时密码
- **SSH密钥**（如果选择了）

### 步骤3: 连接到服务器

#### Mac/Linux 用户：
打开终端，输入：
```bash
ssh root@YOUR_SERVER_IP
# 例如：ssh root@123.45.67.89
```

输入密码（输入时不会显示，直接粘贴或输入后回车）

#### Windows 用户：
下载工具：
- **推荐**：MobaXterm（https://mobaxterm.mobatek.net）
- 或 PuTTY（https://www.putty.org）

连接信息：
- Host：`123.45.67.89`
- Port：`22`
- Username：`root`
- Password：您设置的密码

### 步骤4: 更新服务器

连接成功后，运行：
```bash
apt update && apt upgrade -y
```

### 步骤5: 安装Node.js

```bash
# 安装Node.js 18.x
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt install -y nodejs

# 验证安装
node -v  # 应显示 v18.x.x
npm -v
```

---

## 第三部分：上传后端代码

### 步骤6: 在服务器上创建项目目录

```bash
mkdir -p /opt/silema
cd /opt/silema
```

### 步骤7: 上传代码到服务器

**方法A: 使用SCP（推荐，适合小文件）**

在您的**本地电脑**（Mac/Linux）终端执行：
```bash
cd /Users/a1-6/Desktop/silema

# 只上传backend目录
scp -r backend/ root@123.45.67.89:/opt/silema/
```

**方法B: 使用Git（如果代码在GitHub）**

在服务器上执行：
```bash
cd /opt/silema
git clone YOUR_REPO_URL
```

**方法C: 手动创建文件**

1. 在服务器上创建文件：
```bash
cd /opt/silema/backend
nano package.json
```

2. 复制 `backend/package.json` 的内容粘贴进去
3. 按 `Ctrl+X`，然后 `Y`，然后 `Enter` 保存

4. 对所有 `.js` 文件重复此步骤

**方法D: 使用SFTP工具（Windows推荐）**

使用 FileZilla 或 WinSCP：
- Host：`123.45.67.89`
- Port：`22`
- Username：`root`
- Password：您的密码
- 直接拖拽 `backend` 文件夹到服务器

### 步骤8: 安装依赖

在**服务器**上执行：
```bash
cd /opt/silema/backend
npm install
```

---

## 第四部分：配置和启动后端

### 步骤9: 配置环境变量

在服务器上创建 `.env` 文件：
```bash
cd /opt/silema/backend
nano .env
```

粘贴以下内容：
```env
PORT=3000
JWT_SECRET=your-super-secret-jwt-key-change-this-to-random-string-12345
NODE_ENV=production
```

**重要**：将 `JWT_SECRET` 改成一个强随机字符串！

保存并退出（`Ctrl+X`，`Y`，`Enter`）

### 步骤10: 安装PM2（进程管理器）

```bash
npm install -g pm2
```

### 步骤11: 启动后端服务

```bash
cd /opt/silema/backend
pm2 start src/server.js --name silema
```

您会看到：
```
┌────┬──────────┬──────────┬──────────┬──────────┬─────────┐
│ id │ name     │ version  │ mode     │ status   │ cpu     │
├────┼──────────┼──────────┼──────────┼──────────┼─────────┤
│ 0  │ silema   │ 1.0.0    │ fork     │ online   │ 0%      │
└────┴──────────┴──────────┴──────────┴──────────┴─────────┘
```

### 步骤12: 设置开机自启

```bash
pm2 startup
# 根据提示执行命令，例如：
# sudo env PATH=$PATH:/usr/bin pm2 startup systemd -u root --hp /root

pm2 save
```

### 步骤13: 验证服务运行

在**服务器**上测试：
```bash
curl http://localhost:3000/health
```

应返回：
```json
{"status":"ok","timestamp":"..."}
```

---

## 第五部分：配置防火墙

### 步骤14: 开放3000端口

**在服务器上执行：**

```bash
# 使用ufw（Ubuntu默认防火墙）
ufw allow 22/tcp   # SSH
ufw allow 3000/tcp # 后端API
ufw enable

# 查看状态
ufw status
```

**或在云服务商控制台配置安全组：**

1. 登录阿里云/腾讯云控制台
2. 找到您的服务器实例
3. 点击"安全组"或"防火墙"
4. 添加规则：
   - 端口范围：`3000`
   - 协议：`TCP`
   - 来源：`0.0.0.0/0`（允许所有IP访问）
5. 保存

### 步骤15: 测试外部访问

在您的**电脑浏览器**访问：
```
http://123.45.67.89:3000/health
```

应该看到：
```json
{"status":"ok","timestamp":"..."}
```

---

## 第六部分：构建和安装手机应用

### 步骤16: 修改API地址

#### 方法A: 使用构建脚本（推荐）

在您的**本地电脑**上：
```bash
cd /Users/a1-6/Desktop/silema
./build.sh http://123.45.67.89:3000/api
```

#### 方法B: 手动修改配置

编辑 `lib/config/app_config.dart`：
```dart
static const String apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://123.45.67.89:3000/api', // 👈 改为您的服务器IP
);
```

然后构建：
```bash
flutter build apk --release
```

### 步骤17: 获取APK文件

生成的文件位置：
```
/Users/a1-6/Desktop/silema/build/app/outputs/flutter-apk/app-release.apk
```

### 步骤18: 传输APK到手机

**方法A: 微信/QQ**
1. 将APK文件发送到"我的电脑"或"文件传输助手"
2. 手机微信/QQ接收并下载
3. 点击安装

**方法B: 云盘**
1. 上传到百度网盘/阿里云盘
2. 手机登录云盘下载
3. 点击安装

**方法C: 数据线**
1. 用USB线连接手机
2. 将APK文件复制到手机
3. 在文件管理器中点击安装

### 步骤19: 允许安装未知来源应用

**Android设置：**
- 设置 → 安全 → 允许安装未知来源应用
- Android 8+：设置 → 应用和通知 → 特殊应用权限 → 安装未知应用

---

## 第七部分：测试完整流程

### 步骤20: 打开手机应用

1. ✅ 启动应用
2. ✅ 应该看到登录页面
3. ✅ 注册新用户（填写邮箱、密码、紧急联系人）
4. ✅ 点击注册 → 应该成功并跳转主页

### 步骤21: 测试签到

1. ✅ 点击中央红色"签到"按钮
2. ✅ 看到签到成功动画
3. ✅ 状态显示最后签到时间

### 步骤22: 配置SMTP邮件

1. ✅ 点击右上角设置图标
2. ✅ 配置SMTP（推荐使用Gmail）
3. ✅ 点击"保存SMTP配置"
4. ✅ 点击"发送测试邮件"
5. ✅ 检查紧急联系人邮箱是否收到

### 步骤23: 验证后端记录

在**服务器**上查看日志：
```bash
pm2 logs silema --lines 20
```

您应该能看到：
- 注册请求日志
- 签到请求日志
- SMTP配置日志

---

## 第八部分：日常管理和维护

### 查看服务器状态

```bash
# SSH连接到服务器
ssh root@123.45.67.89

# 查看PM2进程状态
pm2 status

# 查看日志
pm2 logs silema

# 查看实时日志
pm2 logs silema --lines 100

# 重启服务
pm2 restart silema

# 停止服务
pm2 stop silema

# 启动服务
pm2 start silema
```

### 更新后端代码

当您修改了代码：

```bash
# 1. 在本地测试通过后，重新上传
scp -r backend/ root@123.45.67.89:/opt/silema/

# 2. SSH连接服务器
ssh root@123.45.67.89

# 3. 进入目录并重新安装依赖
cd /opt/silema/backend
npm install

# 4. 重启服务
pm2 restart silema
```

### 备份数据库

```bash
# 创建备份目录
mkdir -p /opt/silema/backups

# 备份数据库
cp /opt/silema/backend/data/silema.db /opt/silema/backups/silema_$(date +%Y%m%d).db

# 设置自动备份（每天凌晨2点）
crontab -e

# 添加以下行：
0 2 * * * cp /opt/silema/backend/data/silema.db /opt/silema/backups/silema_$(date +\%Y\%m\%d).db
```

---

## 常见问题排查

### Q1: 手机无法连接服务器？

**检查清单：**
1. ✅ 服务器防火墙已开放3000端口
2. ✅ 云服务商安全组已开放3000端口
3. ✅ 后端服务正在运行：`pm2 status`
4. ✅ API地址正确：`http://IP:3000/api`
5. ✅ 手机能访问 `http://IP:3000/health`

**测试命令：**
```bash
# 在服务器上
curl http://localhost:3000/health

# 在电脑浏览器
http://123.45.67.89:3000/health
```

### Q2: 连接超时？

**可能原因：**
- 防火墙未开放端口
- 服务器IP地址错误
- 后端服务未运行
- 云服务商需要额外配置

**解决方法：**
```bash
# 检查服务是否运行
pm2 status

# 检查端口是否监听
netstat -tlnp | grep 3000

# 重启服务
pm2 restart silema
```

### Q3: 应用安装失败？

**Android 8+：**
1. 设置 → 应用和通知 → 特殊应用权限 → 安装未知应用
2. 允许来自此来源的应用

**Android 7及以下：**
1. 设置 → 安全 → 允许安装未知来源

### Q4: 如何更新应用？

1. 修改代码
2. 重新构建APK：`./build.sh http://123.45.67.89:3000/api`
3. 传输新APK到手机
4. 覆盖安装（会保留数据）

### Q5: 数据库在哪里？

**位置：** `/opt/silema/backend/data/silema.db`

**导出数据库：**
```bash
# 在服务器上
scp root@123.45.67.89:/opt/silema/backend/data/silema.db ./
```

---

## 安全建议

### 🔒 必须做的安全设置

1. **修改JWT密钥**
   ```env
   JWT_SECRET=生成一个强随机密码，包含字母数字符号
   ```

2. **定期备份数据库**
   ```bash
   # 每天自动备份
   crontab -e
   # 添加：0 2 * * * cp /opt/silema/backend/data/silema.db /opt/silema/backups/$(date +\%Y\%m\%d).db
   ```

3. **监控日志**
   ```bash
   pm2 logs silema
   ```

4. **更新系统**
   ```bash
   apt update && apt upgrade -y
   ```

5. **使用SSH密钥认证**（可选，更安全）
   ```bash
   # 在本地生成SSH密钥
   ssh-keygen -t rsa -b 4096

   # 将公钥复制到服务器
   ssh-copy-id root@123.45.67.89
   ```

---

## 成本估算

### 月度成本

| 服务商 | 配置 | 月费 | 年费 |
|--------|------|------|------|
| 阿里云 | 1核1GB | ¥30-50 | ¥360-600 |
| 腾讯云 | 1核1GB | ¥30-50 | ¥360-600 |
| Vultr | 1GB RAM | $5 (¥35) | $60 (¥420) |
| DigitalOcean | 1GB RAM | $6 (¥42) | $72 (¥504) |

**总成本：约 ¥30-50/月**

---

## 快速命令参考卡

### 服务器管理

```bash
# SSH连接
ssh root@YOUR_SERVER_IP

# 启动服务
pm2 start src/server.js --name silema

# 查看状态
pm2 status

# 查看日志
pm2 logs silema

# 重启服务
pm2 restart silema

# 查看防火墙
ufw status
```

### 本地构建

```bash
# 构建APK（替换IP）
./build.sh http://YOUR_IP:3000/api

# 或手动构建
flutter build apk --release --dart-define=API_BASE_URL=http://YOUR_IP:3000/api
```

---

## 完成检查清单

### 服务器端
- [ ] 购买云服务器
- [ ] 连接到服务器（SSH）
- [ ] 安装Node.js
- [ ] 上传后端代码
- [ ] 安装依赖（npm install）
- [ ] 配置.env文件
- [ ] 安装PM2
- [ ] 启动服务（pm2 start）
- [ ] 设置开机自启（pm2 startup）
- [ ] 开放防火墙（ufw allow 3000）
- [ ] 测试外部访问（curl）
- [ ] 测试注册API

### 应用端
- [ ] 修改API地址为服务器IP
- [ ] 构建Release APK
- [ ] 传输APK到手机
- [ ] 安装应用
- [ ] 测试注册
- [ ] 测试登录
- [ ] 测试签到
- [ ] 配置SMTP
- [ ] 发送测试邮件
- [ ] 检查紧急邮箱

---

## 下一步

部署成功后，您拥有：
- ✅ 24/7运行的后端服务器
- ✅ 随时可以签到的手机应用
- ✅ 自动邮件警报系统
- ✅ 完整的用户认证系统

---

**需要帮助？**
- 查看详细文档：`DEPLOYMENT_PRODUCTION.md`
- 查看快速指南：`README_QUICK_START.md`
- 查看邮件测试：`EMAIL_TEST_GUIDE.md`
