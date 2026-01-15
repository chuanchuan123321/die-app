import express from 'express';
import bcrypt from 'bcryptjs';
import { dbHelpers } from '../models/database.js';
import { generateToken, authenticateToken } from '../middleware/auth.js';
import { sendAlertEmail } from '../utils/emailService.js';

const router = express.Router();

// 注册
router.post('/register', async (req, res) => {
  try {
    const { email, password, deviceId, name } = req.body;

    // 验证必填字段
    if (!email || !password || !deviceId || !name) {
      return res.status(400).json({ error: '请填写所有必填字段' });
    }

    // 验证邮箱格式
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
      return res.status(400).json({ error: '邮箱格式不正确' });
    }

    // 检查邮箱是否已存在
    const existingUser = dbHelpers.getUserByEmail(email);
    if (existingUser) {
      return res.status(400).json({ error: '该邮箱已被注册' });
    }

    // 检查设备ID是否已存在
    const existingDevice = dbHelpers.getUserByDeviceId(deviceId);
    if (existingDevice) {
      return res.status(400).json({ error: '该设备已注册' });
    }

    // 加密密码
    const hashedPassword = await bcrypt.hash(password, 10);

    // 创建用户
    dbHelpers.createUser(email, hashedPassword, deviceId, name);
    const user = dbHelpers.getUserByEmail(email);

    // 生成JWT
    const token = generateToken(user);

    res.status(201).json({
      message: '注册成功',
      token,
      user: {
        id: user.id,
        email: user.email,
        name: user.name,
      }
    });
  } catch (error) {
    console.error('Register error:', error);
    res.status(500).json({ error: '注册失败', message: error.message });
  }
});

// 登录
router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({ error: '请提供邮箱和密码' });
    }

    // 查找用户
    const user = dbHelpers.getUserByEmail(email);
    if (!user) {
      return res.status(401).json({ error: '邮箱或密码错误' });
    }

    // 验证密码
    const validPassword = await bcrypt.compare(password, user.password);
    if (!validPassword) {
      return res.status(401).json({ error: '邮箱或密码错误' });
    }

    // 生成JWT
    const token = generateToken(user);

    res.json({
      message: '登录成功',
      token,
      user: {
        id: user.id,
        email: user.email,
        emergencyEmail: user.emergency_email,
      }
    });
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ error: '登录失败', message: error.message });
  }
});

// 设备ID登录（简化流程）
router.post('/login-device', async (req, res) => {
  try {
    const { deviceId } = req.body;

    if (!deviceId) {
      return res.status(400).json({ error: '请提供设备ID' });
    }

    const user = dbHelpers.getUserByDeviceId(deviceId);
    if (!user) {
      return res.status(404).json({ error: '设备未注册' });
    }

    const token = generateToken(user);

    res.json({
      message: '登录成功',
      token,
      user: {
        id: user.id,
        email: user.email,
        emergencyEmail: user.emergency_email,
      }
    });
  } catch (error) {
    console.error('Login device error:', error);
    res.status(500).json({ error: '登录失败', message: error.message });
  }
});

// 获取用户信息
router.get('/me', authenticateToken, (req, res) => {
  try {
    const user = dbHelpers.getUserByEmail(req.user.email);
    if (!user) {
      return res.status(404).json({ error: '用户不存在' });
    }

    res.json({
      id: user.id,
      email: user.email,
      name: user.name || '',
      emergencyEmail: user.emergency_email,
      hasSmtpConfig: !!(user.smtp_host && user.smtp_username && user.smtp_password),
    });
  } catch (error) {
    console.error('Get user error:', error);
    res.status(500).json({ error: '获取用户信息失败' });
  }
});

// 更新SMTP配置
router.put('/smtp', authenticateToken, (req, res) => {
  try {
    const { host, port, username, password } = req.body;

    if (!host || !port || !username || !password) {
      return res.status(400).json({ error: '请填写所有SMTP配置' });
    }

    const user = dbHelpers.getUserByEmail(req.user.email);

    if (!user) {
      console.error('User not found:', req.user.email);
      return res.status(404).json({ error: '用户不存在' });
    }

    dbHelpers.updateUserSmtp(user.id, { host, port, username, password });

    res.json({ message: 'SMTP配置已更新' });
  } catch (error) {
    console.error('Update SMTP error:', error);
    res.status(500).json({ error: '更新SMTP配置失败' });
  }
});

// 更新紧急联系人邮箱
router.put('/emergency-email', authenticateToken, (req, res) => {
  try {
    const { emergencyEmail } = req.body;

    if (!emergencyEmail) {
      return res.status(400).json({ error: '请提供紧急联系人邮箱' });
    }

    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(emergencyEmail)) {
      return res.status(400).json({ error: '邮箱格式不正确' });
    }

    const user = dbHelpers.getUserByEmail(req.user.email);
    dbHelpers.updateUserEmergencyEmail(user.id, emergencyEmail);

    res.json({ message: '紧急联系人邮箱已更新' });
  } catch (error) {
    console.error('Update emergency email error:', error);
    res.status(500).json({ error: '更新紧急联系人邮箱失败' });
  }
});

// 测试邮件发送
router.post('/test-email', authenticateToken, async (req, res) => {
  try {
    const user = dbHelpers.getUserByEmail(req.user.email);
    if (!user) {
      return res.status(404).json({ error: '用户不存在' });
    }

    // 检查是否配置了SMTP
    if (!user.smtp_host || !user.smtp_username || !user.smtp_password) {
      return res.status(400).json({ error: '请先配置SMTP' });
    }

    // 获取紧急联系人列表
    const contacts = dbHelpers.getEmergencyContacts(user.id);

    if (contacts.length === 0) {
      return res.status(400).json({ error: '请先添加紧急联系人' });
    }

    // 获取用户设置
    const settings = dbHelpers.getUserSettings(user.id);
    const alertThresholdMinutes = settings?.alert_threshold_minutes || 2880;

    // 获取用户实际的最后签到时间
    const lastCheckin = dbHelpers.getLastCheckin(user.id);

    let lastCheckInTime;
    if (lastCheckin) {
      // SQLite的CURRENT_TIMESTAMP返回UTC时间，格式 "YYYY-MM-DD HH:MM:SS"
      // 需要在末尾添加 "Z" 表示这是UTC时间
      lastCheckInTime = new Date(lastCheckin.checkin_time + 'Z');

      console.log('📊 Last check-in from DB:', lastCheckin.checkin_time);
      console.log('⏰ Parsed as UTC time:', lastCheckInTime.toString());
    } else {
      // 如果没有签到记录，创建一个虚拟时间（刚好超过阈值5分钟）
      lastCheckInTime = new Date();
      lastCheckInTime.setMinutes(lastCheckInTime.getMinutes() - alertThresholdMinutes - 5);
      console.log('⏰ Using virtual time (no checkins)');
    }

    // 向所有紧急联系人发送测试邮件
    let successCount = 0;
    let failCount = 0;
    const emailList = [];

    for (const contact of contacts) {
      // 创建包含联系人信息的用户对象
      const userWithContact = {
        ...user,
        emergency_email: contact.email,
        emergency_contact_name: contact.name,
      };

      const result = await sendAlertEmail(userWithContact, lastCheckInTime, alertThresholdMinutes);

      if (result.success) {
        successCount++;
        emailList.push(`${contact.name} (${contact.email})`);
      } else {
        failCount++;
      }
    }

    if (successCount > 0) {
      res.json({
        message: '测试邮件已发送',
        details: `成功发送到 ${successCount} 个联系人`,
        recipients: emailList,
        successCount,
        failCount,
      });
    } else {
      res.status(500).json({
        error: '发送失败',
        reason: '所有邮件发送失败'
      });
    }
  } catch (error) {
    console.error('Test email error:', error);
    res.status(500).json({ error: '发送测试邮件失败', message: error.message });
  }
});

// 删除账户
router.delete('/account', authenticateToken, async (req, res) => {
  try {
    const user = dbHelpers.getUserByEmail(req.user.email);
    if (!user) {
      return res.status(404).json({ error: '用户不存在' });
    }

    // 获取数据库连接并删除用户
    const { getDatabase, saveDatabase } = await import('../models/database.js');
    const db = getDatabase();

    // 删除用户（CASCADE会自动删除相关的签到记录、警报记录、紧急联系人和设置）
    const deleteStmt = db.prepare('DELETE FROM users WHERE id = ?');
    deleteStmt.bind([user.id]);
    deleteStmt.step();
    deleteStmt.free();

    // 保存数据库
    saveDatabase();

    console.log(`✅ User account deleted: ${user.email}`);
    res.json({ message: '账户已成功删除' });
  } catch (error) {
    console.error('Delete account error:', error);
    res.status(500).json({ error: '删除账户失败' });
  }
});

export default router;
