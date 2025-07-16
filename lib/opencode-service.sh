#!/bin/bash

# OpenCode AI Service Integration
# OpenCode AI服务集成模块

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 导入配置管理
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/ai-config.sh"

# OpenCode 默认配置
DEFAULT_OPENCODE_API_URL="https://api.opencode.com/v1"
DEFAULT_OPENCODE_MODEL="opencode-pro"
DEFAULT_TIMEOUT=30

# 获取OpenCode配置
get_opencode_config() {
    local config_key=$1
    local default_value=$2
    
    local value=$(get_config_value "$config_key")
    if [ -z "$value" ]; then
        value="$default_value"
    fi
    
    echo "$value"
}

# 检查OpenCode CLI是否可用
check_opencode_cli() {
    if command -v opencode &> /dev/null; then
        return 0
    else
        return 1
    fi
}

# 安装OpenCode CLI
install_opencode_cli() {
    echo -e "${YELLOW}→ 安装 OpenCode CLI...${NC}"
    
    if check_opencode_cli; then
        echo -e "${GREEN}✓ OpenCode CLI 已安装${NC}"
        return 0
    fi
    
    # 尝试通过npm安装
    if command -v npm &> /dev/null; then
        if npm install -g @opencode/cli; then
            echo -e "${GREEN}✓ OpenCode CLI 安装成功${NC}"
            return 0
        else
            echo -e "${RED}✗ OpenCode CLI 安装失败${NC}"
            return 1
        fi
    else
        echo -e "${RED}✗ 需要安装 Node.js 和 npm${NC}"
        return 1
    fi
}

# 配置OpenCode API
configure_opencode_api() {
    local api_key=$(get_opencode_config "OPENCODE_API_KEY")
    local api_url=$(get_opencode_config "OPENCODE_API_URL" "$DEFAULT_OPENCODE_API_URL")
    
    if [ -z "$api_key" ]; then
        echo -e "${RED}❌ 未设置 OPENCODE_API_KEY${NC}"
        echo "请设置 OpenCode API 密钥："
        echo "  方式1: 环境变量 export OPENCODE_API_KEY='your_key'"
        echo "  方式2: 配置文件 ./lib/ai-config.sh set OPENCODE_API_KEY 'your_key'"
        return 1
    fi
    
    # 配置OpenCode CLI
    if check_opencode_cli; then
        opencode config set api_key "$api_key"
        opencode config set api_url "$api_url"
        echo -e "${GREEN}✓ OpenCode API 配置完成${NC}"
        return 0
    else
        echo -e "${RED}❌ OpenCode CLI 未安装${NC}"
        return 1
    fi
}

# 调用OpenCode API进行文本生成
call_opencode_api() {
    local prompt=$1
    local timeout=${2:-$DEFAULT_TIMEOUT}
    local model=$(get_opencode_config "OPENCODE_MODEL" "$DEFAULT_OPENCODE_MODEL")
    local api_key=$(get_opencode_config "OPENCODE_API_KEY")
    local api_url=$(get_opencode_config "OPENCODE_API_URL" "$DEFAULT_OPENCODE_API_URL")
    
    if [ -z "$api_key" ]; then
        echo -e "${RED}❌ 未设置 OPENCODE_API_KEY${NC}" >&2
        return 1
    fi
    
    # 如果有CLI工具，优先使用CLI
    if check_opencode_cli; then
        echo "$prompt" | timeout "$timeout" opencode generate --model "$model" --auto-confirm 2>/dev/null
        return $?
    fi
    
    # 否则使用curl直接调用API
    local json_payload=$(cat <<EOF
{
    "model": "$model",
    "prompt": "$prompt",
    "max_tokens": 2048,
    "temperature": 0.7
}
EOF
)
    
    local response=$(timeout "$timeout" curl -s \
        -H "Authorization: Bearer $api_key" \
        -H "Content-Type: application/json" \
        -d "$json_payload" \
        "$api_url/completions" 2>/dev/null)
    
    if [ $? -eq 0 ] && [ ! -z "$response" ]; then
        # 解析JSON响应，提取生成的文本
        echo "$response" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    if 'choices' in data and len(data['choices']) > 0:
        print(data['choices'][0]['text'].strip())
    elif 'content' in data:
        print(data['content'].strip())
    else:
        print('')
except:
    print('')
" 2>/dev/null
        return 0
    else
        return 1
    fi
}

# OpenCode代码审查
opencode_code_review() {
    local prompt_file=$1
    local additional_prompt=$2
    
    if [ ! -f "$prompt_file" ]; then
        echo -e "${RED}❌ 提示词文件不存在: $prompt_file${NC}" >&2
        return 1
    fi
    
    # 读取提示词文件内容
    local prompt_content=$(cat "$prompt_file")
    
    # 组合完整提示词
    local full_prompt="$prompt_content

$additional_prompt"
    
    # 调用OpenCode API
    call_opencode_api "$full_prompt"
}

# 生成MR标题
opencode_generate_mr_title() {
    local commits=$1
    local branch_name=$2
    
    local prompt="请根据以下 Git 提交记录，生成一个简洁有意义的 MR 标题。要求：
1. 标题应该概括主要变更内容
2. 使用中文
3. 不超过 50 个字符
4. 不需要包含提交数量
5. 可以使用适当的 emoji 图标（如 ✨ 🐛 📝 ♻️ 等）

提交记录：
$commits

请直接返回标题，不要包含其他解释："
    
    local result=$(call_opencode_api "$prompt" 15)
    
    # 清理结果
    if [ ! -z "$result" ]; then
        echo "$result" | head -1 | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//'
    else
        # 备用方案
        if [[ $branch_name =~ ^feature/.* ]]; then
            echo "✨ Feature: ${branch_name#feature/}"
        elif [[ $branch_name =~ ^fix/.* ]]; then
            echo "🐛 Fix: ${branch_name#fix/}"
        elif [[ $branch_name =~ ^hotfix/.* ]]; then
            echo "🚑 Hotfix: ${branch_name#hotfix/}"
        else
            echo "🔀 Update: $branch_name"
        fi
    fi
}

# 生成MR描述
opencode_generate_mr_description() {
    local commits=$1
    local commit_count=$2
    
    local prompt="请根据以下 Git 提交记录，生成一个专业的 MR 描述。要求：
1. 总结主要变更内容和目标
2. 使用中文
3. 结构清晰，重点突出
4. 不要简单罗列提交，而是要概括和总结
5. 描述应该让审查者快速理解这次变更的目的和影响

提交记录：
$commits

请按以下格式返回：
## 📋 变更概述

[在这里写变更的总结和目标]

## 🔧 主要改进

[在这里列出主要的改进点，用简洁的要点形式]"
    
    local result=$(call_opencode_api "$prompt" 30)
    
    if [ ! -z "$result" ]; then
        echo "$result"
        echo ""
        echo "## ✅ 检查清单"
        echo ""
        echo "- [ ] 代码已经过自测"
        echo "- [ ] 相关文档已更新"
        echo "- [ ] 测试用例已添加/更新"
        echo "- [ ] 无明显的性能影响"
        echo "- [ ] 符合代码规范"
    else
        # 备用方案
        echo "## 📋 变更概述"
        echo ""
        echo "本次合并包含 **$commit_count** 个提交，主要变更如下："
        echo ""
        echo "$commits" | while IFS='|' read -r hash subject author date; do
            if [ ! -z "$hash" ]; then
                echo "- $subject"
            fi
        done
        echo ""
        echo "## ✅ 检查清单"
        echo ""
        echo "- [ ] 代码已经过自测"
        echo "- [ ] 相关文档已更新"
        echo "- [ ] 测试用例已添加/更新"
        echo "- [ ] 无明显的性能影响"
        echo "- [ ] 符合代码规范"
    fi
}

# 测试OpenCode服务
test_opencode_service() {
    echo -e "${BLUE}=== 测试 OpenCode 服务 ===${NC}"
    
    # 检查CLI
    if check_opencode_cli; then
        echo -e "${GREEN}✓ OpenCode CLI 已安装${NC}"
    else
        echo -e "${YELLOW}⚠ OpenCode CLI 未安装${NC}"
        echo "安装命令: npm install -g @opencode/cli"
    fi
    
    # 检查配置
    local api_key=$(get_opencode_config "OPENCODE_API_KEY")
    if [ ! -z "$api_key" ]; then
        echo -e "${GREEN}✓ API Key 已配置${NC}"
    else
        echo -e "${RED}❌ API Key 未配置${NC}"
        return 1
    fi
    
    # 测试API调用
    echo -e "${YELLOW}→ 测试API调用...${NC}"
    local test_result=$(call_opencode_api "请回复'OpenCode服务正常'")
    
    if [ ! -z "$test_result" ]; then
        echo -e "${GREEN}✓ API调用成功${NC}"
        echo "响应: $test_result"
        return 0
    else
        echo -e "${RED}❌ API调用失败${NC}"
        return 1
    fi
}

# 主函数
main() {
    case "${1:-help}" in
        "install")
            install_opencode_cli
            ;;
        "config")
            configure_opencode_api
            ;;
        "test")
            test_opencode_service
            ;;
        "review")
            if [ $# -lt 3 ]; then
                echo "用法: $0 review <prompt_file> <additional_prompt>"
                return 1
            fi
            opencode_code_review "$2" "$3"
            ;;
        "mr-title")
            if [ $# -lt 3 ]; then
                echo "用法: $0 mr-title <commits> <branch_name>"
                return 1
            fi
            opencode_generate_mr_title "$2" "$3"
            ;;
        "mr-description")
            if [ $# -lt 3 ]; then
                echo "用法: $0 mr-description <commits> <commit_count>"
                return 1
            fi
            opencode_generate_mr_description "$2" "$3"
            ;;
        "help"|*)
            echo "OpenCode AI 服务集成工具"
            echo ""
            echo "用法: $0 <命令> [参数...]"
            echo ""
            echo "命令:"
            echo "  install                           - 安装 OpenCode CLI"
            echo "  config                            - 配置 OpenCode API"
            echo "  test                              - 测试 OpenCode 服务"
            echo "  review <prompt_file> <prompt>     - 代码审查"
            echo "  mr-title <commits> <branch>       - 生成MR标题"
            echo "  mr-description <commits> <count>  - 生成MR描述"
            echo "  help                              - 显示帮助信息"
            ;;
    esac
}

# 如果直接执行此脚本，运行主函数
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi
