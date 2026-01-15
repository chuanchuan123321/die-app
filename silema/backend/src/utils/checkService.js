import { dbHelpers } from '../models/database.js';
import { sendAlertEmail } from './emailService.js';

const ALERT_COOLDOWN_HOURS = 24; // 避免重复发送警报的冷却时间

export async function checkAllUsers() {
  try {
    // 获取所有用户及其设置和紧急联系人
    const users = dbHelpers.getAllUsersWithContacts();

    if (users.length === 0) {
      console.log('ℹ️ No users to check');
      return;
    }

    console.log(`📊 Checking ${users.length} users...`);

    let alertSentCount = 0;
    let skippedCount = 0;

    for (const user of users) {
      const result = await checkUser(user);
      if (result.alertSent) {
        alertSentCount++;
      } else if (result.skipped) {
        skippedCount++;
      }
    }

    console.log(`✅ Checked ${users.length} users: ${alertSentCount} alerts sent, ${skippedCount} skipped`);
  } catch (error) {
    console.error('❌ Error in checkAllUsers:', error);
  }
}

export async function checkUser(user) {
  try {
    // 获取用户设置中的阈值（分钟）
    const alertThresholdMinutes = user.settings?.alert_threshold_minutes || 2880; // 默认48小时

    console.log(`\n🔍 Checking user ${user.email}:`);
    console.log(`  - Alert threshold: ${alertThresholdMinutes} minutes (${(alertThresholdMinutes/60).toFixed(1)} hours)`);

    // 获取最后签到时间
    const lastCheckin = dbHelpers.getLastCheckin(user.id);

    if (!lastCheckin) {
      console.log(`  ⚠️ No check-in record`);
      return { alertSent: false, skipped: true, reason: 'no_checkin' };
    }

    // SQLite的CURRENT_TIMESTAMP返回UTC时间
    const lastCheckinTime = new Date(lastCheckin.checkin_time + 'Z');
    const now = new Date();
    const minutesSinceLastCheckin = (now - lastCheckinTime) / (1000 * 60);

    console.log(`  - Last checkin: ${lastCheckin.checkin_time} UTC`);
    console.log(`  - Current time: ${now.toISOString()}`);
    console.log(`  - Minutes since last checkin: ${minutesSinceLastCheckin.toFixed(1)}`);
    console.log(`  - Threshold: ${alertThresholdMinutes} minutes`);
    console.log(`  - Exceeded: ${minutesSinceLastCheckin >= alertThresholdMinutes ? 'YES ✅' : 'NO ❌'}`);

    // 检查是否超过阈值
    if (minutesSinceLastCheckin < alertThresholdMinutes) {
      console.log(`  ⏭️ Skipped: within threshold`);
      return { alertSent: false, skipped: true, reason: 'within_threshold' };
    }

    // 检查最近是否已发送过警报（1小时冷却期）
    const lastAlert = dbHelpers.getLastAlert(user.id);
    if (lastAlert) {
      // SQLite的CURRENT_TIMESTAMP返回UTC时间
      const lastAlertTime = new Date(lastAlert.sent_time + 'Z');
      const minutesSinceLastAlert = (now - lastAlertTime) / (1000 * 60);

      console.log(`  - Last alert sent: ${lastAlert.sent_time} UTC`);
      console.log(`  - Minutes since last alert: ${minutesSinceLastAlert.toFixed(1)}`);
      console.log(`  - Cooldown period: 60 minutes (1 hour)`);

      if (minutesSinceLastAlert < 60) {
        console.log(`  ⏭️ Skipped: in cooldown period`);
        return { alertSent: false, skipped: true, reason: 'alert_cooldown' };
      } else {
        console.log(`  ✅ Cooldown period expired, can send new alert`);
      }
    } else {
      console.log(`  - No previous alert record`);
    }

    // 获取紧急联系人列表
    const contacts = user.emergencyContacts || [];

    if (contacts.length === 0) {
      console.log(`⚠️ User ${user.email} has no emergency contacts, skipping alert`);
      return { alertSent: false, skipped: true, reason: 'no_contacts' };
    }

    // 发送警报邮件给所有紧急联系人
    const hours = Math.floor(minutesSinceLastCheckin / 60);
    const minutes = Math.floor(minutesSinceLastCheckin % 60);
    console.log(`⚠️ User ${user.email} exceeded threshold (${hours}h ${minutes}m), sending alert to ${contacts.length} contact(s)`);

    let successCount = 0;
    let failCount = 0;

    for (const contact of contacts) {
      // 创建一个包含联系人信息的用户对象
      const userWithContact = {
        ...user,
        emergency_email: contact.email,
        emergency_contact_name: contact.name,
      };

      const emailResult = await sendAlertEmail(userWithContact, lastCheckinTime, alertThresholdMinutes);

      if (emailResult.success) {
        successCount++;
        // 记录每个发送成功的警报
        dbHelpers.createAlert(user.id, contact.id);
      } else {
        console.log(`⚠️ Failed to send alert to ${contact.email}: ${emailResult.reason}`);
        failCount++;
      }
    }

    if (successCount > 0) {
      console.log(`✅ Alert sent for user ${user.email}: ${successCount} succeeded, ${failCount} failed`);
      return { alertSent: true, successCount, failCount };
    } else {
      console.log(`⚠️ All alert attempts failed for user ${user.email}`);
      return { alertSent: false, skipped: true, reason: 'all_emails_failed' };
    }
  } catch (error) {
    console.error(`❌ Error checking user ${user.email}:`, error);
    return { alertSent: false, error: error.message };
  }
}
