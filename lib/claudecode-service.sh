#!/bin/bash

# ClaudeCode AI Service Integration
# ClaudeCode AI服务集成模块

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 导入配置管理和共享模块
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/ai-config.sh"
source "$SCRIPT_DIR/mr-generator.sh"
source "$SCRIPT_DIR/api-versions.sh"

# ClaudeCode 默认配置
DEFAULT_CLAUDECODE_MODEL="claude-3-sonnet"
DEFAULT_TIMEOUT=30

# 获取ClaudeCode API URL（使用api-versions.sh中的配置）
get_default_claudecode_api_url() {
    get_claudecode_api_url
}

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
    if command -v claude &> /dev/null; then
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
        if npm install -g @anthropic-ai/claude-code; then
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
    local api_url=$(get_claudecode_config "CLAUDECODE_API_URL" "$(get_default_claudecode_api_url)")
    
    if [ -z "$api_key" ]; then
        echo -e "${RED}❌ 未设置 CLAUDECODE_API_KEY${NC}"
        echo "请设置 ClaudeCode API 密钥："
        echo "  方式1: 环境变量 export CLAUDECODE_API_KEY='your_key'"
        echo "  方式2: 配置文件 ./lib/ai-config.sh set CLAUDECODE_API_KEY 'your_key'"
        return 1
    fi
    
    # 配置ClaudeCode CLI
    if check_claudecode_cli; then
        claude config set api_key "$api_key"
        claude config set api_url "$api_url"
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
    local api_url=$(get_claudecode_config "CLAUDECODE_API_URL" "$(get_default_claudecode_api_url)")
    
    if [ -z "$api_key" ]; then
        echo -e "${RED}❌ 未设置 CLAUDECODE_API_KEY${NC}" >&2
        return 1
    fi
    
    # 如果有CLI工具，优先使用CLI
    if check_claudecode_cli; then
        echo "$prompt" | timeout "$timeout" claude chat --model "$model" --yes 2>/dev/null
        return $?
    fi
    
    # 否则使用curl直接调用API
    # 安全地构建JSON，避免特殊字符问题
    local escaped_prompt=$(printf '%s' "$prompt" | python3 -c "import sys, json; print(json.dumps(sys.stdin.read()))")
    local json_payload=$(cat <<EOF
{
    "model": "$model",
    "messages": [
        {
            "role": "user",
            "content": $escaped_prompt
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
        -H "anthropic-version: $(get_anthropic_version)" \
        -d "$json_payload" \
        "$api_url/messages" 2>/dev/null)
    
    if [ $? -eq 0 ] && [ ! -z "$response" ]; then
        # 解析JSON响应，提取生成的文本，增强错误处理
        echo "$response" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    # 检查API错误
    if 'error' in data:
        print('', file=sys.stderr)
        sys.exit(1)
    # 尝试多种Claude响应格式
    if 'content' in data and len(data['content']) > 0:
        if isinstance(data['content'][0], dict) and 'text' in data['content'][0]:
            print(data['content'][0]['text'].strip())
        elif isinstance(data['content'][0], str):
            print(data['content'][0].strip())
    elif 'message' in data and 'content' in data['message']:
        print(data['message']['content'].strip())
    elif 'text' in data:
        print(data['text'].strip())
    else:
        print('', file=sys.stderr)
        sys.exit(1)
except json.JSONDecodeError:
    print('', file=sys.stderr)
    sys.exit(1)
except Exception as e:
    print('', file=sys.stderr)
    sys.exit(1)
" 2>/dev/null
        return $?
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

    # 验证提交格式
    if ! validate_commits_format "$commits"; then
        generate_fallback_mr_title "$branch_name"
        return
    fi

    # 准备提交列表
    local commit_list=$(prepare_commit_list "$commits")
    local prompt=$(get_mr_title_prompt "$commit_list")

    local result=$(call_claudecode_api "$prompt" 15)

    # 清理和验证结果
    if [ ! -z "$result" ]; then
        local cleaned_title=$(clean_and_validate_title "$result")
        if [ $? -eq 0 ]; then
            echo "$cleaned_title"
            return
        fi
    fi

    # 使用备用方案
    generate_fallback_mr_title "$branch_name"
}

# 生成MR描述
claudecode_generate_mr_description() {
    local commits=$1
    local commit_count=$2

    # 验证提交格式
    if ! validate_commits_format "$commits"; then
        generate_fallback_mr_description "$commits" "$commit_count"
        return
    fi

    # 准备提交列表
    local commit_list=$(prepare_commit_list "$commits")
    local prompt=$(get_mr_description_prompt "$commit_list")

    local result=$(call_claudecode_api "$prompt" 30)

    if [ ! -z "$result" ]; then
        add_checklist_to_description "$result"
    else
        # 使用备用方案
        generate_fallback_mr_description "$commits" "$commit_count"
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
        echo "安装命令: npm install -g @anthropic-ai/claude-code"
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
