import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  int _consecutiveDays = 0;
  int _todayCheckins = 0;
  DateTime? _lastCheckin;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);

    try {
      final result = await ApiService.getStats();

      if (result['success'] && mounted) {
        final data = result['data'];
        setState(() {
          _consecutiveDays = data['consecutiveDays'] ?? 0;
          _todayCheckins = data['todayCheckins'] ?? 0;

          if (data['lastCheckin'] != null) {
            // 解析UTC时间并转换为本地时间
            final utcTime = DateTime.parse(data['lastCheckin']);
            _lastCheckin = utcTime.toLocal();
            // Sync to local storage
            StorageService.setLastCheckIn(_lastCheckin!);
          }

          _isLoading = false;
        });
      } else if (mounted) {
        // Fallback to local storage if API fails
        final lastCheckIn = await StorageService.getLastCheckIn();
        setState(() {
          _lastCheckin = lastCheckIn;
          _isLoading = false;
        });
      }
    } catch (e) {
      // Fallback to local storage on error
      final lastCheckIn = await StorageService.getLastCheckIn();
      if (mounted) {
        setState(() {
          _lastCheckin = lastCheckIn;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                      '签到统计',
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

              // 统计内容
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: _isLoading
                      ? Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              const Color(0xFFff6b6b),
                            ),
                          ),
                        )
                      : Column(
                          children: [
                            // 连续签到卡片
                            _buildStatCard(
                              icon: Icons.local_fire_department_outlined,
                              title: '连续签到',
                              value: _consecutiveDays,
                              subtitle: '天',
                              color: const Color(0xFFff6b6b),
                            ),
                            const SizedBox(height: 16),

                            // 今日签到次数卡片
                            _buildStatCard(
                              icon: Icons.today_outlined,
                              title: '今日签到',
                              value: _todayCheckins,
                              subtitle: '次',
                              color: const Color(0xFF4ecdc4),
                            ),
                            const SizedBox(height: 24),

                            // 最近签到记录
                            if (_lastCheckin != null) _buildRecentCheckIns(),
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

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required int value,
    required String subtitle,
    required Color color,
  }) {
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
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.6),
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$value',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: color,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.5),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentCheckIns() {
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
        children: [
          Row(
            children: [
              Icon(
                Icons.history_outlined,
                color: Colors.white.withOpacity(0.6),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '最后签到',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildCheckInItem(
            date: DateFormat('MM月dd日 HH:mm').format(_lastCheckin!),
            label: '最近',
            isRecent: true,
          ),
        ],
      ),
    );
  }

  Widget _buildCheckInItem({
    required String date,
    required String label,
    required bool isRecent,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isRecent
            ? const Color(0xFFff6b6b).withOpacity(0.1)
            : Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isRecent
              ? const Color(0xFFff6b6b).withOpacity(0.3)
              : Colors.white.withOpacity(0.05),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isRecent
                  ? const Color(0xFFff6b6b)
                  : Colors.white.withOpacity(0.3),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              date,
              style: TextStyle(
                fontSize: 15,
                color: Colors.white.withOpacity(0.9),
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isRecent
                  ? const Color(0xFFff6b6b).withOpacity(0.2)
                  : Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isRecent
                    ? const Color(0xFFff6b6b)
                    : Colors.white.withOpacity(0.5),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
