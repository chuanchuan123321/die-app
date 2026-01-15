#!/bin/bash

# "死了吗"应用构建脚本
# 用于快速修改API地址并构建APK

echo "🚀 开始构建生产版本..."
echo ""

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# 检查参数
if [ -z "$1" ]; then
    echo -e "${RED}错误: 请提供服务器地址${NC}"
    echo ""
    echo "使用方法:"
    echo "  ./build.sh http://123.45.67.89:3000/api"
    echo "  ./build.sh https://your-domain.com/api"
    echo ""
    exit 1
fi

API_URL=$1

echo -e "${YELLOW}API地址: $API_URL${NC}"
echo ""

# 确认
read -p "确认构建? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "已取消"
    exit 1
fi

# 构建APK
echo ""
echo -e "${GREEN}📦 正在构建APK...${NC}"
flutter build apk --release \
  --dart-define=API_BASE_URL=$API_URL \
  --target-platform android-arm64

# 检查构建结果
if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}✅ 构建成功！${NC}"
    echo ""
    echo "APK文件位置:"
    echo "  build/app/outputs/flutter-apk/app-release.apk"
    echo ""
    echo "下一步:"
    echo "  1. 将APK传输到手机"
    echo "  2. 安装应用"
    echo "  3. 打开应用测试"
    echo ""

    # 获取APK大小
    APK_SIZE=$(du -h build/app/outputs/flutter-apk/app-release.apk | cut -f1)
    echo "APK大小: $APK_SIZE"
    echo ""

    # 如果有scutil，在macOS上创建分享链接（仅适用于本地）
    if command -v brew &> /dev/null; then
        echo "💡 提示: 可以通过以下方式传输到手机:"
        echo "   - 微信/QQ发送"
        echo "   - 云盘上传"
        echo "   - 数据线传输"
    fi
else
    echo ""
    echo -e "${RED}❌ 构建失败${NC}"
    echo "请检查错误信息并重试"
    exit 1
fi
