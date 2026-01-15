import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/storage_service.dart';
import '../services/api_service.dart';
import '../services/quote_service.dart';
import 'settings_page.dart';
import 'stats_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  DateTime? _lastCheckIn;
  late AnimationController _pulseController;
  late AnimationController _scaleController;
  late AnimationController _rippleController;
  late AnimationController _successController;
  late AnimationController _fadeController;
  bool _isPressed = false;
  bool _showSuccess = false;
  final List<Particle> _particles = [];
  final Random _random = Random();
  String _quote = '';

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadQuote();

    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _rippleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _successController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeController.forward();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _scaleController.dispose();
    _rippleController.dispose();
    _successController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await StorageService.init();
    await ApiService.init();
    setState(() {
      _lastCheckIn = StorageService.getLastCheckIn();
    });
  }

  void _loadQuote() {
    setState(() {
      _quote = QuoteService.getRandomQuote();
    });
  }

  void _generateParticles() {
    _particles.clear();
    for (int i = 0; i < 30; i++) {
      _particles.add(Particle(_random));
    }
  }

  Future<void> _checkIn() async {
    if (_isPressed) return;

    setState(() => _isPressed = true);

    await _scaleController.forward();
    await _scaleController.reverse();

    _rippleController.forward(from: 0);
    _generateParticles();

    // 使用API签到
    final result = await ApiService.checkIn();
    final now = DateTime.now();

    if (result['success']) {
      setState(() {
        _lastCheckIn = now;
        _showSuccess = true;
        _isPressed = false;
        _quote = QuoteService.getRandomQuote();
      });
    } else {
      // API调用失败，使用本地存储作为后备
      await StorageService.setLastCheckIn(now);
      setState(() {
        _lastCheckIn = now;
        _showSuccess = true;
        _isPressed = false;
        _quote = QuoteService.getRandomQuote();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['error'] ?? '签到失败，已使用本地记录'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }

    _successController.forward();

    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        setState(() => _showSuccess = false);
      }
    });
  }

  void _goToSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsPage()),
    ).then((_) => _loadData());
  }

  void _goToStats() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const StatsPage()),
    );
  }

  Color _getStatusColor(int hours) {
    if (hours < 24) return Colors.green;
    if (hours < 36) return Colors.orange;
    return Colors.red;
  }

  String _getStatusText(int? hours) {
    if (hours == null) return '首次签到';
    if (hours < 1) return '刚刚';
    if (hours < 24) return '安全';
    if (hours < 48) return '警告';
    return '危险';
  }

  int? _getHoursSinceLastCheckIn() {
    if (_lastCheckIn == null) return null;
    final now = DateTime.now();
    return now.difference(_lastCheckIn!).inHours;
  }

  @override
  Widget build(BuildContext context) {
    final hours = _getHoursSinceLastCheckIn();
    final statusColor = hours != null ? _getStatusColor(hours) : Colors.grey;
    final statusText = _getStatusText(hours);
    final greeting = QuoteService.getGreeting();

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
          child: Stack(
            children: [
              Positioned(
                top: -100,
                right: -100,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.03),
                  ),
                ),
              ),
              Positioned(
                bottom: -150,
                left: -150,
                child: Container(
                  width: 400,
                  height: 400,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.02),
                  ),
                ),
              ),

              if (_showSuccess)
                ..._particles.map((particle) {
                  return AnimatedBuilder(
                    animation: _successController,
                    builder: (context, child) {
                      final progress = _successController.value;
                      final opacity = (1 - progress) * particle.opacity;
                      final position = particle.position(progress * 400);

                      return Positioned(
                        left: MediaQuery.of(context).size.width / 2 + position.dx,
                        top: MediaQuery.of(context).size.height / 2 + position.dy,
                        child: Opacity(
                          opacity: opacity.clamp(0.0, 1.0),
                          child: Container(
                            width: particle.size,
                            height: particle.size,
                            decoration: BoxDecoration(
                              color: particle.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }),

              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: statusColor.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: statusColor,
                                  boxShadow: [
                                    BoxShadow(
                                      color: statusColor.withOpacity(0.5),
                                      blurRadius: 4,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                statusText,
                                style: TextStyle(
                                  color: statusColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: _goToStats,
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
                                    Icons.bar_chart_outlined,
                                    color: Colors.white.withOpacity(0.8),
                                    size: 24,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: _goToSettings,
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
                                    Icons.settings_outlined,
                                    color: Colors.white.withOpacity(0.8),
                                    size: 24,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: Center(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          if (_showSuccess)
                            AnimatedBuilder(
                              animation: _rippleController,
                              builder: (context, child) {
                                final progress = _rippleController.value;
                                return Transform.scale(
                                  scale: 1 + progress * 3,
                                  child: Opacity(
                                    opacity: 1 - progress,
                                    child: Container(
                                      width: 180,
                                      height: 180,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.green.withOpacity(0.5),
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),

                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                greeting,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white.withOpacity(0.6),
                                  fontWeight: FontWeight.w400,
                                  letterSpacing: 1,
                                ),
                              ),
                              const SizedBox(height: 16),

                              AnimatedOpacity(
                                opacity: _showSuccess ? 0.0 : 1.0,
                                duration: const Duration(milliseconds: 300),
                                child: Text(
                                  '死了吗',
                                  style: TextStyle(
                                    fontSize: 56,
                                    fontWeight: FontWeight.w300,
                                    color: Colors.white.withOpacity(0.95),
                                    letterSpacing: 12,
                                    height: 1.2,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),

                              if (_showSuccess)
                                AnimatedBuilder(
                                  animation: _successController,
                                  builder: (context, child) {
                                    final scale = (_successController.value * 1.5).clamp(0.0, 1.0);
                                    final opacity = (1 - (_successController.value - 0.5) * 2).clamp(0.0, 1.0);

                                    return Transform.scale(
                                      scale: scale,
                                      child: Opacity(
                                        opacity: opacity,
                                        child: Container(
                                          width: 120,
                                          height: 120,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Colors.green.withOpacity(0.2),
                                            border: Border.all(
                                              color: Colors.green,
                                              width: 3,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.check_rounded,
                                            color: Colors.green,
                                            size: 60,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),

                              const SizedBox(height: 20),

                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                child: _showSuccess
                                    ? Column(
                                        key: const ValueKey('success'),
                                        children: [
                                          Text(
                                            '签到成功！',
                                            style: TextStyle(
                                              fontSize: 28,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.green.withOpacity(0.9),
                                              letterSpacing: 2,
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          Text(
                                            _quote,
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.white.withOpacity(0.6),
                                              fontStyle: FontStyle.italic,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      )
                                    : Column(
                                        key: const ValueKey('subtitle'),
                                        children: [
                                          Text(
                                            '每日签到，保持安全',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.white.withOpacity(0.4),
                                              letterSpacing: 2,
                                              fontWeight: FontWeight.w300,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            _quote,
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.white.withOpacity(0.5),
                                              fontStyle: FontStyle.italic,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ),
                              ),

                              SizedBox(height: _showSuccess ? 60 : 80),

                              if (!_showSuccess)
                                AnimatedBuilder(
                                  animation: _pulseController,
                                  builder: (context, child) {
                                    return Transform.scale(
                                      scale: 1.0 + (_pulseController.value * 0.03),
                                      child: GestureDetector(
                                        onTapDown: (_) => _scaleController.forward(),
                                        onTapUp: (_) => _scaleController.reverse(),
                                        onTapCancel: () => _scaleController.reverse(),
                                        onTap: _checkIn,
                                        child: AnimatedBuilder(
                                          animation: _scaleController,
                                          builder: (context, child) {
                                            return Transform.scale(
                                              scale: _scaleController.value * 0.95 + (1 - _scaleController.value) * 1.0,
                                              child: Container(
                                                width: 180,
                                                height: 180,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  gradient: const LinearGradient(
                                                    begin: Alignment(-1, -1),
                                                    end: Alignment(1, 1),
                                                    colors: [
                                                      Color(0xFFff6b6b),
                                                      Color(0xFFee5a6f),
                                                      Color(0xFFc44569),
                                                    ],
                                                    stops: [0.0, 0.5, 1.0],
                                                  ),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: const Color(0xFFff6b6b).withOpacity(0.4),
                                                      blurRadius: 40,
                                                      spreadRadius: 0,
                                                      offset: const Offset(0, 10),
                                                    ),
                                                    BoxShadow(
                                                      color: const Color(0xFFee5a6f).withOpacity(0.3),
                                                      blurRadius: 20,
                                                      spreadRadius: -5,
                                                    ),
                                                  ],
                                                ),
                                                child: const Center(
                                                  child: Text(
                                                    '签到',
                                                    style: TextStyle(
                                                      fontSize: 40,
                                                      fontWeight: FontWeight.w300,
                                                      color: Colors.white,
                                                      letterSpacing: 12,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              const SizedBox(height: 60),

                              AnimatedSlide(
                                offset: _showSuccess ? const Offset(0, 0.5) : Offset.zero,
                                duration: const Duration(milliseconds: 300),
                                child: AnimatedOpacity(
                                  opacity: _showSuccess ? 0.0 : 1.0,
                                  duration: const Duration(milliseconds: 300),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
                                        Text(
                                          '最后签到',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.white.withOpacity(0.4),
                                            letterSpacing: 1.5,
                                            fontWeight: FontWeight.w300,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          _lastCheckIn != null
                                              ? DateFormat('MM/dd HH:mm').format(_lastCheckIn!)
                                              : '从未签到',
                                          style: TextStyle(
                                            fontSize: 20,
                                            color: Colors.white.withOpacity(0.9),
                                            fontWeight: FontWeight.w400,
                                            letterSpacing: 1,
                                          ),
                                        ),
                                        if (hours != null && hours >= 24) ...[
                                          const SizedBox(height: 12),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: Colors.orange.withOpacity(0.15),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              '${hours}小时前',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.orange.withOpacity(0.9),
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 40),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class Particle {
  final Random random;
  final Color color;
  final double size;
  final double opacity;
  final double angle;
  final double speed;

  Particle(this.random)
      : color = [
          Colors.green,
          Colors.blue,
          Colors.purple,
          Colors.orange,
          Colors.pink,
          Colors.cyan,
        ][random.nextInt(6)],
        size = random.nextDouble() * 8 + 4,
        opacity = random.nextDouble() * 0.5 + 0.5,
        angle = random.nextDouble() * 2 * pi,
        speed = random.nextDouble() * 0.5 + 0.5;

  Offset position(double distance) {
    return Offset(
      cos(angle) * distance * speed,
      sin(angle) * distance * speed,
    );
  }
}
