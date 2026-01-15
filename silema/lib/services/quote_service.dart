import 'dart:math';

class QuoteService {
  static final Random _random = Random();

  static final List<String> _quotes = [
    '活着就是最大的胜利',
    '每一天都是新的开始',
    '签到是给生活的一个承诺',
    '安全，从不忘签到开始',
    '你的平安，有人在乎',
    '今天也要加油鸭',
    '生活需要仪式感',
    '记得给自己一个微笑',
    '你的存在就是意义',
    '明天会更好',
    '保持热爱，奔赴山海',
    '星光不问赶路人',
    '愿你被这个世界温柔以待',
    '签到打卡，热爱生活',
    '每一天都值得纪念',
    '平安是最好的礼物',
    '活着真好',
    '珍惜当下，不负韶华',
    '愿你眼里有光，心中有爱',
    '做一个温暖的人',
  ];

  static String getRandomQuote() {
    return _quotes[_random.nextInt(_quotes.length)];
  }

  static String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 6) {
      return '夜深了，注意休息';
    } else if (hour < 9) {
      return '早安，新的一天';
    } else if (hour < 12) {
      return '上午好';
    } else if (hour < 14) {
      return '中午好';
    } else if (hour < 18) {
      return '下午好';
    } else if (hour < 22) {
      return '晚上好';
    } else {
      return '夜深了';
    }
  }
}
