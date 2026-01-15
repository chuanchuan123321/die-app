import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import 'contacts_page.dart';
import 'login_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // SMTP配置
  final _smtpHostController = TextEditingController();
  final _smtpPortController = TextEditingController(text: '465');
  final _smtpUsernameController = TextEditingController();
  final _smtpPasswordController = TextEditingController();

  bool _isLoading = false;
  Map<String, dynamic>? _userInfo;
  Map<String, dynamic>? _settings;
  int _days = 2;
  int _hours = 0;
  int _minutes = 0;
  bool _smtpExpanded = false;  // SMTP配置展开状态

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    await StorageService.init();

    // 从服务器获取用户信息
    final userResult = await ApiService.getUserInfo();
    final settingsResult = await ApiService.getSettings();

    if (mounted) {
      setState(() {
        if (userResult['success']) {
          _userInfo = userResult['data'];
        }
        if (settingsResult['success']) {
          _settings = settingsResult['data'];
          // 将分钟转换为天、小时、分钟
          final totalMinutes = _settings?['alertThresholdMinutes'] ?? (48 * 60);
          _days = totalMinutes ~/ (24 * 60);
          _hours = (totalMinutes % (24 * 60)) ~/ 60;
          _minutes = totalMinutes % 60;
        }
      });
    }
  }

  Future<void> _saveSmtpConfig() async {
    setState(() => _isLoading = true);

    try {
      final port = int.tryParse(_smtpPortController.text);
      if (port == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('请输入有效的端口号'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isLoading = false);
        return;
      }

      final result = await ApiService.updateSmtpConfig(
        host: _smtpHostController.text.trim(),
        port: port,
        username: _smtpUsernameController.text.trim(),
        password: _smtpPasswordController.text,
      );

      if (!mounted) return;

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('SMTP配置已保存'),
            backgroundColor: Colors.green,
          ),
        );
        await _loadConfig();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['error'] ?? '保存失败'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _sendTestEmail() async {
    setState(() => _isLoading = true);

    try {
      final result = await ApiService.sendTestEmail();

      if (!mounted) return;

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['data']['details'] ?? '测试邮件已发送'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['error'] ?? '发送失败'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showTimePickerDialog() async {
    int selectedDay = _days;
    int selectedHour = _hours;
    int selectedMinute = _minutes;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: const Color(0xFF1a1a2e),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 标题
                Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      color: const Color(0xFFff6b6b).withOpacity(0.8),
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      '设置警报时间',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // 滚轮选择器
                SizedBox(
                  height: 180,
                  child: Row(
                    children: [
                      _buildTimeWheel(
                        itemCount: 31, // 0-30天
                        label: '天',
                        initialValue: selectedDay,
                        onChanged: (value) {
                          setDialogState(() {
                            selectedDay = value;
                          });
                        },
                      ),
                      _buildTimeWheel(
                        itemCount: 24, // 0-23小时
                        label: '时',
                        initialValue: selectedHour,
                        onChanged: (value) {
                          setDialogState(() {
                            selectedHour = value;
                          });
                        },
                      ),
                      _buildTimeWheel(
                        itemCount: 60, // 0-59分钟
                        label: '分',
                        initialValue: selectedMinute,
                        onChanged: (value) {
                          setDialogState(() {
                            selectedMinute = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // 当前选择预览
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFff6b6b).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: const Color(0xFFff6b6b).withOpacity(0.8),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '当前选择: $selectedDay 天 $selectedHour 时 $selectedMinute 分',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // 按钮
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context, false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey,
                          side: BorderSide(
                            color: Colors.grey.withOpacity(0.5),
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('取消', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFff6b6b),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('确定', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (result == true) {
      setState(() {
        _days = selectedDay;
        _hours = selectedHour;
        _minutes = selectedMinute;
      });

      // 计算总分钟数
      final totalMinutes = _days * 24 * 60 + _hours * 60 + _minutes;

      final apiResult = await ApiService.updateSettings(
        alertThresholdMinutes: totalMinutes,
      );

      if (mounted) {
        if (!apiResult['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(apiResult['error'] ?? '更新失败'),
              backgroundColor: Colors.red,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('已设置为 $_days 天 $_hours 时 $_minutes 分'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    }
  }

  Widget _buildTimeWheel({
    required int itemCount,
    required String label,
    required int initialValue,
    required Function(int) onChanged,
  }) {
    final controller = FixedExtentScrollController(initialItem: initialValue);

    return Expanded(
      child: Column(
        children: [
          Expanded(
            child: ListWheelScrollView(
              controller: controller,
              itemExtent: 50,
              physics: const FixedExtentScrollPhysics(),
              onSelectedItemChanged: onChanged,
              children: List.generate(itemCount, (index) {
                return Builder(
                  builder: (context) {
                    final isSelected = controller.selectedItem == index;
                    return Center(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFFff6b6b).withOpacity(0.2)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          index.toString().padLeft(2, '0'),
                          style: TextStyle(
                            fontSize: isSelected ? 28 : 20,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected
                                ? const Color(0xFFff6b6b)
                                : Colors.white.withOpacity(0.6),
                          ),
                        ),
                      ),
                    );
                  }
                );
              }),
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _smtpHostController.dispose();
    _smtpPortController.dispose();
    _smtpUsernameController.dispose();
    _smtpPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasSmtpConfig = _userInfo?['hasSmtpConfig'] ?? false;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1a1a2e),
              Color(0xFF16213e),
              Color(0xFF0f3460),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // 顶部栏
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  children: [
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => Navigator.pop(context),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.1),
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Colors.white.withOpacity(0.8),
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      '设置',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w300,
                        color: Colors.white.withOpacity(0.95),
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),

              // 设置内容
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 警报时间阈值设置
                      _buildSectionTitle('警报时间阈值'),
                      const SizedBox(height: 16),
                      _buildCard([
                        InkWell(
                          onTap: _showTimePickerDialog,
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.schedule,
                                      color: const Color(0xFFff6b6b).withOpacity(0.8),
                                      size: 28,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '当前设置',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.white.withOpacity(0.6),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '$_days 天 $_hours 时 $_minutes 分',
                                            style: const TextStyle(
                                              fontSize: 28,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [Color(0xFFff6b6b), Color(0xFFee5a6f)],
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFFff6b6b).withOpacity(0.3),
                                            blurRadius: 8,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.edit,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: Colors.blue.withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.info_outline,
                                        color: Colors.blue.withOpacity(0.8),
                                        size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          '点击上方区域，通过滚轮选择警报时间间隔（支持到分钟级别）',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.blue.withOpacity(0.9),
                                            height: 1.4,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ]),

                      const SizedBox(height: 32),

                      // 紧急联系人管理
                      _buildSectionTitle('紧急联系人'),
                      const SizedBox(height: 16),
                      _buildCard([
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF4ecdc4), Color(0xFF44a08d)],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.contacts,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          title: Text(
                            '管理紧急联系人',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withOpacity(0.95),
                            ),
                          ),
                          subtitle: Text(
                            '添加、编辑或删除紧急联系人',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withOpacity(0.6),
                            ),
                          ),
                          trailing: Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.white.withOpacity(0.5),
                            size: 18,
                          ),
                          onTap: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ContactsPage(),
                              ),
                            );
                            if (result == true) {
                              // 刷新用户信息以更新联系人状态
                              _loadConfig();
                            }
                          },
                        ),
                      ]),

                      const SizedBox(height: 32),

                      // SMTP配置部分（可折叠）
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.08),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            // 点击展开/收起的标题栏
                            InkWell(
                              onTap: () {
                                setState(() {
                                  _smtpExpanded = !_smtpExpanded;
                                });
                              },
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(16),
                                topRight: Radius.circular(16),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.mail_outline,
                                      color: const Color(0xFFff6b6b).withOpacity(0.8),
                                      size: 24,
                                    ),
                                    const SizedBox(width: 12),
                                    const Text(
                                      'SMTP邮件配置',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const Spacer(),
                                    // 配置状态指示器
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: hasSmtpConfig
                                            ? Colors.green.withOpacity(0.2)
                                            : Colors.orange.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: hasSmtpConfig
                                              ? Colors.green.withOpacity(0.5)
                                              : Colors.orange.withOpacity(0.5),
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            hasSmtpConfig ? Icons.check_circle : Icons.warning,
                                            color: hasSmtpConfig ? Colors.green : Colors.orange,
                                            size: 14,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            hasSmtpConfig ? '已配置' : '未配置',
                                            style: TextStyle(
                                              color: hasSmtpConfig ? Colors.green : Colors.orange,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    // 展开/收起图标
                                    AnimatedRotation(
                                      turns: _smtpExpanded ? 0.5 : 0,
                                      duration: const Duration(milliseconds: 300),
                                      child: Icon(
                                        Icons.keyboard_arrow_down,
                                        color: Colors.white.withOpacity(0.6),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            // 可展开的配置内容
                            AnimatedCrossFade(
                              firstChild: const SizedBox.shrink(),
                              secondChild: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  children: [
                                    _buildInputField(
                                      controller: _smtpHostController,
                                      label: 'SMTP服务器',
                                      icon: Icons.dns,
                                      hint: 'smtp.qq.com',
                                    ),
                                    const SizedBox(height: 16),
                                    _buildInputField(
                                      controller: _smtpPortController,
                                      label: '端口',
                                      icon: Icons.settings_ethernet,
                                      keyboardType: TextInputType.number,
                                      hint: '465 (SSL) 或 587 (TLS)',
                                    ),
                                    const SizedBox(height: 16),
                                    _buildInputField(
                                      controller: _smtpUsernameController,
                                      label: '用户名（邮箱）',
                                      icon: Icons.email,
                                      keyboardType: TextInputType.emailAddress,
                                    ),
                                    const SizedBox(height: 16),
                                    _buildInputField(
                                      controller: _smtpPasswordController,
                                      label: '密码或授权码',
                                      icon: Icons.lock,
                                      obscureText: true,
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: SizedBox(
                                            height: 48,
                                            child: ElevatedButton(
                                              onPressed: _isLoading ? null : _saveSmtpConfig,
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(0xFFff6b6b),
                                                foregroundColor: Colors.white,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                              ),
                                              child: _isLoading
                                                  ? const SizedBox(
                                                      width: 20,
                                                      height: 20,
                                                      child: CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        valueColor: AlwaysStoppedAnimation<Color>(
                                                            Colors.white),
                                                      ),
                                                    )
                                                  : const Text('保存SMTP配置'),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: SizedBox(
                                            height: 48,
                                            child: OutlinedButton(
                                              onPressed: hasSmtpConfig && !_isLoading
                                                  ? _sendTestEmail
                                                  : null,
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor: hasSmtpConfig
                                                    ? const Color(0xFF4ecdc4)
                                                    : Colors.grey,
                                                side: BorderSide(
                                                  color: hasSmtpConfig
                                                      ? const Color(0xFF4ecdc4)
                                                      : Colors.grey.withOpacity(0.5),
                                                  width: 1.5,
                                                ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                              ),
                                              child: const Text('发送测试邮件'),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              crossFadeState: _smtpExpanded
                                  ? CrossFadeState.showSecond
                                  : CrossFadeState.showFirst,
                              duration: const Duration(milliseconds: 300),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // 说明部分
                      _buildSectionTitle('使用说明'),
                      const SizedBox(height: 16),
                      _buildCard([
                        _buildInfoItem(
                          icon: Icons.info_outline,
                          title: 'SMTP配置',
                          description: '配置SMTP服务器后，系统才能在您超时未签到时发送邮件通知。',
                        ),
                        const SizedBox(height: 12),
                        _buildInfoItem(
                          icon: Icons.security,
                          title: '隐私保护',
                          description: '您的SMTP配置加密存储在服务器，仅用于发送警报邮件。',
                        ),
                        const SizedBox(height: 12),
                        _buildInfoItem(
                          icon: Icons.contact_phone,
                          title: '紧急联系人',
                          description: '可以添加多个紧急联系人，警报邮件将发送给所有联系人。',
                        ),
                      ]),

                      const SizedBox(height: 24),

                      // 退出登录
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton(
                          onPressed: () async {
                            await ApiService.logout();
                            if (!mounted) return;
                            Navigator.of(context).pushNamedAndRemoveUntil(
                              '/',
                              (route) => false,
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: BorderSide(
                              color: Colors.red.withOpacity(0.5),
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('退出登录'),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 删除账户按钮
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _showDeleteAccountDialog,
                          icon: const Icon(Icons.delete_forever),
                          label: const Text('删除账户'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: BorderSide(
                              color: Colors.red.withOpacity(0.5),
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showDeleteAccountDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a2e),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.warning_rounded,
              color: Colors.red.withOpacity(0.8),
              size: 28,
            ),
            const SizedBox(width: 12),
            const Text(
              '删除账户',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: const Text(
          '此操作不可撤销！删除后将：\n\n'
          '• 删除所有签到记录\n'
          '• 删除所有紧急联系人\n'
          '• 删除所有设置信息\n'
          '• 删除账户信息\n\n'
          '确定要删除账户吗？',
          style: TextStyle(color: Colors.white70, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              '取消',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('确认删除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteAccount();
    }
  }

  Future<void> _deleteAccount() async {
    setState(() => _isLoading = true);

    try {
      final result = await ApiService.deleteAccount();

      if (mounted) {
        if (result['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('账户已成功删除'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );

          // 延迟2秒后跳转到登录页
          await Future.delayed(const Duration(seconds: 2));

          if (mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => LoginPage()),
              (route) => false,
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['error'] ?? '删除失败'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('删除失败: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.white.withOpacity(0.9),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
    String? hint,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 15,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: Colors.white.withOpacity(0.6),
          fontSize: 13,
        ),
        hintText: hint,
        hintStyle: TextStyle(
          color: Colors.white.withOpacity(0.3),
        ),
        prefixIcon: Icon(
          icon,
          color: Colors.white.withOpacity(0.7),
          size: 20,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.white.withOpacity(0.1),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.white.withOpacity(0.1),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFFff6b6b),
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Colors.red,
            width: 1,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Colors.red,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.all(16),
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFFff6b6b).withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: const Color(0xFFff6b6b),
            size: 18,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withOpacity(0.6),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
