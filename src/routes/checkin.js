import express from 'express';
import { dbHelpers } from '../models/database.js';
import { authenticateToken } from '../middleware/auth.js';

const router = express.Router();

// 签到
router.post('/', authenticateToken, (req, res) => {
  try {
    const user = dbHelpers.getUserByEmail(req.user.email);

    // 创建签到记录
    dbHelpers.createCheckin(user.id);

    res.json({
      message: '签到成功',
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.error('Check-in error:', error);
    res.status(500).json({ error: '签到失败', message: error.message });
  }
});

// 获取最后签到时间
router.get('/last', authenticateToken, (req, res) => {
  try {
    const user = dbHelpers.getUserByEmail(req.user.email);
    const lastCheckin = dbHelpers.getLastCheckin(user.id);

    if (!lastCheckin) {
      return res.json({ lastCheckin: null });
    }

    res.json({
      lastCheckin: `${lastCheckin.checkin_time}Z`  // 添加Z表示UTC时间
    });
  } catch (error) {
    console.error('Get last check-in error:', error);
    res.status(500).json({ error: '获取最后签到时间失败' });
  }
});

// 获取签到统计
router.get('/stats', authenticateToken, (req, res) => {
  try {
    const user = dbHelpers.getUserByEmail(req.user.email);

    // 获取所有签到记录
    const allCheckins = dbHelpers.getRecentCheckins(user.id, 10000);

    // 计算连续签到天数（同一天多次签到只算1天）
    let consecutiveDays = 0;
    if (allCheckins.length > 0) {
      // 将所有签到记录转换为日期字符串并去重（同一天只保留一次）
      const uniqueDates = [
        ...new Set(
          allCheckins.map(c => {
            // SQLite的CURRENT_TIMESTAMP返回UTC时间
            const checkinDate = new Date(c.checkin_time + 'Z');
            return `${checkinDate.getFullYear()}-${String(checkinDate.getMonth() + 1).padStart(2, '0')}-${String(checkinDate.getDate()).padStart(2, '0')}`;
          })
        )
      ];

      // 按日期从新到旧排序
      uniqueDates.sort((a, b) => b.localeCompare(a));

      // 从今天开始向前检查连续天数
      const today = new Date();
      today.setHours(0, 0, 0, 0);
      const todayStr = `${today.getFullYear()}-${String(today.getMonth() + 1).padStart(2, '0')}-${String(today.getDate()).padStart(2, '0')}`;

      // 检查今天是否签到，如果没有签到，从昨天开始计算
      let startDate = today;
      if (!uniqueDates.includes(todayStr)) {
        startDate = new Date(today);
        startDate.setDate(startDate.getDate() - 1);
      }

      // 计算连续签到天数
      for (let i = 0; i < uniqueDates.length; i++) {
        const checkinDateStr = uniqueDates[i];
        const [year, month, day] = checkinDateStr.split('-').map(Number);
        const checkinDate = new Date(year, month - 1, day);
        checkinDate.setHours(0, 0, 0, 0);

        const diffDays = Math.round((startDate - checkinDate) / (1000 * 60 * 60 * 24));

        if (diffDays === consecutiveDays) {
          consecutiveDays++;
        } else {
          break;
        }
      }
    }

    // 计算今日签到次数
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const tomorrow = new Date(today);
    tomorrow.setDate(tomorrow.getDate() + 1);

    const todayCheckins = allCheckins.filter(c => {
      // SQLite的CURRENT_TIMESTAMP返回UTC时间
      const checkinDate = new Date(c.checkin_time + 'Z');
      return checkinDate >= today && checkinDate < tomorrow;
    }).length;

    const lastCheckin = dbHelpers.getLastCheckin(user.id);

    res.json({
      consecutiveDays,
      todayCheckins,
      lastCheckin: lastCheckin ? `${lastCheckin.checkin_time}Z` : null  // 添加Z表示UTC时间
    });
  } catch (error) {
    console.error('Get stats error:', error);
    res.status(500).json({ error: '获取统计数据失败' });
  }
});

// 获取最近签到记录
router.get('/recent', authenticateToken, (req, res) => {
  try {
    const user = dbHelpers.getUserByEmail(req.user.email);
    const recentCheckins = dbHelpers.getRecentCheckins(user.id, 10);

    res.json({
      checkins: recentCheckins.map(c => ({
        id: c.id,
        timestamp: c.checkin_time
      }))
    });
  } catch (error) {
    console.error('Get recent check-ins error:', error);
    res.status(500).json({ error: '获取签到记录失败' });
  }
});

export default router;
