#!/bin/bash

# AI Service Manager - 多AI服务抽象层
# 支持 Gemini、OpenCode、ClaudeCode 等多种AI服务

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 默认配置
DEFAULT_AI_SERVICE="gemini"
DEFAULT_TIMEOUT=30

# 导入服务模块
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/ai-config.sh"
source "$SCRIPT_DIR/opencode-service.sh"
source "$SCRIPT_DIR/claudecode-service.sh"

# 获取AI服务配置
get_ai_service() {
    # 优先级：环境变量 > 项目配置 > 全局配置 > 默认值
    local service=""
    
    # 1. 检查环境变量
    if [ ! -z "$AI_SERVICE" ]; then
        service="$AI_SERVICE"
    # 2. 检查项目配置文件
    elif [ -f ".ai-config" ]; then
        service=$(grep "^AI_SERVICE=" .ai-config 2>/dev/null | cut -d'=' -f2)
    # 3. 检查全局配置文件
    elif [ -f "$HOME/.codereview-cli/ai-config" ]; then
        service=$(grep "^AI_SERVICE=" "$HOME/.codereview-cli/ai-config" 2>/dev/null | cut -d'=' -f2)
    fi
    
    # 4. 使用默认值
    if [ -z "$service" ]; then
        service="$DEFAULT_AI_SERVICE"
    fi
    
    echo "$service"
}

# 检查AI服务是否可用
check_ai_service_available() {
    local service=$1
    
    case "$service" in
        "gemini")
            command -v gemini &> /dev/null
            ;;
        "opencode")
            command -v opencode &> /dev/null
            ;;
        "claudecode")
            command -v claudecode &> /dev/null
            ;;
        *)
            echo -e "${RED}❌ 不支持的AI服务: $service${NC}" >&2
            return 1
            ;;
    esac
}

# 获取AI服务安装命令
get_install_command() {
    local service=$1
    
    case "$service" in
        "gemini")
            echo "npm install -g @google/gemini-cli"
            ;;
        "opencode")
            echo "npm install -g @opencode/cli"
            ;;
        "claudecode")
            echo "npm install -g @claudecode/cli"
            ;;
        *)
            echo "未知服务"
            ;;
    esac
}

# 获取AI服务配置命令
get_config_command() {
    local service=$1
    
    case "$service" in
        "gemini")
            echo "gemini config"
            ;;
        "opencode")
            echo "opencode config"
            ;;
        "claudecode")
            echo "claudecode config"
            ;;
        *)
            echo "未知服务"
            ;;
    esac
}

# 调用AI服务进行代码审查
call_ai_for_review() {
    local service=$1
    local prompt_file=$2
    local additional_prompt=$3

    if [ ! -f "$prompt_file" ]; then
        echo -e "${RED}❌ 提示词文件不存在: $prompt_file${NC}" >&2
        return 1
    fi

    case "$service" in
        "gemini")
            cat "$prompt_file" | gemini -p "$additional_prompt" -y
            ;;
        "opencode")
            opencode_code_review "$prompt_file" "$additional_prompt"
            ;;
        "claudecode")
            claudecode_code_review "$prompt_file" "$additional_prompt"
            ;;
        *)
            echo -e "${RED}❌ 不支持的AI服务: $service${NC}" >&2
            return 1
            ;;
    esac
}

# 调用AI服务生成文本
call_ai_for_generation() {
    local service=$1
    local prompt=$2
    local timeout=${3:-$DEFAULT_TIMEOUT}

    case "$service" in
        "gemini")
            echo "$prompt" | timeout "$timeout" gemini -y 2>/dev/null
            ;;
        "opencode")
            call_opencode_api "$prompt" "$timeout"
            ;;
        "claudecode")
            call_claudecode_api "$prompt" "$timeout"
            ;;
        *)
            echo -e "${RED}❌ 不支持的AI服务: $service${NC}" >&2
            return 1
            ;;
    esac
}

# 生成备用响应
generate_fallback_response() {
    local type=$1
    local context=$2
    
    case "$type" in
        "mr_title")
            local branch_name=$context
            if [[ $branch_name =~ ^feature/.* ]]; then
                echo "✨ Feature: ${branch_name#feature/}"
            elif [[ $branch_name =~ ^fix/.* ]]; then
                echo "🐛 Fix: ${branch_name#fix/}"
            elif [[ $branch_name =~ ^hotfix/.* ]]; then
                echo "🚑 Hotfix: ${branch_name#hotfix/}"
            else
                echo "🔀 Update: $branch_name"
            fi
            ;;
        "mr_description")
            local commit_count=$context
            echo "## 📋 变更概述

本次合并包含 **$commit_count** 个提交。

## ✅ 检查清单

- [ ] 代码已经过自测
- [ ] 相关文档已更新
- [ ] 测试用例已添加/更新
- [ ] 无明显的性能影响
- [ ] 符合代码规范"
            ;;
        *)
            echo "AI服务不可用，使用备用方案"
            ;;
    esac
}

# 智能调用AI服务（带备用方案）
smart_ai_call() {
    local service=$1
    local type=$2
    local prompt=$3
    local fallback_context=$4
    
    # 检查服务是否可用
    if ! check_ai_service_available "$service"; then
        echo -e "${YELLOW}⚠ AI服务 $service 不可用，使用备用方案${NC}" >&2
        generate_fallback_response "$type" "$fallback_context"
        return 0
    fi
    
    # 尝试调用AI服务
    local result=$(call_ai_for_generation "$service" "$prompt")
    local exit_code=$?
    
    # 检查调用是否成功
    if [ $exit_code -ne 0 ] || [ -z "$result" ]; then
        echo -e "${YELLOW}⚠ AI服务调用失败，使用备用方案${NC}" >&2
        generate_fallback_response "$type" "$fallback_context"
        return 0
    fi
    
    # 返回AI生成的结果
    echo "$result"
}

# 显示AI服务状态
show_ai_service_status() {
    local current_service=$(get_ai_service)
    
    echo -e "${BLUE}=== AI服务状态 ===${NC}"
    echo "当前服务: $current_service"
    echo ""
    
    # 检查各个服务的可用性
    local services=("gemini" "opencode" "claudecode")
    for service in "${services[@]}"; do
        if check_ai_service_available "$service"; then
            echo -e "  ${GREEN}✓ $service${NC} - 已安装"
        else
            echo -e "  ${RED}✗ $service${NC} - 未安装"
            echo -e "    安装命令: $(get_install_command "$service")"
        fi
    done
}

# 设置AI服务
set_ai_service() {
    local service=$1
    local scope=${2:-"project"}  # project 或 global
    
    # 验证服务名称
    case "$service" in
        "gemini"|"opencode"|"claudecode")
            ;;
        *)
            echo -e "${RED}❌ 不支持的AI服务: $service${NC}"
            echo "支持的服务: gemini, opencode, claudecode"
            return 1
            ;;
    esac
    
    # 设置配置
    if [ "$scope" = "global" ]; then
        mkdir -p "$HOME/.codereview-cli"
        echo "AI_SERVICE=$service" > "$HOME/.codereview-cli/ai-config"
        echo -e "${GREEN}✓ 全局AI服务设置为: $service${NC}"
    else
        echo "AI_SERVICE=$service" > ".ai-config"
        echo -e "${GREEN}✓ 项目AI服务设置为: $service${NC}"
    fi
}

# 主函数 - 用于测试
main() {
    case "${1:-status}" in
        "status")
            show_ai_service_status
            ;;
        "set")
            set_ai_service "$2" "$3"
            ;;
        "test")
            local service=$(get_ai_service)
            echo "测试AI服务: $service"
            smart_ai_call "$service" "mr_title" "生成一个测试标题" "test-branch"
            ;;
        *)
            echo "用法: $0 {status|set|test}"
            echo "  status - 显示AI服务状态"
            echo "  set <service> [global|project] - 设置AI服务"
            echo "  test - 测试当前AI服务"
            ;;
    esac
}

# 如果直接执行此脚本，运行主函数
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi
