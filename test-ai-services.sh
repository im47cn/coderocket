#!/bin/bash

# AI Services Test Script
# 测试多AI服务功能的集成测试脚本

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 测试结果统计
TESTS_TOTAL=0
TESTS_PASSED=0
TESTS_FAILED=0

# 测试函数
run_test() {
    local test_name=$1
    local test_command=$2
    local expected_exit_code=${3:-0}
    
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    echo -e "\n${BLUE}[TEST $TESTS_TOTAL] $test_name${NC}"
    echo "命令: $test_command"
    
    # 执行测试命令
    eval "$test_command"
    local actual_exit_code=$?
    
    if [ $actual_exit_code -eq $expected_exit_code ]; then
        echo -e "${GREEN}✓ PASSED${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗ FAILED (期望退出码: $expected_exit_code, 实际退出码: $actual_exit_code)${NC}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

# 显示测试结果
show_test_results() {
    echo -e "\n${BLUE}=== 测试结果汇总 ===${NC}"
    echo "总测试数: $TESTS_TOTAL"
    echo -e "通过: ${GREEN}$TESTS_PASSED${NC}"
    echo -e "失败: ${RED}$TESTS_FAILED${NC}"
    
    if [ $TESTS_FAILED -eq 0 ]; then
        echo -e "\n${GREEN}🎉 所有测试通过！${NC}"
        return 0
    else
        echo -e "\n${RED}❌ 有测试失败${NC}"
        return 1
    fi
}

echo -e "${BLUE}=== CodeReview CLI 多AI服务测试 ===${NC}"
echo "开始测试多AI服务功能..."

# 1. 测试AI服务管理器
run_test "AI服务管理器 - 状态检查" "./lib/ai-service-manager.sh status"
run_test "AI服务管理器 - 测试功能" "./lib/ai-service-manager.sh test"

# 2. 测试AI配置工具
run_test "AI配置工具 - 显示配置" "./lib/ai-config.sh show"
run_test "AI配置工具 - 获取配置" "./lib/ai-config.sh get AI_SERVICE"

# 3. 测试各个AI服务模块
echo -e "\n${YELLOW}=== 测试各个AI服务模块 ===${NC}"
echo -e "${BLUE}注意: 以下测试预期失败，因为需要有效的API密钥${NC}"

# 测试OpenCode服务 (预期失败 - 需要API密钥)
echo -e "${YELLOW}→ OpenCode服务测试 (预期失败: 未配置API密钥)${NC}"
run_test "OpenCode服务 - 状态检查" "./lib/opencode-service.sh test" 1

# 测试ClaudeCode服务 (预期失败 - 需要API密钥)
echo -e "${YELLOW}→ ClaudeCode服务测试 (预期失败: 未配置API密钥)${NC}"
run_test "ClaudeCode服务 - 状态检查" "./lib/claudecode-service.sh test" 1

# 4. 测试配置设置和获取
echo -e "\n${YELLOW}=== 测试配置管理 ===${NC}"

run_test "设置AI服务配置" "./lib/ai-config.sh set TEST_KEY test_value"
run_test "获取AI服务配置" "./lib/ai-config.sh get TEST_KEY"
run_test "设置AI超时配置" "./lib/ai-config.sh set AI_TIMEOUT 45"
run_test "获取AI超时配置" "./lib/ai-config.sh get AI_TIMEOUT"

# 5. 测试备用方案
echo -e "\n${YELLOW}=== 测试备用方案 ===${NC}"

# 创建临时测试脚本
cat > test_fallback.sh << 'EOF'
#!/bin/bash
source ./lib/ai-service-manager.sh
# 测试MR标题生成备用方案
result=$(generate_fallback_response "mr_title" "feature/test-feature")
echo "$result"
if [[ "$result" == *"Feature"* ]]; then
    exit 0
else
    exit 1
fi
EOF

chmod +x test_fallback.sh
run_test "备用方案 - MR标题生成" "./test_fallback.sh"
rm -f test_fallback.sh

# 6. 测试文件权限
echo -e "\n${YELLOW}=== 测试文件权限 ===${NC}"

run_test "检查AI服务管理器权限" "test -x ./lib/ai-service-manager.sh"
run_test "检查AI配置工具权限" "test -x ./lib/ai-config.sh"
run_test "检查OpenCode服务权限" "test -x ./lib/opencode-service.sh"
run_test "检查ClaudeCode服务权限" "test -x ./lib/claudecode-service.sh"

# 7. 测试配置文件
echo -e "\n${YELLOW}=== 测试配置文件 ===${NC}"

run_test "检查项目配置文件存在" "test -f .ai-config"
run_test "检查环境变量模板" "test -f .env.example"

# 8. 测试Git hooks更新
echo -e "\n${YELLOW}=== 测试Git hooks ===${NC}"

run_test "检查post-commit hook" "test -f githooks/post-commit"
run_test "检查pre-push hook" "test -f githooks/pre-push"

# 检查hooks中是否包含AI服务管理器调用
run_test "post-commit包含AI服务调用" "grep -q 'call_ai_for_review' githooks/post-commit"
run_test "pre-push包含AI服务调用" "grep -q 'generate_mr_title_with_ai' githooks/pre-push"

# 9. 测试文档
echo -e "\n${YELLOW}=== 测试文档 ===${NC}"

run_test "检查AI服务指南文档" "test -f docs/AI_SERVICES_GUIDE.md"
run_test "检查README更新" "grep -q 'OpenCode\|ClaudeCode' README.md"

# 10. 集成测试
echo -e "\n${YELLOW}=== 集成测试 ===${NC}"

# 测试完整的AI服务切换流程
run_test "切换到OpenCode服务" "./lib/ai-config.sh set AI_SERVICE opencode"
run_test "验证服务切换" "test \"\$(./lib/ai-config.sh get AI_SERVICE)\" = \"opencode\""

run_test "切换到ClaudeCode服务" "./lib/ai-config.sh set AI_SERVICE claudecode"
run_test "验证服务切换" "test \"\$(./lib/ai-config.sh get AI_SERVICE)\" = \"claudecode\""

# 切换回Gemini
run_test "切换回Gemini服务" "./lib/ai-config.sh set AI_SERVICE gemini"
run_test "验证服务切换" "test \"\$(./lib/ai-config.sh get AI_SERVICE)\" = \"gemini\""

# 11. 清理测试
echo -e "\n${YELLOW}=== 清理测试环境 ===${NC}"

# 清理测试配置
./lib/ai-config.sh set TEST_KEY "" > /dev/null 2>&1

echo -e "\n${BLUE}=== 测试完成 ===${NC}"

# 显示最终结果
show_test_results
