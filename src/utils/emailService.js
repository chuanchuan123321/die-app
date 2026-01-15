import nodemailer from 'nodemailer';

export async function sendAlertEmail(user, lastCheckinTime, alertThresholdMinutes) {
  try {
    if (!user.smtp_host || !user.smtp_username || !user.smtp_password) {
      console.log(`⚠️ User ${user.email} has no SMTP config, skipping alert`);
      return { success: false, reason: 'no_smtp_config' };
    }

    // 创建SMTP传输
    const port = parseInt(user.smtp_port) || 465;  // 默认465端口

    console.log(`📧 Creating SMTP transport for ${user.emergency_email}:`);
    console.log(`  - Host: ${user.smtp_host}`);
    console.log(`  - Port: ${port}`);
    console.log(`  - Secure: ${port === 465}`);
    console.log(`  - Username: ${user.smtp_username}`);

    const transporter = nodemailer.createTransport({
      host: user.smtp_host,
      port: port,
      secure: port === 465, // true for 465 (SSL), false for 587 (STARTTLS)
      auth: {
        user: user.smtp_username,
        pass: user.smtp_password,
      },
      tls: {
        // 忽略证书验证错误（某些SMTP服务器证书问题）
        rejectUnauthorized: false,
      },
      debug: true, // 启用调试日志
      logger: true, // 启用日志记录
    });

    const lastTime = new Date(lastCheckinTime);
    const now = new Date();
    const minutesSinceLastCheckin = Math.floor((now - lastTime) / (1000 * 60));

    // 计算超时时长
    const days = Math.floor(minutesSinceLastCheckin / (24 * 60));
    const hours = Math.floor((minutesSinceLastCheckin % (24 * 60)) / 60);
    const minutes = minutesSinceLastCheckin % 60;

    let timeExceededStr = '';
    if (days > 0) {
      timeExceededStr = `${days}天${hours}小时${minutes}分钟`;
    } else if (hours > 0) {
      timeExceededStr = `${hours}小时${minutes}分钟`;
    } else {
      timeExceededStr = `${minutes}分钟`;
    }

    // 计算设定的间隔时间
    const thresholdDays = Math.floor(alertThresholdMinutes / (24 * 60));
    const thresholdHours = Math.floor((alertThresholdMinutes % (24 * 60)) / 60);
    const thresholdMinutes = alertThresholdMinutes % 60;

    let thresholdStr = '';
    if (thresholdDays > 0) {
      thresholdStr = `${thresholdDays}天${thresholdHours}小时${thresholdMinutes}分钟`;
    } else if (thresholdHours > 0) {
      thresholdStr = `${thresholdHours}小时${thresholdMinutes}分钟`;
    } else {
      thresholdStr = `${thresholdMinutes}分钟`;
    }

    const displayName = user.name || user.email;
    const contactName = user.emergency_contact_name || '紧急联系人';

    // 发送邮件
    const info = await transporter.sendMail({
      from: `"死了吗" <${user.smtp_username}>`,
      to: user.emergency_email,
      subject: `【紧急通知】${displayName} 已超过${timeExceededStr}未签到`,
      text: `
${contactName}，您好！

这是一封来自"死了吗"应用的紧急通知。

用户信息：
- 姓名：${displayName}
- 邮箱：${user.email}
- 最后签到时间：${lastTime.toLocaleString('zh-CN', { timeZone: 'Asia/Shanghai' })}
- 已超过设定时间：${timeExceededStr}

${displayName}设定的签到间隔是${thresholdStr}，目前已经超过该时间未签到，可能发生意外情况，请尽快联系或确认其安全状况。

---
此邮件由"死了吗"应用自动发送，请勿回复。
      `.trim(),
      html: `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; background-color: #f9f9f9;">
          <div style="background-color: #fff; padding: 30px; border-radius: 10px; box-shadow: 0 2px 4px rgba(0,0,0,0.1);">
            <h2 style="color: #ff4444; margin-top: 0;">⚠️ 紧急通知</h2>
            <p>${contactName}，您好！</p>
            <p>这是一封来自"死了吗"应用的紧急通知。</p>

            <div style="background-color: #fff3cd; border-left: 4px solid #ffc107; padding: 15px; margin: 20px 0;">
              <h3 style="margin-top: 0; color: #856404;">用户信息</h3>
              <ul style="list-style: none; padding: 0;">
                <li><strong>姓名：</strong>${displayName}</li>
                <li><strong>邮箱：</strong>${user.email}</li>
                <li><strong>最后签到时间：</strong>${lastTime.toLocaleString('zh-CN', { timeZone: 'Asia/Shanghai' })}</li>
                <li><strong>设定的签到间隔：</strong>${thresholdStr}</li>
                <li><strong>已超过：</strong><span style="color: #ff4444; font-size: 18px; font-weight: bold;">${timeExceededStr}</span></li>
              </ul>
            </div>

            <p style="color: #ff4444; font-size: 16px;">
              <strong>${displayName}设定的签到间隔是${thresholdStr}，目前已经超过该时间未签到，可能发生意外情况，请尽快联系或确认其安全状况。</strong>
            </p>

            <hr style="border: none; border-top: 1px solid #ddd; margin: 30px 0;">

            <p style="color: #999; font-size: 12px;">
              此邮件由"死了吗"应用自动发送，请勿回复。
            </p>
          </div>
        </div>
      `.trim(),
    });

    console.log(`✅ Alert email sent to ${user.emergency_email}:`, info.messageId);
    return { success: true, messageId: info.messageId };
  } catch (error) {
    console.error(`❌ Failed to send alert email for user ${user.email}:`, error.message);
    return { success: false, reason: error.message };
  }
}
