#!/bin/bash

# API Versions Configuration
# API版本配置模块

# API版本配置
# 这些版本号相对稳定，但可以通过环境变量覆盖

# OpenCode API配置
DEFAULT_OPENCODE_API_VERSION="v1"
DEFAULT_OPENCODE_API_BASE="https://api.opencode.com"

# ClaudeCode API配置  
DEFAULT_CLAUDECODE_API_VERSION="v1"
DEFAULT_CLAUDECODE_API_BASE="https://api.claudecode.com"
DEFAULT_ANTHROPIC_VERSION="2023-06-01"

# GitLab API配置
DEFAULT_GITLAB_API_VERSION="v4"
DEFAULT_GITLAB_API_BASE="https://gitlab.com/api"

# 获取OpenCode API URL
#
# 功能: 获取OpenCode API的完整URL
# 参数: 无
# 返回: API URL字符串
# 环境变量: OPENCODE_API_BASE, OPENCODE_API_VERSION
# 示例: get_opencode_api_url  # 返回 "https://api.opencode.com/v1"
get_opencode_api_url() {
    local api_base="${OPENCODE_API_BASE:-$DEFAULT_OPENCODE_API_BASE}"
    local api_version="${OPENCODE_API_VERSION:-$DEFAULT_OPENCODE_API_VERSION}"
    echo "${api_base}/${api_version}"
}

# 获取ClaudeCode API URL
#
# 功能: 获取ClaudeCode API的完整URL
# 参数: 无
# 返回: API URL字符串
# 环境变量: CLAUDECODE_API_BASE, CLAUDECODE_API_VERSION
# 示例: get_claudecode_api_url  # 返回 "https://api.claudecode.com/v1"
get_claudecode_api_url() {
    local api_base="${CLAUDECODE_API_BASE:-$DEFAULT_CLAUDECODE_API_BASE}"
    local api_version="${CLAUDECODE_API_VERSION:-$DEFAULT_CLAUDECODE_API_VERSION}"
    echo "${api_base}/${api_version}"
}

# 获取Anthropic API版本
#
# 功能: 获取Anthropic API版本号
# 参数: 无
# 返回: API版本字符串
# 环境变量: ANTHROPIC_VERSION
# 示例: get_anthropic_version  # 返回 "2023-06-01"
get_anthropic_version() {
    echo "${ANTHROPIC_VERSION:-$DEFAULT_ANTHROPIC_VERSION}"
}

# 获取GitLab API URL
#
# 功能: 获取GitLab API的完整URL
# 参数: 无
# 返回: API URL字符串
# 环境变量: GITLAB_API_BASE, GITLAB_API_VERSION
# 示例: get_gitlab_api_url  # 返回 "https://gitlab.com/api/v4"
get_gitlab_api_url() {
    local api_base="${GITLAB_API_BASE:-$DEFAULT_GITLAB_API_BASE}"
    local api_version="${GITLAB_API_VERSION:-$DEFAULT_GITLAB_API_VERSION}"
    echo "${api_base}/${api_version}"
}

# 显示所有API版本信息
#
# 功能: 显示当前配置的所有API版本
# 参数: 无
# 返回: 无 (直接输出到stdout)
show_api_versions() {
    echo "=== API版本配置 ==="
    echo "OpenCode API: $(get_opencode_api_url)"
    echo "ClaudeCode API: $(get_claudecode_api_url)"
    echo "Anthropic Version: $(get_anthropic_version)"
    echo "GitLab API: $(get_gitlab_api_url)"
    echo ""
    echo "=== 环境变量覆盖 ==="
    echo "OPENCODE_API_BASE=${OPENCODE_API_BASE:-未设置}"
    echo "OPENCODE_API_VERSION=${OPENCODE_API_VERSION:-未设置}"
    echo "CLAUDECODE_API_BASE=${CLAUDECODE_API_BASE:-未设置}"
    echo "CLAUDECODE_API_VERSION=${CLAUDECODE_API_VERSION:-未设置}"
    echo "ANTHROPIC_VERSION=${ANTHROPIC_VERSION:-未设置}"
    echo "GITLAB_API_BASE=${GITLAB_API_BASE:-未设置}"
    echo "GITLAB_API_VERSION=${GITLAB_API_VERSION:-未设置}"
}

# 主函数
main() {
    case "${1:-show}" in
        "show"|"list")
            show_api_versions
            ;;
        "opencode")
            get_opencode_api_url
            ;;
        "claudecode")
            get_claudecode_api_url
            ;;
        "anthropic")
            get_anthropic_version
            ;;
        "gitlab")
            get_gitlab_api_url
            ;;
        "help"|"-h"|"--help")
            echo "API版本配置模块"
            echo ""
            echo "用法: $0 <命令>"
            echo ""
            echo "命令:"
            echo "  show        - 显示所有API版本配置"
            echo "  opencode    - 获取OpenCode API URL"
            echo "  claudecode  - 获取ClaudeCode API URL"
            echo "  anthropic   - 获取Anthropic API版本"
            echo "  gitlab      - 获取GitLab API URL"
            echo "  help        - 显示帮助信息"
            ;;
        *)
            show_api_versions
            ;;
    esac
}

# 如果直接执行此脚本，运行主函数
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi
