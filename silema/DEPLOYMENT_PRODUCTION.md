# 生产环境部署指南

## 问题说明

当前配置：
- ❌ Flutter应用：`http://10.0.2.2:3000` (仅模拟器可用)
- ❌ 后端服务器：运行在本地

生产环境需要：
- ✅ Flutter应用：`http://YOUR_SERVER_IP:3000` 或 `https://your-domain.com`
- ✅ 后端服务器：运行在云服务器上

## 方案1: 使用服务器IP地址（快速测试）

### 步骤1: 获取服务器IP地址

```bash
# 在服务器上运行
curl ifconfig.me
# 或
curl ipinfo.io/ip
```

假设您的服务器IP是：`123.45.67.89`

### 步骤2: 修改Flutter应用

编辑 `lib/services/api_service.dart`:

```dart
class ApiService {
  // 改为您的服务器IP
  static String baseUrl = 'http://123.45.67.89:3000/api';
  static String? _token;
  // ...
}
```

### 步骤3: 开放服务器防火墙

**阿里云/腾讯云：**
在控制台添加安全组规则：
- 端口：`3000`
- 协议：`TCP`
- 来源：`0.0.0.0/0`（允许所有IP访问）

**使用命令行：**
```bash
# 如果使用ufw
sudo ufw allow 3000/tcp

# 如果使用iptables
sudo iptables -A INPUT -p tcp --dport 3000 -j ACCEPT
```

### 步骤4: 测试连接

在手机浏览器访问：
```
http://123.45.67.89:3000/health
```

应该看到：
```json
{"status":"ok","timestamp":"..."}
```

### 步骤5: 重新安装应用

```bash
# 构建APK
flutter build apk --release

# 传输到手机并安装
# 或使用
flutter install
```

## 方案2: 使用域名 + HTTPS（推荐生产环境）

### 优点：
- ✅ 更安全（数据加密）
- ✅ 更专业
- ✅ 避免运营商限制HTTP

### 步骤1: 购买域名（可选）

从阿里云、腾讯云等购买域名

### 步骤2: 配置DNS

添加A记录：
```
@  A  123.45.67.89
```

或子域名：
```
api  A  123.45.67.89
```

### 步骤3: 安装Nginx

```bash
# Ubuntu/Debian
sudo apt update
sudo apt install nginx -y
```

### 步骤4: 配置Nginx

创建配置文件：
```bash
sudo nano /etc/nginx/sites-available/silema-api
```

内容：
```nginx
server {
    listen 80;
    server_name your-domain.com;  # 改为您的域名

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

### 步骤5: 配置SSL证书（免费）

使用Let's Encrypt：
```bash
sudo apt install certbot python3-certbot-nginx -y
sudo certbot --nginx -d your-domain.com
```

### 步骤6: 修改Flutter应用

```dart
class ApiService {
  // 使用HTTPS
  static String baseUrl = 'https://your-domain.com/api';
  static String? _token;
  // ...
}
```

### 步骤7: 配置Android允许HTTP（如果只用HTTP）

编辑 `android/app/src/main/AndroidManifest.xml`：

```xml
<application
    android:usesCleartextTraffic="true"
    ...>
```

## 方案3: 环境变量配置（推荐）

让API地址可配置，避免每次修改代码。

### 步骤1: 创建配置文件

创建 `lib/config/app_config.dart`:

```dart
class AppConfig {
  // 根据构建模式自动选择
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:3000/api', // 开发默认值
  );
}
```

### 步骤2: 修改API服务

```dart
import 'app_config.dart';

class ApiService {
  static String baseUrl = AppConfig.apiBaseUrl;
  // ...
}
```

### 步骤3: 构建时指定API地址

**开发环境：**
```bash
flutter run
```

**生产环境：**
```bash
flutter build apk --release --dart-define=API_BASE_URL=https://your-domain.com/api
```

## 完整部署清单

### 服务器端

- [ ] 安装Node.js (v16+)
- [ ] 安装依赖 `npm install`
- [ ] 配置环境变量 `.env`
- [ ] 开放防火墙端口3000
- [ ] 使用PM2启动服务 `pm2 start src/server.js --name silema`
- [ ] 配置开机自启 `pm2 startup && pm2 save`
- [ ] 测试API `curl http://localhost:3000/health`

### 应用端

- [ ] 修改API地址为服务器IP/域名
- [ ] 构建Release APK `flutter build apk --release`
- [ ] 传输APK到手机
- [ ] 安装应用
- [ ] 测试登录功能
- [ ] 测试签到功能
- [ ] 配置SMTP
- [ ] 发送测试邮件

### 验证测试

- [ ] 手机可以访问服务器API
- [ ] 注册新用户成功
- [ ] 登录成功
- [ ] 签到成功
- [ ] 配置SMTP成功
- [ ] 测试邮件发送成功
- [ ] 后端日志正常

## 常见问题

### Q: 手机无法连接服务器？

**A:** 检查：
1. 服务器防火墙是否开放3000端口
2. 手机和服务器是否在同一网络（测试时）
3. API地址是否正确（http://IP:3000）
4. 浏览器能否访问 `http://IP:3000/health`

### Q: 连接超时？

**A:** 可能原因：
1. 服务器IP地址错误
2. 防火墙未开放端口
3. 服务器未运行
4. 网络不通

### Q: HTTPS证书错误？

**A:**
1. 确保域名DNS已生效
2. 检查证书是否过期
3. 使用 `https://` 而非 `http://`

### Q: 真机安装失败？

**A:**
1. 允许安装来自未知来源的应用
2. 卸载旧版本再安装新版本
3. 检查APK文件是否完整

## 快速命令参考

**服务器端：**
```bash
# 上传代码到服务器
scp -r backend/ user@123.45.67.89:/opt/silema/

# SSH登录服务器
ssh user@123.45.67.89

# 启动服务
cd /opt/silema/backend
npm install
pm2 start src/server.js --name silema
pm2 logs silema

# 查看防火墙状态
sudo ufw status
```

**应用端：**
```bash
# 构建APK
flutter build apk --release --dart-define=API_BASE_URL=http://123.45.67.89:3000/api

# 查看生成的APK
ls -lh build/app/outputs/flutter-apk/
```

## 安全提醒

⚠️ **生产环境必须注意：**

1. **修改JWT密钥** - 使用强随机字符串
2. **启用HTTPS** - 保护数据传输安全
3. **配置CORS** - 限制跨域访问来源
4. **定期备份** - 备份数据库文件
5. **监控日志** - 及时发现异常
6. **更新依赖** - 修复安全漏洞
