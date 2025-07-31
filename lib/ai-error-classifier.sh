#!/bin/bash

# AI Error Classifier - 智能AI服务错误分类器
# 识别和分类不同AI服务的错误类型，为智能切换提供决策依据

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 错误类型常量
readonly ERROR_SUCCESS="success"
readonly ERROR_RATE_LIMIT="rate_limit"
readonly ERROR_AUTH="auth_error"
readonly ERROR_NETWORK="network_error"
readonly ERROR_SERVER="server_error"
readonly ERROR_CLI_MISSING="cli_missing"
readonly ERROR_TIMEOUT="timeout"
readonly ERROR_UNKNOWN="unknown_error"

# 全局变量存储最后的错误信息
LAST_ERROR_TYPE=""
LAST_ERROR_MESSAGE=""
LAST_ERROR_SERVICE=""

# 分类AI服务错误
#
# 功能: 根据错误输出和退出码分类错误类型
# 参数:
#   $1 - service: AI服务名称
#   $2 - exit_code: 命令退出码
#   $3 - error_output: 错误输出内容
#   $4 - stdout_output: 标准输出内容（可选）
# 返回: 错误类型字符串
# 全局变量: 设置LAST_ERROR_*变量
classify_ai_error() {
    local service=$1
    local exit_code=$2
    local error_output=$3
    local stdout_output=${4:-""}
    
    # 重置全局变量
    LAST_ERROR_TYPE=""
    LAST_ERROR_MESSAGE="$error_output"
    LAST_ERROR_SERVICE="$service"
    
    # 成功情况
    if [ "$exit_code" -eq 0 ] && [ -n "$stdout_output" ]; then
        LAST_ERROR_TYPE="$ERROR_SUCCESS"
        echo "$ERROR_SUCCESS"
        return 0
    fi
    
    # 命令未找到（CLI未安装）
    if [ $exit_code -eq 127 ] || echo "$error_output" | grep -qi "command not found\|not found\|no such file"; then
        LAST_ERROR_TYPE="$ERROR_CLI_MISSING"
        echo "$ERROR_CLI_MISSING"
        return 0
    fi
    
    # 超时错误
    if [ $exit_code -eq 124 ] || echo "$error_output" | grep -qi "timeout\|timed out"; then
        LAST_ERROR_TYPE="$ERROR_TIMEOUT"
        echo "$ERROR_TIMEOUT"
        return 0
    fi
    
    # 根据服务类型和错误内容进行分类
    case "$service" in
        "gemini")
            classify_gemini_error "$error_output"
            ;;
        "opencode")
            classify_opencode_error "$error_output"
            ;;
        "claudecode")
            classify_claudecode_error "$error_output"
            ;;
        *)
            classify_generic_error "$error_output"
            ;;
    esac
    
    echo "$LAST_ERROR_TYPE"
}

# 分类Gemini CLI错误
classify_gemini_error() {
    local error_output=$1
    
    # 限流错误 (429, quota exceeded, rate limit)
    if echo "$error_output" | grep -qi "429\|rate limit\|quota exceeded\|too many requests\|rate_limit_exceeded"; then
        LAST_ERROR_TYPE="$ERROR_RATE_LIMIT"
        return 0
    fi
    
    # 认证错误 (401, 403, API key)
    if echo "$error_output" | grep -qi "401\|403\|unauthorized\|forbidden\|api key\|invalid key\|authentication"; then
        LAST_ERROR_TYPE="$ERROR_AUTH"
        return 0
    fi
    
    # 网络错误
    if echo "$error_output" | grep -qi "network\|connection\|dns\|resolve\|unreachable\|connection refused"; then
        LAST_ERROR_TYPE="$ERROR_NETWORK"
        return 0
    fi
    
    # 服务器错误 (5xx)
    if echo "$error_output" | grep -qi "500\|502\|503\|504\|internal server error\|bad gateway\|service unavailable"; then
        LAST_ERROR_TYPE="$ERROR_SERVER"
        return 0
    fi
    
    # 默认为未知错误
    LAST_ERROR_TYPE="$ERROR_UNKNOWN"
}

# 分类OpenCode CLI错误
classify_opencode_error() {
    local error_output=$1
    
    # OpenCode特定的错误模式
    if echo "$error_output" | grep -qi "rate limit\|quota\|429"; then
        LAST_ERROR_TYPE="$ERROR_RATE_LIMIT"
        return 0
    fi
    
    if echo "$error_output" | grep -qi "unauthorized\|invalid token\|authentication failed"; then
        LAST_ERROR_TYPE="$ERROR_AUTH"
        return 0
    fi
    
    if echo "$error_output" | grep -qi "connection\|network\|timeout"; then
        LAST_ERROR_TYPE="$ERROR_NETWORK"
        return 0
    fi
    
    # 使用通用分类
    classify_generic_error "$error_output"
}

# 分类ClaudeCode CLI错误
classify_claudecode_error() {
    local error_output=$1
    
    # Claude特定的错误模式
    if echo "$error_output" | grep -qi "rate_limit\|too_many_requests\|429"; then
        LAST_ERROR_TYPE="$ERROR_RATE_LIMIT"
        return 0
    fi
    
    if echo "$error_output" | grep -qi "invalid_api_key\|unauthorized\|authentication_error"; then
        LAST_ERROR_TYPE="$ERROR_AUTH"
        return 0
    fi
    
    if echo "$error_output" | grep -qi "connection_error\|network\|timeout"; then
        LAST_ERROR_TYPE="$ERROR_NETWORK"
        return 0
    fi
    
    # 使用通用分类
    classify_generic_error "$error_output"
}

# 通用错误分类
classify_generic_error() {
    local error_output=$1
    
    # 网络相关错误
    if echo "$error_output" | grep -qi "network\|connection\|dns\|timeout\|unreachable"; then
        LAST_ERROR_TYPE="$ERROR_NETWORK"
        return 0
    fi
    
    # 认证相关错误
    if echo "$error_output" | grep -qi "auth\|unauthorized\|forbidden\|key\|token"; then
        LAST_ERROR_TYPE="$ERROR_AUTH"
        return 0
    fi
    
    # 服务器错误
    if echo "$error_output" | grep -qi "server error\|internal error\|5[0-9][0-9]"; then
        LAST_ERROR_TYPE="$ERROR_SERVER"
        return 0
    fi
    
    # 默认未知错误
    LAST_ERROR_TYPE="$ERROR_UNKNOWN"
}

# 获取错误处理策略
#
# 功能: 根据错误类型返回处理策略
# 参数:
#   $1 - error_type: 错误类型
# 返回: 处理策略字符串
get_error_strategy() {
    local error_type=$1
    
    case "$error_type" in
        "$ERROR_SUCCESS")
            echo "continue"
            ;;
        "$ERROR_RATE_LIMIT")
            echo "switch_immediately"  # 立即切换到下一个服务
            ;;
        "$ERROR_AUTH")
            echo "skip_service"        # 跳过此服务，提示用户配置
            ;;
        "$ERROR_CLI_MISSING")
            echo "skip_service"        # 跳过此服务，提示安装
            ;;
        "$ERROR_NETWORK")
            echo "retry_then_switch"   # 重试一次，然后切换
            ;;
        "$ERROR_TIMEOUT")
            echo "switch_immediately"  # 立即切换
            ;;
        "$ERROR_SERVER")
            echo "retry_then_switch"   # 重试一次，然后切换
            ;;
        *)
            echo "switch_immediately"  # 未知错误，立即切换
            ;;
    esac
}

# 获取用户友好的错误描述
get_error_description() {
    local error_type=$1
    local service=$2
    
    case "$error_type" in
        "$ERROR_RATE_LIMIT")
            echo "🚫 $service 服务达到使用限制（429错误）"
            ;;
        "$ERROR_AUTH")
            echo "🔐 $service 服务认证失败，请检查API密钥配置"
            ;;
        "$ERROR_CLI_MISSING")
            echo "📦 $service CLI工具未安装"
            ;;
        "$ERROR_NETWORK")
            echo "🌐 网络连接问题，无法访问 $service 服务"
            ;;
        "$ERROR_TIMEOUT")
            echo "⏰ $service 服务响应超时"
            ;;
        "$ERROR_SERVER")
            echo "🔧 $service 服务器错误"
            ;;
        *)
            echo "❓ $service 服务遇到未知错误"
            ;;
    esac
}

# 获取最后的错误信息
get_last_error_type() {
    echo "$LAST_ERROR_TYPE"
}

get_last_error_message() {
    echo "$LAST_ERROR_MESSAGE"
}

get_last_error_service() {
    echo "$LAST_ERROR_SERVICE"
}

# 测试函数
test_error_classifier() {
    echo "🧪 测试AI错误分类器..."
    
    # 测试429错误
    local result=$(classify_ai_error "gemini" 1 "Error: 429 Too Many Requests - Rate limit exceeded")
    echo "429错误分类: $result (期望: $ERROR_RATE_LIMIT)"
    
    # 测试认证错误
    result=$(classify_ai_error "gemini" 1 "Error: 401 Unauthorized - Invalid API key")
    echo "认证错误分类: $result (期望: $ERROR_AUTH)"
    
    # 测试网络错误
    result=$(classify_ai_error "opencode" 1 "Error: Connection timeout")
    echo "网络错误分类: $result (期望: $ERROR_NETWORK)"
    
    # 测试CLI未安装
    result=$(classify_ai_error "claudecode" 127 "claudecode: command not found")
    echo "CLI未安装分类: $result (期望: $ERROR_CLI_MISSING)"
}

# 如果直接运行此脚本，执行测试
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    test_error_classifier
fi
