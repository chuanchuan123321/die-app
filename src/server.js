import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import cron from 'node-cron';
import { initializeDatabase } from './models/database.js';
import authRoutes from './routes/auth.js';
import checkinRoutes from './routes/checkin.js';
import contactsRoutes from './routes/contacts.js';
import settingsRoutes from './routes/settings.js';
import { checkAllUsers } from './utils/checkService.js';

dotenv.config();

const app = express();
const PORT = process.env.PORT || 3000;

// 中间件
app.use(cors());
app.use(express.json());

// 路由
app.use('/api/auth', authRoutes);
app.use('/api/checkin', checkinRoutes);
app.use('/api/contacts', contactsRoutes);
app.use('/api/settings', settingsRoutes);

// 健康检查
app.get('/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// 错误处理
app.use((err, req, res, next) => {
  console.error('Error:', err);
  res.status(500).json({ error: '服务器错误', message: err.message });
});

// 初始化数据库
initializeDatabase();

// 启动服务器
app.listen(PORT, () => {
  console.log(`🚀 Server running on port ${PORT}`);
  console.log(`📊 Health check: http://localhost:${PORT}/health`);
});

// 定时任务：每分钟检查一次所有用户
cron.schedule('* * * * *', async () => {
  console.log('⏰ Starting minute-by-minute check for all users...');
  await checkAllUsers();
  console.log('✅ Minute check completed');
});

// 服务器启动时立即执行一次检查
setTimeout(async () => {
  console.log('🔍 Starting initial check for all users...');
  await checkAllUsers();
  console.log('✅ Initial check completed');
}, 5000);
