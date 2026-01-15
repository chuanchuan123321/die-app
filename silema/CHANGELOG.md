# 编译错误修复说明

## 问题

由于移除了 `mailer` 包（邮件发送现在在后端处理），但Flutter应用中还有一些旧的服务文件在使用它，导致编译错误。

## 已修复的内容

### 1. 删除的文件
- `lib/services/email_service.dart` - 旧的本地邮件发送服务
- `lib/services/check_service.dart` - 旧的本地检查服务

### 2. 更新的文件

**lib/pages/home_page.dart:**
- 移除了 `check_service.dart` 的导入
- 移除了 `CheckService.checkAndSendAlert()` 调用（现在由后端自动处理）
- 将 `CheckService.getHoursSinceLastCheckIn()` 替换为本地方法 `_getHoursSinceLastCheckIn()`

**lib/pages/settings_page.dart:**
- 完全重写，使用 API 而不是本地服务
- 从 `ApiService.getUserInfo()` 获取用户信息
- 使用 `ApiService.updateEmergencyEmail()` 更新紧急联系人
- 使用 `ApiService.updateSmtpConfig()` 更新SMTP配置
- 添加了"退出登录"功能

**lib/main.dart:**
- 添加了 `ApiService.init()` 初始化

## 现在的工作流程

### 之前（本地处理）
```
App打开 → CheckService检查 → 本地发送邮件
```

### 现在（云端处理）
```
用户签到 → API保存到数据库 → 后端定时检查 → 后端发送邮件
```

## 下一步

现在可以尝试重新编译运行：

```bash
flutter pub get
flutter run
```

注意：后端服务器需要先启动才能正常使用完整功能。

## 后端启动

```bash
cd backend
npm install
npm run dev
```

Flutter应用配置（`lib/services/api_service.dart`）：
```dart
static String baseUrl = 'http://localhost:3000/api';  // 本地开发
// 或
static String baseUrl = 'http://your-server-ip:3000/api';  // 远程服务器
```
