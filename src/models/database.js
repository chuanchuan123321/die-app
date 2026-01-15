import initSqlJs from 'sql.js';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const dbPath = path.join(__dirname, '../../data/silema.db');
const dataDir = path.join(__dirname, '../../data');

let db = null;
let SQL = null;

export async function initializeDatabase() {
  // 创建数据库目录
  if (!fs.existsSync(dataDir)) {
    fs.mkdirSync(dataDir, { recursive: true });
  }

  // 初始化 sql.js
  SQL = await initSqlJs();

  // 加载或创建数据库
  if (fs.existsSync(dbPath)) {
    const buffer = fs.readFileSync(dbPath);
    db = new SQL.Database(buffer);
    console.log('✅ Database loaded from disk');

    // 检查是否需要迁移（添加新表）
    migrateDatabase();
  } else {
    db = new SQL.Database();
    console.log('✅ New database created');
  }

  // 创建表
  createTables();

  // 保存数据库
  saveDatabase();
}

function migrateDatabase() {
  // 检查是否有新表需要添加
  const tables = db.exec("SELECT name FROM sqlite_master WHERE type='table'");
  const tableNames = tables[0]?.values.map(row => row[0]) || [];

  // 添加新表（如果不存在）
  if (!tableNames.includes('emergency_contacts')) {
    console.log('🔄 Migrating: Adding emergency_contacts table');
    db.run(`
      CREATE TABLE IF NOT EXISTS emergency_contacts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        email TEXT NOT NULL,
        phone TEXT,
        is_primary INTEGER DEFAULT 0,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      )
    `);
  }

  if (!tableNames.includes('user_settings')) {
    console.log('🔄 Migrating: Adding user_settings table');
    db.run(`
      CREATE TABLE IF NOT EXISTS user_settings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL UNIQUE,
        alert_threshold_minutes INTEGER DEFAULT 2880,
        enable_email_alert INTEGER DEFAULT 1,
        enable_sms_alert INTEGER DEFAULT 0,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      )
    `);
  }

  // 检查user_settings表的列，如果使用旧的alert_threshold_hours，需要迁移
  if (tableNames.includes('user_settings')) {
    const columns = db.exec("PRAGMA table_info(user_settings)");
    const columnNames = columns[0]?.values.map(row => row[1]) || [];

    // 如果存在旧的alert_threshold_hours列，需要添加新的列并迁移数据
    if (columnNames.includes('alert_threshold_hours') && !columnNames.includes('alert_threshold_minutes')) {
      console.log('🔄 Migrating: Converting alert_threshold_hours to alert_threshold_minutes');

      // 添加新列
      db.run('ALTER TABLE user_settings ADD COLUMN alert_threshold_minutes INTEGER DEFAULT 2880');

      // 迁移数据：将小时转换为分钟
      db.run('UPDATE user_settings SET alert_threshold_minutes = alert_threshold_hours * 60');

      saveDatabase();
      console.log('✅ Migration completed: alert_threshold_hours → alert_threshold_minutes');
    }
  }

  // 检查alerts表，添加contact_id列（如果不存在）
  if (tableNames.includes('alerts')) {
    const alertColumns = db.exec("PRAGMA table_info(alerts)");
    const alertColumnNames = alertColumns[0]?.values.map(row => row[1]) || [];

    if (!alertColumnNames.includes('contact_id')) {
      console.log('🔄 Migrating: Adding contact_id column to alerts table');

      // 添加contact_id列
      db.run('ALTER TABLE alerts ADD COLUMN contact_id INTEGER');

      saveDatabase();
      console.log('✅ Migration completed: Added contact_id to alerts table');
    }
  }

  // 检查users表，添加name列（如果不存在）
  if (tableNames.includes('users')) {
    const userColumns = db.exec("PRAGMA table_info(users)");
    const userColumnNames = userColumns[0]?.values.map(row => row[1]) || [];

    if (!userColumnNames.includes('name')) {
      console.log('🔄 Migrating: Adding name column to users table');

      // 添加name列
      db.run('ALTER TABLE users ADD COLUMN name TEXT NOT NULL DEFAULT \'\'');

      saveDatabase();
      console.log('✅ Migration completed: Added name to users table');
    }

    // 添加SMTP配置列（如果不存在）
    const smtpColumns = ['smtp_host', 'smtp_port', 'smtp_username', 'smtp_password'];
    for (const col of smtpColumns) {
      if (!userColumnNames.includes(col)) {
        console.log(`🔄 Migrating: Adding ${col} column to users table`);
        db.run(`ALTER TABLE users ADD COLUMN ${col} TEXT`);
        saveDatabase();
        console.log(`✅ Migration completed: Added ${col} to users table`);
      }
    }
  }
}

function createTables() {
  // 用户表
  db.run(`
    CREATE TABLE IF NOT EXISTS users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      email TEXT NOT NULL UNIQUE,
      password TEXT NOT NULL,
      device_id TEXT NOT NULL UNIQUE,
      name TEXT NOT NULL DEFAULT '',
      smtp_host TEXT,
      smtp_port TEXT,
      smtp_username TEXT,
      smtp_password TEXT,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
    )
  `);

  // 紧急联系人表（支持多个）
  db.run(`
    CREATE TABLE IF NOT EXISTS emergency_contacts (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER NOT NULL,
      name TEXT NOT NULL,
      email TEXT NOT NULL,
      phone TEXT,
      is_primary INTEGER DEFAULT 0,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
    )
  `);

  // 用户设置表
  db.run(`
    CREATE TABLE IF NOT EXISTS user_settings (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER NOT NULL UNIQUE,
      alert_threshold_minutes INTEGER DEFAULT 2880,
      enable_email_alert INTEGER DEFAULT 1,
      enable_sms_alert INTEGER DEFAULT 0,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
    )
  `);

  // 签到记录表
  db.run(`
    CREATE TABLE IF NOT EXISTS checkins (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER NOT NULL,
      checkin_time DATETIME DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
    )
  `);

  // 警报记录表
  db.run(`
    CREATE TABLE IF NOT EXISTS alerts (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER NOT NULL,
      contact_id INTEGER,
      sent_time DATETIME DEFAULT CURRENT_TIMESTAMP,
      status TEXT DEFAULT 'sent',
      FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
    )
  `);

  // 创建索引
  db.run(`CREATE INDEX IF NOT EXISTS idx_emergency_contacts_user_id ON emergency_contacts(user_id)`);
  db.run(`CREATE INDEX IF NOT EXISTS idx_user_settings_user_id ON user_settings(user_id)`);
  db.run(`CREATE INDEX IF NOT EXISTS idx_checkins_user_id ON checkins(user_id)`);
  db.run(`CREATE INDEX IF NOT EXISTS idx_checkins_time ON checkins(checkin_time)`);
  db.run(`CREATE INDEX IF NOT EXISTS idx_alerts_user_id ON alerts(user_id)`);
  db.run(`CREATE INDEX IF NOT EXISTS idx_alerts_time ON alerts(sent_time)`);

  console.log('✅ Tables created');
}

function saveDatabase() {
  const data = db.export();
  const buffer = Buffer.from(data);
  fs.writeFileSync(dbPath, buffer);
}

export function getDatabase() {
  return db;
}

export { saveDatabase };

// 辅助函数：执行查询并返回结果
function queryOne(sql, params = []) {
  const stmt = db.prepare(sql);
  stmt.bind(params);
  if (stmt.step()) {
    const result = stmt.getAsObject();
    stmt.free();
    return result;
  }
  stmt.free();
  return null;
}

// 辅助函数：执行查询并返回所有结果
function queryAll(sql, params = []) {
  const stmt = db.prepare(sql);
  stmt.bind(params);
  const results = [];
  while (stmt.step()) {
    results.push(stmt.getAsObject());
  }
  stmt.free();
  return results;
}

// 辅助函数：执行更新/插入/删除
function run(sql, params = []) {
  db.run(sql, params);
  saveDatabase();
}

// 辅助函数：执行查询并返回插入的ID
function runAndGetId(sql, params = []) {
  const stmt = db.prepare(sql);
  stmt.bind(params);
  stmt.step();
  const result = stmt.getAsObject();
  stmt.free();
  saveDatabase();
  return result; // 返回包含 lastID 的对象
}

// 数据库操作辅助函数
export const dbHelpers = {
  // 用户操作
  getUserByEmail: (email) => {
    return queryOne('SELECT * FROM users WHERE email = ?', [email]);
  },

  getUserByDeviceId: (deviceId) => {
    return queryOne('SELECT * FROM users WHERE device_id = ?', [deviceId]);
  },

  createUser: (email, password, deviceId, name = '') => {
    run(
      'INSERT INTO users (email, password, device_id, name) VALUES (?, ?, ?, ?)',
      [email, password, deviceId, name]
    );

    // 创建默认设置
    const user = queryOne('SELECT * FROM users WHERE email = ?', [email]);
    if (user) {
      run(
        'INSERT INTO user_settings (user_id, alert_threshold_minutes) VALUES (?, ?)',
        [user.id, 2880] // 默认48小时 = 2880分钟
      );
    }
  },

  updateUserSmtp: (userId, smtpConfig) => {
    run(
      'UPDATE users SET smtp_host = ?, smtp_port = ?, smtp_username = ?, smtp_password = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?',
      [smtpConfig.host, smtpConfig.port, smtpConfig.username, smtpConfig.password, userId]
    );
    saveDatabase();
  },

  // 紧急联系人操作
  addEmergencyContact: (userId, name, email, phone, isPrimary = false) => {
    runAndGetId(
      'INSERT INTO emergency_contacts (user_id, name, email, phone, is_primary) VALUES (?, ?, ?, ?, ?)',
      [userId, name, email, phone, isPrimary ? 1 : 0]
    );
  },

  getEmergencyContacts: (userId) => {
    return queryAll(
      'SELECT * FROM emergency_contacts WHERE user_id = ? ORDER BY is_primary DESC, created_at ASC',
      [userId]
    );
  },

  updateEmergencyContact: (contactId, name, email, phone) => {
    run(
      'UPDATE emergency_contacts SET name = ?, email = ?, phone = ? WHERE id = ?',
      [name, email, phone, contactId]
    );
  },

  deleteEmergencyContact: (contactId) => {
    run('DELETE FROM emergency_contacts WHERE id = ?', [contactId]);
  },

  setPrimaryContact: (userId, contactId) => {
    // 先取消所有主联系人标记
    run('UPDATE emergency_contacts SET is_primary = 0 WHERE user_id = ?', [userId]);
    // 设置新的主联系人
    run('UPDATE emergency_contacts SET is_primary = 1 WHERE id = ?', [contactId]);
  },

  // 用户设置操作
  getUserSettings: (userId) => {
    return queryOne('SELECT * FROM user_settings WHERE user_id = ?', [userId]);
  },

  updateUserSettings: (userId, settings) => {
    const { alertThresholdMinutes, enableEmailAlert, enableSmsAlert } = settings;
    run(
      'UPDATE user_settings SET alert_threshold_minutes = ?, enable_email_alert = ?, enable_sms_alert = ?, updated_at = CURRENT_TIMESTAMP WHERE user_id = ?',
      [alertThresholdMinutes, enableEmailAlert ? 1 : 0, enableSmsAlert ? 1 : 0, userId]
    );
  },

  createUserSettings: (userId, settings) => {
    const { alertThresholdMinutes = 2880 } = settings; // 默认48小时 = 2880分钟
    run(
      'INSERT INTO user_settings (user_id, alert_threshold_minutes) VALUES (?, ?)',
      [userId, alertThresholdMinutes]
    );
  },

  // 签到操作
  createCheckin: (userId) => {
    run('INSERT INTO checkins (user_id) VALUES (?)', [userId]);
    saveDatabase();
  },

  getLastCheckin: (userId) => {
    return queryOne(`
      SELECT * FROM checkins
      WHERE user_id = ?
      ORDER BY checkin_time DESC
      LIMIT 1
    `, [userId]);
  },

  getRecentCheckins: (userId, limit = 10) => {
    return queryAll(`
      SELECT * FROM checkins
      WHERE user_id = ?
      ORDER BY checkin_time DESC
      LIMIT ?
    `, [userId, limit]);
  },

  getCheckinCount: (userId, days = null) => {
    if (days) {
      const startDate = new Date();
      startDate.setDate(startDate.getDate() - days);
      const result = queryOne(`
        SELECT COUNT(*) as count FROM checkins
        WHERE user_id = ? AND checkin_time >= ?
      `, [userId, startDate.toISOString()]);
      return result.count;
    }
    const result = queryOne('SELECT COUNT(*) as count FROM checkins WHERE user_id = ?', [userId]);
    return result.count;
  },

  // 警报操作
  createAlert: (userId, contactId = null) => {
    run('INSERT INTO alerts (user_id, contact_id) VALUES (?, ?)', [userId, contactId]);
  },

  getLastAlert: (userId) => {
    return queryOne(`
      SELECT * FROM alerts
      WHERE user_id = ?
      ORDER BY sent_time DESC
      LIMIT 1
    `, [userId]);
  },

  // 获取需要检查的用户（含设置和紧急联系人）
  getAllUsersWithContacts: () => {
    const users = queryAll('SELECT * FROM users');
    return users.map(user => {
      const settings = queryOne('SELECT * FROM user_settings WHERE user_id = ?', [user.id]);
      const contacts = queryAll('SELECT * FROM emergency_contacts WHERE user_id = ?', [user.id]);
      return {
        ...user,
        settings: settings || { alert_threshold_minutes: 2880 }, // 默认48小时
        emergencyContacts: contacts
      };
    });
  },

  // 兼容旧方法
  getAllUsers: () => {
    return queryAll('SELECT * FROM users');
  }
};
