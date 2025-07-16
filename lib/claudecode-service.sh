#!/bin/bash

# ClaudeCode AI Service Integration
# ClaudeCode AI服务集成模块

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 导入配置管理
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/ai-config.sh"

# ClaudeCode 默认配置
DEFAULT_CLAUDECODE_API_URL="https://api.claudecode.com/v1"
DEFAULT_CLAUDECODE_MODEL="claude-3-sonnet"
DEFAULT_TIMEOUT=30

# 获取ClaudeCode配置
get_claudecode_config() {
    local config_key=$1
    local default_value=$2
    
    local value=$(get_config_value "$config_key")
    if [ -z "$value" ]; then
        value="$default_value"
    fi
    
    echo "$value"
}

# 检查ClaudeCode CLI是否可用
check_claudecode_cli() {
    if command -v claudecode &> /dev/null; then
        return 0
    else
        return 1
    fi
}

# 安装ClaudeCode CLI
install_claudecode_cli() {
    echo -e "${YELLOW}→ 安装 ClaudeCode CLI...${NC}"
    
    if check_claudecode_cli; then
        echo -e "${GREEN}✓ ClaudeCode CLI 已安装${NC}"
        return 0
    fi
    
    # 尝试通过npm安装
    if command -v npm &> /dev/null; then
        if npm install -g @claudecode/cli; then
            echo -e "${GREEN}✓ ClaudeCode CLI 安装成功${NC}"
            return 0
        else
            echo -e "${RED}✗ ClaudeCode CLI 安装失败${NC}"
            return 1
        fi
    else
        echo -e "${RED}✗ 需要安装 Node.js 和 npm${NC}"
        return 1
    fi
}

# 配置ClaudeCode API
configure_claudecode_api() {
    local api_key=$(get_claudecode_config "CLAUDECODE_API_KEY")
    local api_url=$(get_claudecode_config "CLAUDECODE_API_URL" "$DEFAULT_CLAUDECODE_API_URL")
    
    if [ -z "$api_key" ]; then
        echo -e "${RED}❌ 未设置 CLAUDECODE_API_KEY${NC}"
        echo "请设置 ClaudeCode API 密钥："
        echo "  方式1: 环境变量 export CLAUDECODE_API_KEY='your_key'"
        echo "  方式2: 配置文件 ./lib/ai-config.sh set CLAUDECODE_API_KEY 'your_key'"
        return 1
    fi
    
    # 配置ClaudeCode CLI
    if check_claudecode_cli; then
        claudecode config set api_key "$api_key"
        claudecode config set api_url "$api_url"
        echo -e "${GREEN}✓ ClaudeCode API 配置完成${NC}"
        return 0
    else
        echo -e "${RED}❌ ClaudeCode CLI 未安装${NC}"
        return 1
    fi
}

# 调用ClaudeCode API进行文本生成
call_claudecode_api() {
    local prompt=$1
    local timeout=${2:-$DEFAULT_TIMEOUT}
    local model=$(get_claudecode_config "CLAUDECODE_MODEL" "$DEFAULT_CLAUDECODE_MODEL")
    local api_key=$(get_claudecode_config "CLAUDECODE_API_KEY")
    local api_url=$(get_claudecode_config "CLAUDECODE_API_URL" "$DEFAULT_CLAUDECODE_API_URL")
    
    if [ -z "$api_key" ]; then
        echo -e "${RED}❌ 未设置 CLAUDECODE_API_KEY${NC}" >&2
        return 1
    fi
    
    # 如果有CLI工具，优先使用CLI
    if check_claudecode_cli; then
        echo "$prompt" | timeout "$timeout" claudecode chat --model "$model" --yes 2>/dev/null
        return $?
    fi
    
    # 否则使用curl直接调用API
    local json_payload=$(cat <<EOF
{
    "model": "$model",
    "messages": [
        {
            "role": "user",
            "content": "$prompt"
        }
    ],
    "max_tokens": 2048,
    "temperature": 0.7
}
EOF
)
    
    local response=$(timeout "$timeout" curl -s \
        -H "Authorization: Bearer $api_key" \
        -H "Content-Type: application/json" \
        -H "anthropic-version: 2023-06-01" \
        -d "$json_payload" \
        "$api_url/messages" 2>/dev/null)
    
    if [ $? -eq 0 ] && [ ! -z "$response" ]; then
        # 解析JSON响应，提取生成的文本
        echo "$response" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    if 'content' in data and len(data['content']) > 0:
        print(data['content'][0]['text'].strip())
    elif 'message' in data and 'content' in data['message']:
        print(data['message']['content'].strip())
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

# ClaudeCode代码审查
claudecode_code_review() {
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
    
    # 调用ClaudeCode API
    call_claudecode_api "$full_prompt"
}

# 生成MR标题
claudecode_generate_mr_title() {
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
    
    local result=$(call_claudecode_api "$prompt" 15)
    
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
claudecode_generate_mr_description() {
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
    
    local result=$(call_claudecode_api "$prompt" 30)
    
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

# 测试ClaudeCode服务
test_claudecode_service() {
    echo -e "${BLUE}=== 测试 ClaudeCode 服务 ===${NC}"
    
    # 检查CLI
    if check_claudecode_cli; then
        echo -e "${GREEN}✓ ClaudeCode CLI 已安装${NC}"
    else
        echo -e "${YELLOW}⚠ ClaudeCode CLI 未安装${NC}"
        echo "安装命令: npm install -g @claudecode/cli"
    fi
    
    # 检查配置
    local api_key=$(get_claudecode_config "CLAUDECODE_API_KEY")
    if [ ! -z "$api_key" ]; then
        echo -e "${GREEN}✓ API Key 已配置${NC}"
    else
        echo -e "${RED}❌ API Key 未配置${NC}"
        return 1
    fi
    
    # 测试API调用
    echo -e "${YELLOW}→ 测试API调用...${NC}"
    local test_result=$(call_claudecode_api "请回复'ClaudeCode服务正常'")
    
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
            install_claudecode_cli
            ;;
        "config")
            configure_claudecode_api
            ;;
        "test")
            test_claudecode_service
            ;;
        "review")
            if [ $# -lt 3 ]; then
                echo "用法: $0 review <prompt_file> <additional_prompt>"
                return 1
            fi
            claudecode_code_review "$2" "$3"
            ;;
        "mr-title")
            if [ $# -lt 3 ]; then
                echo "用法: $0 mr-title <commits> <branch_name>"
                return 1
            fi
            claudecode_generate_mr_title "$2" "$3"
            ;;
        "mr-description")
            if [ $# -lt 3 ]; then
                echo "用法: $0 mr-description <commits> <commit_count>"
                return 1
            fi
            claudecode_generate_mr_description "$2" "$3"
            ;;
        "help"|*)
            echo "ClaudeCode AI 服务集成工具"
            echo ""
            echo "用法: $0 <命令> [参数...]"
            echo ""
            echo "命令:"
            echo "  install                           - 安装 ClaudeCode CLI"
            echo "  config                            - 配置 ClaudeCode API"
            echo "  test                              - 测试 ClaudeCode 服务"
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
