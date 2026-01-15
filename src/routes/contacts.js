import express from 'express';
import { dbHelpers } from '../models/database.js';
import { authenticateToken } from '../middleware/auth.js';

const router = express.Router();

// 获取所有紧急联系人
router.get('/', authenticateToken, (req, res) => {
  try {
    const user = dbHelpers.getUserByEmail(req.user.email);
    if (!user) {
      return res.status(404).json({ error: '用户不存在' });
    }

    const contacts = dbHelpers.getEmergencyContacts(user.id);
    res.json({ contacts });
  } catch (error) {
    console.error('Get contacts error:', error);
    res.status(500).json({ error: '获取紧急联系人失败' });
  }
});

// 添加紧急联系人
router.post('/', authenticateToken, (req, res) => {
  try {
    const { name, email, phone, isPrimary } = req.body;

    // 验证必填字段
    if (!name || !email) {
      return res.status(400).json({ error: '请填写姓名和邮箱' });
    }

    // 验证邮箱格式
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
      return res.status(400).json({ error: '邮箱格式不正确' });
    }

    const user = dbHelpers.getUserByEmail(req.user.email);
    if (!user) {
      return res.status(404).json({ error: '用户不存在' });
    }

    // 检查联系人数量限制（最多10个）
    const existingContacts = dbHelpers.getEmergencyContacts(user.id);
    if (existingContacts.length >= 10) {
      return res.status(400).json({ error: '最多只能添加10个紧急联系人' });
    }

    // 如果是第一个联系人或设为主要联系人，自动设为主要
    const shouldSetPrimary = isPrimary || existingContacts.length === 0;

    // 添加联系人
    dbHelpers.addEmergencyContact(user.id, name, email, phone || '', shouldSetPrimary);

    // 如果设为主要联系人，取消其他联系人主要标记
    if (shouldSetPrimary) {
      const contacts = dbHelpers.getEmergencyContacts(user.id);
      const newContact = contacts.find(c => c.email === email && c.name === name);
      if (newContact) {
        dbHelpers.setPrimaryContact(user.id, newContact.id);
      }
    }

    res.status(201).json({
      message: '紧急联系人已添加',
      contact: {
        name,
        email,
        phone: phone || '',
        isPrimary: shouldSetPrimary
      }
    });
  } catch (error) {
    console.error('Add contact error:', error);
    res.status(500).json({ error: '添加紧急联系人失败' });
  }
});

// 更新紧急联系人
router.put('/:id', authenticateToken, (req, res) => {
  try {
    const { id } = req.params;
    const { name, email, phone } = req.body;

    // 验证必填字段
    if (!name || !email) {
      return res.status(400).json({ error: '请填写姓名和邮箱' });
    }

    // 验证邮箱格式
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
      return res.status(400).json({ error: '邮箱格式不正确' });
    }

    const user = dbHelpers.getUserByEmail(req.user.email);
    if (!user) {
      return res.status(404).json({ error: '用户不存在' });
    }

    // 验证联系人是否属于当前用户
    const contacts = dbHelpers.getEmergencyContacts(user.id);
    const contact = contacts.find(c => c.id === parseInt(id));
    if (!contact) {
      return res.status(404).json({ error: '联系人不存在' });
    }

    // 更新联系人
    dbHelpers.updateEmergencyContact(parseInt(id), name, email, phone || '');

    res.json({ message: '紧急联系人已更新' });
  } catch (error) {
    console.error('Update contact error:', error);
    res.status(500).json({ error: '更新紧急联系人失败' });
  }
});

// 删除紧急联系人
router.delete('/:id', authenticateToken, (req, res) => {
  try {
    const { id } = req.params;

    const user = dbHelpers.getUserByEmail(req.user.email);
    if (!user) {
      return res.status(404).json({ error: '用户不存在' });
    }

    // 验证联系人是否属于当前用户
    const contacts = dbHelpers.getEmergencyContacts(user.id);
    const contact = contacts.find(c => c.id === parseInt(id));
    if (!contact) {
      return res.status(404).json({ error: '联系人不存在' });
    }

    // 如果删除的是主要联系人，需要将其他联系人设为主要
    if (contact.is_primary) {
      const otherContacts = contacts.filter(c => c.id !== parseInt(id));
      if (otherContacts.length > 0) {
        // 将第一个其他联系人设为主要
        dbHelpers.setPrimaryContact(user.id, otherContacts[0].id);
      }
    }

    // 删除联系人
    dbHelpers.deleteEmergencyContact(parseInt(id));

    res.json({ message: '紧急联系人已删除' });
  } catch (error) {
    console.error('Delete contact error:', error);
    res.status(500).json({ error: '删除紧急联系人失败' });
  }
});

// 设为主要联系人
router.put('/:id/primary', authenticateToken, (req, res) => {
  try {
    const { id } = req.params;

    const user = dbHelpers.getUserByEmail(req.user.email);
    if (!user) {
      return res.status(404).json({ error: '用户不存在' });
    }

    // 验证联系人是否属于当前用户
    const contacts = dbHelpers.getEmergencyContacts(user.id);
    const contact = contacts.find(c => c.id === parseInt(id));
    if (!contact) {
      return res.status(404).json({ error: '联系人不存在' });
    }

    // 设为主要联系人
    dbHelpers.setPrimaryContact(user.id, parseInt(id));

    res.json({ message: '已设为主要联系人' });
  } catch (error) {
    console.error('Set primary contact error:', error);
    res.status(500).json({ error: '设置主要联系人失败' });
  }
});

export default router;
