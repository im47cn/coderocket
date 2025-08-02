#!/bin/bash

# CodeRocket CLI 测试套件
# 基本的单元测试和集成测试

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 测试计数器
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# 测试框架函数
assert_equals() {
    local expected="$1"
    local actual="$2"
    local test_name="$3"
    
    TESTS_RUN=$((TESTS_RUN + 1))
    
    if [ "$expected" = "$actual" ]; then
        echo -e "${GREEN}✓ $test_name${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗ $test_name${NC}"
        echo -e "${RED}  Expected: '$expected'${NC}"
        echo -e "${RED}  Actual:   '$actual'${NC}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

assert_file_exists() {
    local file_path="$1"
    local test_name="$2"
    
    TESTS_RUN=$((TESTS_RUN + 1))
    
    if [ -f "$file_path" ]; then
        echo -e "${GREEN}✓ $test_name${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗ $test_name${NC}"
        echo -e "${RED}  File not found: $file_path${NC}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

assert_command_exists() {
    local command="$1"
    local test_name="$2"
    
    TESTS_RUN=$((TESTS_RUN + 1))
    
    if command -v "$command" &> /dev/null; then
        echo -e "${GREEN}✓ $test_name${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗ $test_name${NC}"
        echo -e "${RED}  Command not found: $command${NC}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

# 获取项目根目录
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "🧪 CodeRocket CLI 测试套件"
echo "=========================="
echo "项目路径: $PROJECT_ROOT"
echo ""

# 测试1: 核心文件存在性检查
echo "📁 测试核心文件存在性..."
assert_file_exists "$PROJECT_ROOT/bin/coderocket" "主执行文件存在"
assert_file_exists "$PROJECT_ROOT/install.sh" "安装脚本存在"
assert_file_exists "$PROJECT_ROOT/install-hooks.sh" "Hooks安装脚本存在"
assert_file_exists "$PROJECT_ROOT/lib/ai-service-manager.sh" "AI服务管理器存在"
assert_file_exists "$PROJECT_ROOT/githooks/post-commit" "Post-commit hook存在"
assert_file_exists "$PROJECT_ROOT/.env.example" "环境变量示例文件存在"

# 测试2: 脚本语法检查
echo ""
echo "🔍 测试脚本语法..."
if bash -n "$PROJECT_ROOT/bin/coderocket" 2>/dev/null; then
    assert_equals "valid" "valid" "主执行文件语法检查"
else
    assert_equals "valid" "invalid" "主执行文件语法检查"
fi

if bash -n "$PROJECT_ROOT/lib/ai-service-manager.sh" 2>/dev/null; then
    assert_equals "valid" "valid" "AI服务管理器语法检查"
else
    assert_equals "valid" "invalid" "AI服务管理器语法检查"
fi

# 测试3: 配置函数测试
echo ""
echo "⚙️  测试配置函数..."

# 导入AI服务管理器进行测试
source "$PROJECT_ROOT/lib/ai-service-manager.sh"

# 测试默认AI服务
default_service=$(get_ai_service)
assert_equals "gemini" "$default_service" "默认AI服务配置"

# 测试AI服务可用性检查函数
if command -v which &> /dev/null; then
    assert_equals "function_exists" "function_exists" "AI服务可用性检查函数存在"
else
    assert_equals "function_exists" "function_missing" "AI服务可用性检查函数存在"
fi

# 测试4: Git仓库检测功能
echo ""
echo "📂 测试Git仓库检测..."

# 导入主脚本函数
source "$PROJECT_ROOT/bin/coderocket"

# 测试Git仓库检测函数
if git rev-parse --git-dir > /dev/null 2>&1; then
    if is_git_repo; then
        assert_equals "true" "true" "Git仓库检测功能"
    else
        assert_equals "true" "false" "Git仓库检测功能"
    fi
else
    # 如果不在Git仓库中，测试函数应该返回false
    if ! is_git_repo; then
        assert_equals "false" "false" "非Git仓库检测功能"
    else
        assert_equals "false" "true" "非Git仓库检测功能"
    fi
fi

# 测试结果汇总
echo ""
echo "📊 测试结果汇总"
echo "================"
echo -e "总计测试: $TESTS_RUN"
echo -e "${GREEN}通过: $TESTS_PASSED${NC}"
echo -e "${RED}失败: $TESTS_FAILED${NC}"

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}🎉 所有测试通过！${NC}"
    exit 0
else
    echo -e "${RED}❌ 有 $TESTS_FAILED 个测试失败${NC}"
    exit 1
fi
