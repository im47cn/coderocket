#!/bin/bash

# Version Management Module
# 版本管理模块

# 获取项目版本号
#
# 功能: 从多个来源获取项目版本号
# 参数: 无
# 返回: 版本号字符串
# 复杂度: O(1) - 常数时间查找
# 依赖: cat, git命令
# 调用者: install.sh, 其他需要版本信息的脚本
# 优先级: VERSION文件 > Git标签 > Git提交哈希 > 默认版本
# 示例:
#   version=$(get_version)  # 返回 "1.0.0"
get_version() {
    local version=""
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local project_root="$(dirname "$script_dir")"
    
    # 1. 尝试从VERSION文件读取
    if [ -f "$project_root/VERSION" ]; then
        version=$(cat "$project_root/VERSION" 2>/dev/null | tr -d '\n\r' | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
        if [ ! -z "$version" ]; then
            echo "$version"
            return 0
        fi
    fi
    
    # 2. 尝试从Git标签获取
    if command -v git &> /dev/null && [ -d "$project_root/.git" ]; then
        version=$(cd "$project_root" && git describe --tags --exact-match 2>/dev/null)
        if [ ! -z "$version" ]; then
            echo "$version"
            return 0
        fi
        
        # 3. 尝试从最新Git标签获取
        version=$(cd "$project_root" && git describe --tags --abbrev=0 2>/dev/null)
        if [ ! -z "$version" ]; then
            # 如果有未提交的更改，添加-dev后缀
            local commit_hash=$(cd "$project_root" && git rev-parse --short HEAD 2>/dev/null)
            if [ ! -z "$commit_hash" ]; then
                echo "${version}-dev-${commit_hash}"
            else
                echo "$version"
            fi
            return 0
        fi
        
        # 4. 使用Git提交哈希作为版本
        local commit_hash=$(cd "$project_root" && git rev-parse --short HEAD 2>/dev/null)
        if [ ! -z "$commit_hash" ]; then
            echo "dev-${commit_hash}"
            return 0
        fi
    fi
    
    # 5. 默认版本
    echo "1.0.0-unknown"
    return 0
}

# 获取详细版本信息
#
# 功能: 获取包含构建信息的详细版本
# 参数: 无
# 返回: 详细版本信息字符串
# 复杂度: O(1) - 常数时间查找
# 依赖: get_version(), git命令, date命令
# 调用者: 调试和诊断脚本
# 示例:
#   detailed_version=$(get_detailed_version)
get_detailed_version() {
    local version=$(get_version)
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local project_root="$(dirname "$script_dir")"
    
    echo "CodeRocket v$version"
    
    # 添加Git信息（如果可用）
    if command -v git &> /dev/null && [ -d "$project_root/.git" ]; then
        local commit_hash=$(cd "$project_root" && git rev-parse HEAD 2>/dev/null)
        local commit_date=$(cd "$project_root" && git log -1 --format=%ci 2>/dev/null)
        local branch=$(cd "$project_root" && git rev-parse --abbrev-ref HEAD 2>/dev/null)
        
        if [ ! -z "$commit_hash" ]; then
            echo "Commit: ${commit_hash:0:8}"
        fi
        if [ ! -z "$commit_date" ]; then
            echo "Date: $commit_date"
        fi
        if [ ! -z "$branch" ]; then
            echo "Branch: $branch"
        fi
    fi
    
    # 添加构建信息
    echo "Built: $(date '+%Y-%m-%d %H:%M:%S')"
}

# 检查版本兼容性
#
# 功能: 检查当前版本是否满足最低要求
# 参数:
#   $1 - required_version: 最低要求版本 (必需)
# 返回: 0=满足要求, 1=不满足要求
# 复杂度: O(1) - 版本号比较
# 依赖: get_version()
# 调用者: 兼容性检查脚本
# 示例:
#   if check_version_compatibility "1.0.0"; then
#       echo "版本兼容"
#   fi
check_version_compatibility() {
    local required_version=$1
    local current_version=$(get_version)
    
    # 移除版本号中的非数字字符进行比较
    local current_numeric=$(echo "$current_version" | sed 's/[^0-9.].*$//' | sed 's/\.$//') 
    local required_numeric=$(echo "$required_version" | sed 's/[^0-9.].*$//' | sed 's/\.$//')
    
    # 简单的版本比较（假设语义化版本）
    if [ "$current_numeric" = "$required_numeric" ]; then
        return 0
    fi
    
    # 更复杂的版本比较可以在这里实现
    # 目前简化处理
    return 1
}

# 主函数 - 用于测试
main() {
    case "${1:-version}" in
        "version"|"-v"|"--version")
            get_version
            ;;
        "detailed"|"-d"|"--detailed")
            get_detailed_version
            ;;
        "check")
            if [ -z "$2" ]; then
                echo "用法: $0 check <required_version>"
                return 1
            fi
            if check_version_compatibility "$2"; then
                echo "✓ 版本兼容: $(get_version) >= $2"
                return 0
            else
                echo "✗ 版本不兼容: $(get_version) < $2"
                return 1
            fi
            ;;
        "help"|"-h"|"--help")
            echo "版本管理模块"
            echo ""
            echo "用法: $0 <命令> [参数...]"
            echo ""
            echo "命令:"
            echo "  version              - 获取版本号"
            echo "  detailed             - 获取详细版本信息"
            echo "  check <version>      - 检查版本兼容性"
            echo "  help                 - 显示帮助信息"
            ;;
        *)
            get_version
            ;;
    esac
}

# 如果直接执行此脚本，运行主函数
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi
