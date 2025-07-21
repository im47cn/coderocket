#!/bin/bash

# Version Comparison Utilities
# 版本比较工具模块

# 标准化版本号
#
# 功能: 将版本号标准化为可比较的格式
# 参数:
#   $1 - version: 原始版本号
# 返回: 标准化的版本号
# 复杂度: O(1) - 字符串处理
# 格式: 移除前缀v，移除后缀标识符
# 示例:
#   normalize_version "v1.2.3-beta" -> "1.2.3"
normalize_version() {
    local version="$1"
    
    # 移除 v 前缀
    version=$(echo "$version" | sed 's/^v//')
    
    # 移除后缀（如 -beta, -alpha, -dev 等）
    version=$(echo "$version" | sed 's/-.*$//')
    
    # 移除前后空白
    version=$(echo "$version" | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
    
    echo "$version"
}

# 将版本号分解为数组
#
# 功能: 将版本号按点分割为数组
# 参数:
#   $1 - version: 版本号
#   $2 - array_name: 输出数组名称
# 返回: 无（通过数组返回）
# 复杂度: O(n) - n为版本段数
# 示例:
#   split_version "1.2.3" version_parts
#   echo ${version_parts[0]} # 输出: 1
split_version() {
    local version="$1"
    local array_name="$2"
    
    # 清空数组
    eval "$array_name=()"
    
    # 使用点作为分隔符
    local IFS='.'
    local parts=($version)
    
    # 复制到指定数组
    for i in "${!parts[@]}"; do
        eval "${array_name}[$i]=${parts[$i]}"
    done
}

# 比较两个版本号
#
# 功能: 比较两个版本号的大小关系
# 参数:
#   $1 - version1: 第一个版本号
#   $2 - version2: 第二个版本号
# 返回: 
#   0 = version1 == version2
#   1 = version1 > version2  
#   2 = version1 < version2
# 复杂度: O(max(m,n)) - m,n为版本段数
# 示例:
#   compare_versions_detailed "1.2.3" "1.2.4" # 返回 2
compare_versions_detailed() {
    local version1="$1"
    local version2="$2"
    
    # 标准化版本号
    version1=$(normalize_version "$version1")
    version2=$(normalize_version "$version2")
    
    # 处理空版本号
    if [ -z "$version1" ] && [ -z "$version2" ]; then
        return 0  # 都为空，相等
    elif [ -z "$version1" ]; then
        return 2  # version1 为空，小于 version2
    elif [ -z "$version2" ]; then
        return 1  # version2 为空，version1 大于 version2
    fi
    
    # 分解版本号
    local v1_parts=()
    local v2_parts=()
    split_version "$version1" v1_parts
    split_version "$version2" v2_parts
    
    # 获取最大段数
    local max_parts=${#v1_parts[@]}
    if [ ${#v2_parts[@]} -gt $max_parts ]; then
        max_parts=${#v2_parts[@]}
    fi
    
    # 逐段比较
    for ((i=0; i<max_parts; i++)); do
        local v1_part=${v1_parts[$i]:-0}
        local v2_part=${v2_parts[$i]:-0}
        
        # 确保是数字
        if ! [[ "$v1_part" =~ ^[0-9]+$ ]]; then
            v1_part=0
        fi
        if ! [[ "$v2_part" =~ ^[0-9]+$ ]]; then
            v2_part=0
        fi
        
        if [ "$v1_part" -gt "$v2_part" ]; then
            return 1  # version1 > version2
        elif [ "$v1_part" -lt "$v2_part" ]; then
            return 2  # version1 < version2
        fi
    done
    
    return 0  # 版本相等
}

# 简化的版本比较（兼容性函数）
#
# 功能: 检查 version1 是否大于等于 version2
# 参数:
#   $1 - version1: 第一个版本号
#   $2 - version2: 第二个版本号
# 返回: 0=version1>=version2, 1=version1<version2
# 复杂度: O(max(m,n)) - m,n为版本段数
# 示例:
#   is_version_greater_or_equal "1.2.3" "1.2.0" # 返回 0
is_version_greater_or_equal() {
    local version1="$1"
    local version2="$2"
    
    compare_versions_detailed "$version1" "$version2"
    local result=$?
    
    # 返回值：0(相等) 或 1(大于) 都表示 >= 
    if [ $result -eq 0 ] || [ $result -eq 1 ]; then
        return 0
    else
        return 1
    fi
}

# 检查版本是否为有效格式
#
# 功能: 验证版本号格式是否有效
# 参数:
#   $1 - version: 要验证的版本号
# 返回: 0=有效, 1=无效
# 复杂度: O(1) - 正则匹配
# 格式: 支持 x.y.z 或 vx.y.z 格式
# 示例:
#   is_valid_version "1.2.3" # 返回 0
#   is_valid_version "abc"   # 返回 1
is_valid_version() {
    local version="$1"
    
    if [ -z "$version" ]; then
        return 1
    fi
    
    # 移除可能的 v 前缀
    version=$(echo "$version" | sed 's/^v//')
    
    # 检查基本格式：数字.数字.数字（可选更多段）
    if [[ "$version" =~ ^[0-9]+(\.[0-9]+)*(-[a-zA-Z0-9]+)?$ ]]; then
        return 0
    else
        return 1
    fi
}

# 获取版本的主要部分
#
# 功能: 获取版本号的主要部分（主版本.次版本.修订版本）
# 参数:
#   $1 - version: 完整版本号
# 返回: 主要版本号
# 复杂度: O(1) - 字符串处理
# 示例:
#   get_major_version "1.2.3-beta.4" # 返回 "1.2.3"
get_major_version() {
    local version="$1"
    
    version=$(normalize_version "$version")
    
    # 提取前三段
    local IFS='.'
    local parts=($version)
    
    local major=${parts[0]:-0}
    local minor=${parts[1]:-0}
    local patch=${parts[2]:-0}
    
    echo "$major.$minor.$patch"
}

# 检查是否为预发布版本
#
# 功能: 检查版本是否为预发布版本
# 参数:
#   $1 - version: 版本号
# 返回: 0=是预发布版本, 1=不是
# 复杂度: O(1) - 字符串匹配
# 示例:
#   is_prerelease_version "1.2.3-beta" # 返回 0
#   is_prerelease_version "1.2.3"      # 返回 1
is_prerelease_version() {
    local version="$1"
    
    if [[ "$version" =~ -[a-zA-Z] ]]; then
        return 0
    else
        return 1
    fi
}

# 版本比较测试函数
#
# 功能: 测试版本比较功能
# 参数: 无
# 返回: 无
# 复杂度: O(1) - 测试用例
test_version_comparison() {
    echo "=== 版本比较测试 ==="
    
    local test_cases=(
        "1.0.0:1.0.0:0"    # 相等
        "1.0.1:1.0.0:1"    # 大于
        "1.0.0:1.0.1:2"    # 小于
        "2.0.0:1.9.9:1"    # 大于
        "1.2.3:1.2.3-beta:1" # 正式版大于预发布版
        "v1.0.0:1.0.0:0"   # 带v前缀
    )
    
    for test_case in "${test_cases[@]}"; do
        local IFS=':'
        local parts=($test_case)
        local v1="${parts[0]}"
        local v2="${parts[1]}"
        local expected="${parts[2]}"
        
        compare_versions_detailed "$v1" "$v2"
        local result=$?
        
        if [ $result -eq $expected ]; then
            echo "✅ $v1 vs $v2 = $result (期望: $expected)"
        else
            echo "❌ $v1 vs $v2 = $result (期望: $expected)"
        fi
    done
}

# 主函数
#
# 功能: 命令行接口
# 参数: $@ - 命令行参数
# 返回: 0=成功, 1=失败
# 复杂度: O(1) - 命令分发
main() {
    case "${1:-help}" in
        "compare")
            if [ $# -lt 3 ]; then
                echo "用法: $0 compare <version1> <version2>"
                return 1
            fi
            compare_versions_detailed "$2" "$3"
            local result=$?
            case $result in
                0) echo "$2 == $3" ;;
                1) echo "$2 > $3" ;;
                2) echo "$2 < $3" ;;
            esac
            return $result
            ;;
        "gte")
            if [ $# -lt 3 ]; then
                echo "用法: $0 gte <version1> <version2>"
                return 1
            fi
            if is_version_greater_or_equal "$2" "$3"; then
                echo "$2 >= $3"
                return 0
            else
                echo "$2 < $3"
                return 1
            fi
            ;;
        "valid")
            if [ $# -lt 2 ]; then
                echo "用法: $0 valid <version>"
                return 1
            fi
            if is_valid_version "$2"; then
                echo "✅ $2 是有效版本号"
                return 0
            else
                echo "❌ $2 不是有效版本号"
                return 1
            fi
            ;;
        "normalize")
            if [ $# -lt 2 ]; then
                echo "用法: $0 normalize <version>"
                return 1
            fi
            normalize_version "$2"
            ;;
        "test")
            test_version_comparison
            ;;
        "help"|*)
            echo "版本比较工具"
            echo ""
            echo "用法: $0 <命令> [参数...]"
            echo ""
            echo "命令:"
            echo "  compare <v1> <v2>  - 比较两个版本号"
            echo "  gte <v1> <v2>      - 检查 v1 >= v2"
            echo "  valid <version>    - 验证版本号格式"
            echo "  normalize <version> - 标准化版本号"
            echo "  test               - 运行测试用例"
            echo "  help               - 显示帮助信息"
            ;;
    esac
}

# 如果直接执行此脚本，运行主函数
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi
