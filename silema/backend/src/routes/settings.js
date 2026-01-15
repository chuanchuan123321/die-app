import express from 'express';
import { dbHelpers } from '../models/database.js';
import { authenticateToken } from '../middleware/auth.js';

const router = express.Router();

// 获取用户设置
router.get('/', authenticateToken, (req, res) => {
  try {
    const user = dbHelpers.getUserByEmail(req.user.email);
    if (!user) {
      return res.status(404).json({ error: '用户不存在' });
    }

    const settings = dbHelpers.getUserSettings(user.id);

    res.json({
      alertThresholdMinutes: settings?.alert_threshold_minutes || (48 * 60), // 默认48小时，转换为分钟
      enableEmailAlert: settings?.enable_email_alert === 1,
      enableSmsAlert: settings?.enable_sms_alert === 1,
    });
  } catch (error) {
    console.error('Get settings error:', error);
    res.status(500).json({ error: '获取用户设置失败' });
  }
});

// 更新用户设置
router.put('/', authenticateToken, (req, res) => {
  try {
    const { alertThresholdMinutes, enableEmailAlert, enableSmsAlert } = req.body;

    // 验证阈值范围（最大30天）
    if (alertThresholdMinutes !== undefined) {
      if (alertThresholdMinutes < 1) {
        return res.status(400).json({ error: '时间阈值不能少于1分钟' });
      }
      if (alertThresholdMinutes > 30 * 24 * 60) {
        return res.status(400).json({ error: '时间阈值不能超过30天' });
      }
    }

    const user = dbHelpers.getUserByEmail(req.user.email);
    if (!user) {
      return res.status(404).json({ error: '用户不存在' });
    }

    // 检查设置是否存在
    const existingSettings = dbHelpers.getUserSettings(user.id);

    if (existingSettings) {
      // 更新现有设置
      dbHelpers.updateUserSettings(user.id, {
        alertThresholdMinutes: alertThresholdMinutes ?? existingSettings.alert_threshold_minutes,
        enableEmailAlert: enableEmailAlert ?? (existingSettings.enable_email_alert === 1),
        enableSmsAlert: enableSmsAlert ?? (existingSettings.enable_sms_alert === 1),
      });
    } else {
      // 创建新设置
      dbHelpers.createUserSettings(user.id, {
        alertThresholdMinutes: alertThresholdMinutes ?? (48 * 60),
      });
    }

    res.json({ message: '用户设置已更新' });
  } catch (error) {
    console.error('Update settings error:', error);
    res.status(500).json({ error: '更新用户设置失败' });
  }
});

export default router;
