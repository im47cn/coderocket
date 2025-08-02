#!/bin/bash

# AI Service Manager - 多AI服务抽象层
# 支持 Gemini、ClaudeCode 等多种AI服务

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
source "$SCRIPT_DIR/claudecode-service.sh"
source "$SCRIPT_DIR/ai-error-classifier.sh" 2>/dev/null

# 智能切换配置
AI_AUTO_SWITCH=${AI_AUTO_SWITCH:-"true"}
AI_MAX_RETRIES=${AI_MAX_RETRIES:-3}
AI_RETRY_DELAY=${AI_RETRY_DELAY:-1}

# 获取AI服务配置
#
# 功能: 按优先级获取当前配置的AI服务
# 参数: 无
# 返回: AI服务名称 (gemini/claudecode)
# 复杂度: O(1) - 常数时间查找
# 依赖: grep, cut命令
# 调用者: smart_ai_call(), show_ai_service_status(), main()
# 优先级: 环境变量 > 项目配置 > 全局配置 > 默认值
# 示例:
#   service=$(get_ai_service)  # 返回 "gemini"
get_ai_service() {
    # 优先级：环境变量 > 项目配置 > 全局配置 > 默认值
    local service=""

    # 1. 检查环境变量 (最高优先级)
    if [ ! -z "$AI_SERVICE" ]; then
        service="$AI_SERVICE"
    # 2. 检查项目配置文件
    elif [ -f ".ai-config" ]; then
        service=$(grep "^AI_SERVICE=" .ai-config 2>/dev/null | sed 's/^AI_SERVICE=//')
    # 3. 检查全局配置文件
    elif [ -f "$HOME/.coderocket/ai-config" ]; then
        service=$(grep "^AI_SERVICE=" "$HOME/.coderocket/ai-config" 2>/dev/null | sed 's/^AI_SERVICE=//')
    fi

    # 4. 使用默认值 (最低优先级)
    if [ -z "$service" ]; then
        service="$DEFAULT_AI_SERVICE"
    fi

    echo "$service"
}

# 检查AI服务是否可用
#
# 功能: 检查指定AI服务的CLI工具是否已安装
# 参数:
#   $1 - service: AI服务名称 (必需)
#        支持: "gemini", "claudecode"
# 返回: 0=服务可用, 1=服务不可用或不支持
# 复杂度: O(1) - 常数时间命令检查
# 依赖: command命令
# 调用者: smart_ai_call(), show_ai_service_status()
# 检查方式: 使用command -v检查CLI工具是否在PATH中
# 示例:
#   if check_ai_service_available "gemini"; then
#       echo "Gemini可用"
#   fi
check_ai_service_available() {
    local service=$1

    case "$service" in
        "gemini")
            command -v gemini &> /dev/null  # 检查gemini命令是否存在
            ;;
        "claudecode")
            command -v claude &> /dev/null  # 检查claude命令是否存在
            ;;
        *)
            echo -e "${RED}❌ 不支持的AI服务: $service${NC}" >&2
            return 1
            ;;
    esac
}

# 获取AI服务安装命令
#
# 功能: 获取指定AI服务的安装命令字符串
# 参数:
#   $1 - service: AI服务名称 (必需)
#        支持: "gemini", "claudecode"
# 返回: 安装命令字符串，未知服务返回"未知服务"
# 复杂度: O(1) - 常数时间查找
# 依赖: 无
# 调用者: show_ai_service_status()
# 用途: 为用户提供安装指导
# 示例:
#   cmd=$(get_install_command "gemini")
#   echo "安装命令: $cmd"
get_install_command() {
    local service=$1

    case "$service" in
        "gemini")
            echo "npm install -g @google/gemini-cli"  # Google Gemini CLI
            ;;
        "claudecode")
            echo "npm install -g @anthropic-ai/claude-code"  # ClaudeCode CLI
            ;;
        *)
            echo "未知服务"  # 不支持的服务
            ;;
    esac
}

# 获取AI服务配置命令
#
# 功能: 获取指定AI服务的配置命令字符串
# 参数:
#   $1 - service: AI服务名称 (必需)
#        支持: "gemini", "claudecode"
# 返回: 配置命令字符串，未知服务返回"未知服务"
# 复杂度: O(1) - 常数时间查找
# 依赖: 无
# 调用者: 安装脚本和用户指导
# 用途: 为用户提供配置指导
# 示例:
#   cmd=$(get_config_command "gemini")
#   echo "配置命令: $cmd"
get_config_command() {
    local service=$1

    case "$service" in
        "gemini")
            echo "gemini config"  # Gemini配置命令
            ;;

        "claudecode")
            echo "claude config"  # ClaudeCode配置命令
            ;;
        *)
            echo "未知服务"  # 不支持的服务
            ;;
    esac
}

# 调用AI服务进行代码审查
#
# 功能: 使用指定AI服务进行代码审查
# 参数:
#   $1 - service: AI服务名称 (必需)
#   $2 - prompt_file: 提示词文件路径 (必需)
#   $3 - additional_prompt: 附加提示词 (必需)
# 返回: 0=成功, 1=文件不存在或服务不支持
# 复杂度: O(n) - n为提示词文件大小
# 依赖: cat, gemini命令, claudecode_code_review()
# 调用者: Git hooks (post-commit)
# 流程: 验证文件 -> 根据服务类型调用相应函数
# 示例:
#   call_ai_for_review "gemini" "prompt.md" "请审查代码"
call_ai_for_review() {
    local service=$1
    local prompt_file=$2
    local additional_prompt=$3

    # 验证提示词文件是否存在
    if [ ! -f "$prompt_file" ]; then
        echo -e "${RED}❌ 提示词文件不存在: $prompt_file${NC}" >&2
        return 1
    fi

    case "$service" in
        "gemini")
            # 使用管道将文件内容传递给gemini CLI
            cat "$prompt_file" | gemini -p "$additional_prompt" -y
            ;;
        "claudecode")
            # 调用ClaudeCode服务的代码审查函数
            claudecode_code_review "$prompt_file" "$additional_prompt"
            ;;
        *)
            echo -e "${RED}❌ 不支持的AI服务: $service${NC}" >&2
            return 1
            ;;
    esac
}

# 智能代码审查调用函数（多服务自动切换）
#
# 功能: 智能调用AI服务进行代码审查，支持自动错误处理和服务切换
# 参数:
#   $1 - service: 主要AI服务名称 (必需)
#   $2 - prompt_file: 提示词文件路径 (必需)
#   $3 - additional_prompt: 附加提示词 (必需)
# 返回: 0=成功, 1=失败
# 特性: 自动错误分类、智能服务切换、用户友好提示
intelligent_ai_review() {
    local primary_service=$1
    local prompt_file=$2
    local additional_prompt=$3

    # 验证提示词文件是否存在
    if [ ! -f "$prompt_file" ]; then
        echo -e "${RED}❌ 提示词文件不存在: $prompt_file${NC}" >&2
        return 1
    fi

    # 检查是否启用自动切换
    if [ "$AI_AUTO_SWITCH" != "true" ]; then
        # 禁用自动切换，使用原有逻辑
        return $(call_ai_for_review "$primary_service" "$prompt_file" "$additional_prompt")
    fi

    # 获取可用服务列表
    local available_services=($(get_available_services "$primary_service"))
    local tried_services=()

    echo -e "${BLUE}🔍 开始AI代码审查 (主服务: $primary_service)${NC}" >&2

    # 遍历可用服务
    for service in "${available_services[@]}"; do
        # 跳过已尝试的服务
        if [[ " ${tried_services[@]} " =~ " ${service} " ]]; then
            continue
        fi

        tried_services+=("$service")

        echo -e "${YELLOW}→ 使用 $service 进行代码审查...${NC}" >&2

        # 调用代码审查
        local result=""
        local exit_code=0

        case "$service" in
            "gemini")
                result=$(cat "$prompt_file" | gemini -p "$additional_prompt" -y 2>&1)
                exit_code=$?
                ;;
            "claudecode")
                result=$(claudecode_code_review "$prompt_file" "$additional_prompt" 2>&1)
                exit_code=$?
                ;;
            *)
                echo -e "${RED}❌ 不支持的AI服务: $service${NC}" >&2
                continue
                ;;
        esac

        # 检查调用结果
        if [ $exit_code -eq 0 ] && [ -n "$result" ]; then
            echo -e "${GREEN}✅ $service 代码审查完成${NC}" >&2
            echo "$result"
            return 0
        fi

        # 分析错误并决定策略
        local error_type=$(classify_ai_error "$service" "$exit_code" "$result")
        local error_desc=$(get_error_description "$error_type" "$service")
        local strategy=$(get_error_strategy "$error_type")

        echo -e "${YELLOW}$error_desc${NC}" >&2

        # 根据策略处理错误
        case "$strategy" in
            "switch_immediately"|"skip_service")
                echo -e "${YELLOW}→ 切换到下一个服务${NC}" >&2
                continue
                ;;
            "retry_then_switch")
                echo -e "${YELLOW}→ 重试 $service 服务...${NC}" >&2
                sleep "$AI_RETRY_DELAY"

                # 重试一次
                case "$service" in
                    "gemini")
                        result=$(cat "$prompt_file" | gemini -p "$additional_prompt" -y 2>&1)
                        exit_code=$?
                        ;;
                    "claudecode")
                        result=$(claudecode_code_review "$prompt_file" "$additional_prompt" 2>&1)
                        exit_code=$?
                        ;;
                esac

                if [ $exit_code -eq 0 ] && [ -n "$result" ]; then
                    echo -e "${GREEN}✅ $service 代码审查重试成功${NC}" >&2
                    echo "$result"
                    return 0
                else
                    echo -e "${YELLOW}→ $service 重试失败，切换到下一个服务${NC}" >&2
                    continue
                fi
                ;;
            *)
                continue
                ;;
        esac
    done

    # 所有服务都失败
    echo -e "${RED}❌ 所有AI服务都不可用，代码审查失败${NC}" >&2
    echo -e "${YELLOW}💡 建议检查AI服务配置或网络连接${NC}" >&2
    return 1
}

# 调用AI服务生成文本
#
# 功能: 使用指定AI服务生成文本内容
# 参数:
#   $1 - service: AI服务名称 (必需)
#   $2 - prompt: 提示词内容 (必需)
#   $3 - timeout: 超时时间，秒 (可选, 默认: DEFAULT_TIMEOUT)
# 返回: 0=成功, 1=服务不支持
# 输出: 生成的文本内容到stdout
# 复杂度: O(n) - n为提示词长度，实际受AI服务响应时间影响
# 依赖: echo, timeout, gemini命令, call_claudecode_api()
# 调用者: smart_ai_call()
# 超时处理: 使用timeout命令防止长时间等待
# 示例:
#   result=$(call_ai_for_generation "gemini" "生成标题" 30)
call_ai_for_generation() {
    local service=$1
    local prompt=$2
    local timeout=${3:-$DEFAULT_TIMEOUT}

    case "$service" in
        "gemini")
            # 使用timeout防止长时间等待，重定向错误输出
            echo "$prompt" | timeout "$timeout" gemini -y 2>/dev/null
            ;;
        "claudecode")
            # 调用ClaudeCode API函数
            call_claudecode_api "$prompt" "$timeout"
            ;;
        *)
            echo -e "${RED}❌ 不支持的AI服务: $service${NC}" >&2
            return 1
            ;;
    esac
}

# 增强版AI调用函数（带详细错误处理）
#
# 功能: 调用AI服务并捕获详细错误信息
# 参数:
#   $1 - service: AI服务名称 (必需)
#   $2 - prompt: 提示词内容 (必需)
#   $3 - timeout: 超时时间，秒 (可选, 默认: DEFAULT_TIMEOUT)
# 返回: 0=成功, 非0=失败
# 输出: 成功时输出结果到stdout，失败时错误信息到stderr
# 全局变量: 设置错误分类器的全局变量
call_ai_with_error_handling() {
    local service=$1
    local prompt=$2
    local timeout=${3:-$DEFAULT_TIMEOUT}

    # 创建临时文件存储输出和错误
    local temp_stdout=$(mktemp)
    local temp_stderr=$(mktemp)
    local exit_code=0

    # 确保临时文件在函数退出时被清理
    trap "rm -f '$temp_stdout' '$temp_stderr'" RETURN

    case "$service" in
        "gemini")
            # 捕获stdout和stderr
            echo "$prompt" | timeout "$timeout" gemini -y >"$temp_stdout" 2>"$temp_stderr"
            exit_code=$?
            ;;
        "claudecode")
            # 调用ClaudeCode API函数，捕获输出
            call_claudecode_api "$prompt" "$timeout" >"$temp_stdout" 2>"$temp_stderr"
            exit_code=$?
            ;;
        *)
            echo "不支持的AI服务: $service" >"$temp_stderr"
            exit_code=1
            ;;
    esac

    # 读取输出内容
    local stdout_content=$(cat "$temp_stdout" 2>/dev/null)
    local stderr_content=$(cat "$temp_stderr" 2>/dev/null)

    # 使用错误分类器分析错误
    if [ -n "$(command -v classify_ai_error)" ]; then
        classify_ai_error "$service" "$exit_code" "$stderr_content" "$stdout_content" >/dev/null
    fi

    # 输出结果
    if [ $exit_code -eq 0 ] && [ -n "$stdout_content" ]; then
        echo "$stdout_content"
        return 0
    else
        # 输出错误信息到stderr
        [ -n "$stderr_content" ] && echo "$stderr_content" >&2
        return $exit_code
    fi
}

# 获取可用AI服务列表
#
# 功能: 获取当前可用的AI服务列表，按优先级排序
# 参数:
#   $1 - primary_service: 主要服务名称 (可选)
# 返回: 可用服务列表，空格分隔
# 优先级: 主要服务 > 其他已安装服务 > 所有支持的服务
get_available_services() {
    local primary_service=${1:-$(get_ai_service)}
    local available_services=()
    local all_services=("gemini" "claudecode")

    # 首先添加主要服务（如果可用）
    if check_ai_service_available "$primary_service"; then
        available_services+=("$primary_service")
    fi

    # 添加其他可用服务
    for service in "${all_services[@]}"; do
        if [ "$service" != "$primary_service" ] && check_ai_service_available "$service"; then
            available_services+=("$service")
        fi
    done

    # 如果没有可用服务，返回所有支持的服务（让后续逻辑处理）
    if [ ${#available_services[@]} -eq 0 ]; then
        available_services=("${all_services[@]}")
    fi

    echo "${available_services[@]}"
}

# 获取服务优先级配置
#
# 功能: 从配置文件读取服务优先级设置
# 返回: 服务优先级列表，空格分隔
get_service_priority() {
    local priority_config=""

    # 检查环境变量
    if [ -n "$AI_SERVICE_PRIORITY" ]; then
        priority_config="$AI_SERVICE_PRIORITY"
    # 检查项目配置
    elif [ -f ".ai-config" ]; then
        priority_config=$(grep "^AI_SERVICE_PRIORITY=" .ai-config 2>/dev/null | cut -d'=' -f2)
    # 检查全局配置
    elif [ -f "$HOME/.coderocket/ai-config" ]; then
        priority_config=$(grep "^AI_SERVICE_PRIORITY=" "$HOME/.coderocket/ai-config" 2>/dev/null | cut -d'=' -f2)
    fi

    # 如果有配置，返回配置的优先级
    if [ -n "$priority_config" ]; then
        echo "$priority_config"
    else
        # 默认优先级
        echo "gemini claudecode"
    fi
}

# 智能AI调用函数（多服务自动切换）
#
# 功能: 智能调用AI服务，支持自动错误处理和服务切换
# 参数:
#   $1 - service: 主要AI服务名称 (必需)
#   $2 - type: 响应类型 (必需) - 用于备用方案
#   $3 - prompt: 提示词内容 (必需)
#   $4 - fallback_context: 备用方案上下文 (必需)
# 返回: 0=总是成功 (AI成功或备用方案)
# 输出: AI生成的内容或备用方案内容到stdout
# 特性: 自动错误分类、智能服务切换、用户友好提示
intelligent_ai_call() {
    local primary_service=$1
    local type=$2
    local prompt=$3
    local fallback_context=$4

    # 检查是否启用自动切换
    if [ "$AI_AUTO_SWITCH" != "true" ]; then
        # 禁用自动切换，使用原有逻辑
        smart_ai_call "$primary_service" "$type" "$prompt" "$fallback_context"; return $?
    fi

    # 获取可用服务列表
    local available_services=($(get_available_services "$primary_service"))
    local tried_services=()
    local success=false

    echo -e "${BLUE}🤖 开始AI服务调用 (主服务: $primary_service)${NC}" >&2

    # 遍历可用服务
    for service in "${available_services[@]}"; do
        # 跳过已尝试的服务
        if [[ " ${tried_services[@]} " =~ " ${service} " ]]; then
            continue
        fi

        tried_services+=("$service")

        echo -e "${YELLOW}→ 尝试使用 $service 服务...${NC}" >&2

        # 调用AI服务
        local result=$(call_ai_with_error_handling "$service" "$prompt")
        local exit_code=$?

        # 检查调用结果
        if [ $exit_code -eq 0 ] && [ -n "$result" ]; then
            echo -e "${GREEN}✅ $service 服务调用成功${NC}" >&2
            echo "$result"
            return 0
        fi

        # 获取错误信息和处理策略
        local error_type=$(get_last_error_type)
        local error_desc=$(get_error_description "$error_type" "$service")
        local strategy=$(get_error_strategy "$error_type")

        echo -e "${YELLOW}$error_desc${NC}" >&2

        # 根据策略处理错误
        case "$strategy" in
            "continue")
                # 成功，不应该到这里
                echo "$result"
                return 0
                ;;
            "switch_immediately")
                echo -e "${YELLOW}→ 立即切换到下一个服务${NC}" >&2
                continue
                ;;
            "skip_service")
                echo -e "${YELLOW}→ 跳过 $service 服务${NC}" >&2
                continue
                ;;
            "retry_then_switch")
                echo -e "${YELLOW}→ 重试 $service 服务...${NC}" >&2
                sleep "$AI_RETRY_DELAY"

                # 重试一次
                result=$(call_ai_with_error_handling "$service" "$prompt")
                exit_code=$?

                if [ $exit_code -eq 0 ] && [ -n "$result" ]; then
                    echo -e "${GREEN}✅ $service 服务重试成功${NC}" >&2
                    echo "$result"
                    return 0
                else
                    echo -e "${YELLOW}→ $service 服务重试失败，切换到下一个服务${NC}" >&2
                    continue
                fi
                ;;
            *)
                echo -e "${YELLOW}→ 切换到下一个服务${NC}" >&2
                continue
                ;;
        esac
    done

    # 所有服务都失败，使用备用方案
    echo -e "${RED}❌ 所有AI服务都不可用，使用备用方案${NC}" >&2
    generate_fallback_response "$type" "$fallback_context"
    return 0
}

# 生成备用响应
#
# 功能: 当AI服务不可用时生成备用响应内容
# 参数:
#   $1 - type: 响应类型 (必需)
#        支持: "mr_title", "mr_description"
#   $2 - context: 上下文信息 (必需)
#        - mr_title: 分支名称
#        - mr_description: 提交数量
# 返回: 无 (直接输出到stdout)
# 复杂度: O(1) - 常数时间模板生成
# 依赖: echo命令, 正则表达式匹配
# 调用者: smart_ai_call()
# 模式匹配: 使用bash正则表达式识别分支类型
# 示例:
#   generate_fallback_response "mr_title" "feature/new-ui"
#   generate_fallback_response "mr_description" "5"
generate_fallback_response() {
    local type=$1
    local context=$2

    case "$type" in
        "mr_title")
            local branch_name=$context
            # 根据分支命名规范生成相应的标题
            if [[ $branch_name =~ ^feature/.* ]]; then
                echo "✨ Feature: ${branch_name#feature/}"  # 移除feature/前缀
            elif [[ $branch_name =~ ^fix/.* ]]; then
                echo "🐛 Fix: ${branch_name#fix/}"  # 移除fix/前缀
            elif [[ $branch_name =~ ^hotfix/.* ]]; then
                echo "🚑 Hotfix: ${branch_name#hotfix/}"  # 移除hotfix/前缀
            else
                echo "🔀 Update: $branch_name"  # 通用更新
            fi
            ;;
        "mr_description")
            local commit_count=$context
            # 生成标准的MR描述模板
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
            echo "AI服务不可用，使用备用方案"  # 默认备用消息
            ;;
    esac
}

# 智能调用AI服务（带备用方案）
#
# 功能: 智能调用AI服务，失败时自动使用备用方案
# 参数:
#   $1 - service: AI服务名称 (必需)
#   $2 - type: 响应类型 (必需) - 用于备用方案
#   $3 - prompt: 提示词内容 (必需)
#   $4 - fallback_context: 备用方案上下文 (必需)
# 返回: 0=总是成功 (AI成功或备用方案)
# 输出: AI生成的内容或备用方案内容到stdout
# 复杂度: O(n) - n为提示词长度，受AI服务响应时间影响
# 依赖: check_ai_service_available(), call_ai_for_generation(), generate_fallback_response()
# 调用者: Git hooks (pre-push)
# 容错机制: 服务不可用 -> 备用方案, 调用失败 -> 备用方案, 结果为空 -> 备用方案
# 示例:
#   result=$(smart_ai_call "gemini" "mr_title" "生成标题" "feature/ui")
smart_ai_call() {
    local service=$1
    local type=$2
    local prompt=$3
    local fallback_context=$4

    # 使用新的智能调用机制（向后兼容）
    intelligent_ai_call "$service" "$type" "$prompt" "$fallback_context"
}

# 显示AI服务状态
#
# 功能: 显示当前AI服务配置和所有服务的安装状态
# 参数: 无
# 返回: 无
# 复杂度: O(n) - n为支持的服务数量
# 依赖: get_ai_service(), check_ai_service_available(), get_install_command()
# 调用者: main()
# 输出格式: 彩色状态报告，包含当前服务和安装状态
# 示例:
#   show_ai_service_status
show_ai_service_status() {
    local current_service=$(get_ai_service)

    echo -e "${BLUE}=== AI服务状态 ===${NC}"
    echo "当前服务: $current_service"
    echo ""

    # 检查各个服务的可用性
    local services=("gemini" "claudecode")
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
#
# 功能: 设置当前使用的AI服务
# 参数:
#   $1 - service: AI服务名称 (必需)
#        支持: "gemini", "claudecode"
#   $2 - scope: 配置范围 (可选, 默认: "project")
#        - "project": 保存到项目配置文件
#        - "global": 保存到全局配置文件
# 返回: 0=设置成功, 1=不支持的服务
# 复杂度: O(1) - 常数时间文件写入
# 依赖: mkdir, echo命令
# 调用者: main()
# 配置文件: 项目级(.ai-config) 或 全局级(~/.coderocket/ai-config)
# 示例:
#   set_ai_service "gemini" "project"
#   set_ai_service "claudecode" "global"
set_ai_service() {
    local service=$1
    local scope=${2:-"project"}  # project 或 global

    # 验证服务名称
    case "$service" in
        "gemini"|"claudecode")
            ;;
        *)
            echo -e "${RED}❌ 不支持的AI服务: $service${NC}"
            echo "支持的服务: gemini, claudecode"
            return 1
            ;;
    esac

    # 设置配置
    if [ "$scope" = "global" ]; then
        # 全局配置：创建目录并写入配置文件
        mkdir -p "$HOME/.coderocket"
        echo "AI_SERVICE=$service" > "$HOME/.coderocket/ai-config"
        echo -e "${GREEN}✓ 全局AI服务设置为: $service${NC}"
    else
        # 项目配置：写入当前目录的配置文件
        echo "AI_SERVICE=$service" > ".ai-config"
        echo -e "${GREEN}✓ 项目AI服务设置为: $service${NC}"
    fi
}

# 主函数 - 用于测试
#
# 功能: 命令行接口，提供AI服务管理的各种操作
# 参数: $@ - 命令行参数
#   命令格式:
#     status                        - 显示AI服务状态
#     set <service> [global|project] - 设置AI服务
#     test                          - 测试当前AI服务
# 返回: 0=成功, 1=参数错误
# 复杂度: O(1) - 命令分发
# 依赖: show_ai_service_status(), set_ai_service(), get_ai_service(), smart_ai_call()
# 调用者: 脚本直接执行时
# 默认命令: status (当无参数时)
# 示例:
#   main status
#   main set gemini global
#   main test
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
            # 使用智能调用测试AI服务功能
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
