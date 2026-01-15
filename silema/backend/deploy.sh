#!/bin/bash

# "死了吗" 后端部署脚本

echo "🚀 开始部署..."

# 检查Node.js是否安装
if ! command -v node &> /dev/null; then
    echo "❌ Node.js未安装，请先安装Node.js"
    exit 1
fi

echo "✅ Node.js版本: $(node -v)"

# 安装依赖
echo "📦 安装依赖..."
npm install

# 检查.env文件
if [ ! -f .env ]; then
    echo "⚠️ 未找到.env文件，从.env.example复制..."
    cp .env.example .env
    echo "⚠️ 请编辑.env文件，设置JWT_SECRET等配置"
    exit 1
fi

# 创建data目录
mkdir -p data

echo "✅ 部署完成！"
echo ""
echo "📝 后续步骤："
echo "1. 编辑 .env 文件，修改JWT_SECRET"
echo "2. 运行 'npm start' 启动服务"
echo "3. 或使用 'npm run dev' 开发模式"
echo ""
echo "💡 使用PM2管理进程（推荐）："
echo "  pm2 start src/server.js --name silema-backend"
echo "  pm2 startup"
echo "  pm2 save"
